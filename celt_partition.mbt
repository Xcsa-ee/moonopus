// celt_partition.mbt
//
// band 形状的递归分割解码（RFC 6716 §4.3.4.4 Split Decoding）。
//
// 对应参考实现 celt_bands.c 的 quant_partition 解码侧：位数超过最大
// 码本 1.5 bit 且 N>2 就把带切成两半，先按 celt_compute_theta 解出的
// θ 把位数分给 mid/side（含 rebalance 补偿），递归到叶；叶上用
// celt_bits2pulses 把位数换成脉冲索引，在预算内回退，再交给 PVQ
// 解出脉冲向量。
//
// 递归同时完成叶上的谱应用（对应 alg_unquant 的解码侧与 q==0 填充），
// 由谱上下文 CeltBandCtx 控制：
//
//   - active=false：只走控制与熵解码（本文件的 celt_decode_quant_partition
//     包装入口），结果仍是 splits/leaves/remaining；
//   - active=true：额外把叶写进 x——q>0 时按 gain/√Σy² 归一化并做
//     展宽旋转，q==0 时按 fill/折叠源填充噪声并重归一化，同时消费
//     lcg seed、累积每带的 collapse mask（cm 按 side<<(B>>1) 归并）。
//
// 谱的频序还原（tf_inverse）、fill/cm 的位图变换与 n==1 特例在
// celt_quant_band.mbt 的带级入口完成。

///|
/// 谱上下文：数组字段按引用共享；`seed`/`cm` 是单元素出参盒。
/// `active=false` 时所有谱写入与 seed 消费都被跳过。
priv struct CeltBandCtx {
  active : Bool
  // 本带频谱（长度 n，叶按偏移就地写）
  x : Array[Double]
  // 折叠源（空数组 = 无折叠，q==0 走噪声路径）
  lowband : Array[Double]
  has_lowband : Bool
  // 展宽旋转的档位（§4.3.4.3 的 spread 决策）
  spread : Int
  // lcg seed 出参（初值由调用方放入）
  seed : Array[Int64]
}

///|
/// 一个叶节点的解码控制量（前序排列于 CeltPartitionResult.leaves）。
pub struct CeltPartitionLeaf {
  /// 叶的维度 N
  n : Int
  /// 该叶的时间块数 B（随分割折半、随升频翻倍后的值）
  blocks : Int
  /// 该叶的 LM（分割到顶为 -1）
  lm : Int
  /// 进入叶时的可用位数（1/8 bit）
  b : Int
  /// bits2pulses 的结果（经预算循环回退后的伪脉冲索引）
  q : Int
  /// 实际占用位数 pulses2bits(q)（预算扣减量）
  used : Int
  /// 叶上的 fill 位图（经过带级与分割级变换后的最终值）
  fill : Int
  /// PVQ 解出的脉冲向量；q==0 时为空数组（叶上无熵消费）
  pulses : Array[Int]
}

///|
/// 整棵树的解码结果：split 节点与叶都按熵消费顺序（前序）排列。
pub struct CeltPartitionResult {
  /// 每个分割节点的 θ 控制量
  splits : Array[CeltThetaSplit]
  /// 叶序列
  leaves : Array[CeltPartitionLeaf]
  /// 结束时的剩余预算（初始值扣掉全部熵消费）
  remaining_bits : Int
}

///|
/// quant_partition 的解码入口（控制与熵解码路径，谱写入关闭）。
///
/// `band` 是原始带号（查脉冲缓存用，不随分割改变），`lm` 是本带
/// 帧长索引，`n` 是带的 MDCT bin 数，`b` 是本带可用位数（1/8 bit），
/// `blocks` 是时间块数 B，`fill` 是噪声填充位图，`remaining_bits` 是
/// 进入本带时的全局剩余预算（1/8 bit）。
pub fn celt_decode_quant_partition(
  dec : RangeDecoder,
  band : Int,
  lm : Int,
  n : Int,
  b : Int,
  blocks : Int,
  fill : Int,
  remaining_bits : Int,
) -> CeltPartitionResult {
  let splits : Array[CeltThetaSplit] = []
  let leaves : Array[CeltPartitionLeaf] = []
  let ctx = CeltBandCtx::{
    active: false,
    x: [],
    lowband: [],
    has_lowband: false,
    spread: 0,
    seed: [0L],
  }
  let (remaining, _) = celt_partition_rec(
    dec, band, lm, n, b, blocks, fill, remaining_bits, splits, leaves, ctx, 0, 0,
    1.0,
  )
  { splits, leaves, remaining_bits: remaining, }
}

///|
/// 噪声填充的一个样本：seed 按 int32 重解释后算术右移 20 位。float
/// 构建的 SHL32(…, NORM_SHIFT-14) 是恒等宏，故不再二次缩放。
fn celt_fill_sample(seed : Int64) -> Double {
  let sv = seed & 0xFFFFFFFFL
  let iv = if sv >= 0x80000000L { sv - 0x100000000L } else { sv }
  (iv >> 20).to_double()
}

///|
/// 叶向量的塌缩位图（celt_vq.c 的 extract_collapse_mask）：B≤1 恒 1，
/// 否则按 N/B 分块，块内任一系数非零则该位为 1。
fn celt_extract_collapse_mask(y : Array[Int], n : Int, blocks : Int) -> Int {
  if blocks <= 1 {
    return 1
  }
  let n0 = celt_udiv(n, blocks)
  let mut mask = 0
  for i in 0..<blocks {
    let mut t = 0
    for j in 0..<n0 {
      t = t | y[i * n0 + j]
    }
    if t != 0 {
      mask = mask | (1 << i)
    }
  }
  mask
}

///|
/// 把叶旋转到（复制进出：celt_exp_rotation 按整段数组工作）。
/// 守卫与 celt_exp_rotation 自身的早退一致，避免无谓分配。
fn celt_rotate_band(
  x : Array[Double],
  off : Int,
  n : Int,
  blocks : Int,
  k : Int,
  spread : Int,
) -> Unit {
  if spread == 0 || 2 * k >= n {
    return
  }
  let sub = Array::make(n, 0.0)
  for j in 0..<n {
    sub[j] = x[off + j]
  }
  celt_exp_rotation(sub, blocks, k, spread)
  for j in 0..<n {
    x[off + j] = sub[j]
  }
}

///|
/// 递归体：分割或落叶，返回 (更新后的剩余预算, 子树 collapse mask)。
fn celt_partition_rec(
  dec : RangeDecoder,
  band : Int,
  lm : Int,
  n : Int,
  b : Int,
  blocks : Int,
  fill : Int,
  remaining : Int,
  splits : Array[CeltThetaSplit],
  leaves : Array[CeltPartitionLeaf],
  ctx : CeltBandCtx,
  x_off : Int,
  lb_off : Int,
  gain : Double,
) -> (Int, Int) {
  let blocks0 = blocks
  let off = cel_cache_index50[(lm + 1) * CEL_NB_EBANDS + band]
  let kmax = cel_cache_bits50[off].to_int()
  // 位数超过最大码本 1.5 bit 才分割；N≤2 或 LM 到顶（-1）时必须落叶
  if lm != -1 && b > cel_cache_bits50[off + kmax].to_int() + 12 && n > 2 {
    let n2 = n >> 1
    let mut fill_mid = fill
    if blocks == 1 {
      fill_mid = (fill & 1) | (fill << 1)
    }
    let blocks_half = (blocks + 1) >> 1
    let (sctx, b_mid, fill_theta) = celt_compute_theta(
      dec,
      band,
      lm - 1,
      n2,
      b,
      blocks_half,
      blocks0,
      false,
      0,
      remaining,
      false,
      fill_mid,
    )
    let mut remaining_after = remaining - sctx.qalloc
    // 低能量 MDCT 多分点位数：B0>1 且 θ 不在 0/满量程时微调 delta
    let mut delta = sctx.delta
    let itheta = sctx.itheta
    if blocks0 > 1 && (itheta & 0x3FFF) != 0 {
      if itheta > 8192 {
        // 近似预回声掩蔽
        delta = delta - (delta >> (4 - (lm - 1)))
      } else {
        // 前向掩蔽 1.5 dB/10ms 的斜率，上限 0
        let t = delta + (n2 << CEL_BITRES >> (5 - (lm - 1)))
        delta = if t < 0 { t } else { 0 }
      }
    }
    let mut mbits = celt_sudiv(b_mid - delta, 2)
    if mbits > b_mid {
      mbits = b_mid
    }
    if mbits < 0 {
      mbits = 0
    }
    let sbits = b_mid - mbits
    splits.push(sctx)
    let rebalance0 = remaining_after
    // mid/side 的缩放增益：float 路径下 mid = imid/32768
    let gain_mid = gain * (sctx.imid.to_double() / 32768.0)
    let gain_side = gain * (sctx.iside.to_double() / 32768.0)
    let mut cm_tree = 0
    if mbits >= sbits {
      let (r1, cm_mid) = celt_partition_rec(
        dec,
        band,
        lm - 1,
        n2,
        mbits,
        blocks_half,
        fill_theta,
        remaining_after,
        splits,
        leaves,
        ctx,
        x_off,
        lb_off,
        gain_mid,
      )
      remaining_after = r1
      let rebalance = mbits - (rebalance0 - remaining_after)
      let mut sbits_r = sbits
      if rebalance > 3 << CEL_BITRES && itheta != 0 {
        sbits_r += rebalance - (3 << CEL_BITRES)
      }
      let (r2, cm_side) = celt_partition_rec(
        dec,
        band,
        lm - 1,
        n2,
        sbits_r,
        blocks_half,
        fill_theta >> blocks_half,
        remaining_after,
        splits,
        leaves,
        ctx,
        x_off + n2,
        lb_off + n2,
        gain_side,
      )
      remaining_after = r2
      cm_tree = cm_mid | (cm_side << (blocks >> 1))
    } else {
      let (r1, cm_side) = celt_partition_rec(
        dec,
        band,
        lm - 1,
        n2,
        sbits,
        blocks_half,
        fill_theta >> blocks_half,
        remaining_after,
        splits,
        leaves,
        ctx,
        x_off + n2,
        lb_off + n2,
        gain_side,
      )
      remaining_after = r1
      let rebalance = sbits - (rebalance0 - remaining_after)
      let mut mbits_r = mbits
      if rebalance > 3 << CEL_BITRES && itheta != 16384 {
        mbits_r += rebalance - (3 << CEL_BITRES)
      }
      let (r2, cm_mid) = celt_partition_rec(
        dec,
        band,
        lm - 1,
        n2,
        mbits_r,
        blocks_half,
        fill_theta,
        remaining_after,
        splits,
        leaves,
        ctx,
        x_off,
        lb_off,
        gain_mid,
      )
      remaining_after = r2
      cm_tree = cm_mid | (cm_side << (blocks >> 1))
    }
    return (remaining_after, cm_tree)
  }
  // ---- 叶：bits2pulses + 预算循环 ----
  let mut q = celt_bits2pulses(band, lm, b)
  let mut used = celt_pulses2bits(band, lm, q)
  let mut remaining_leaf = remaining - used
  while remaining_leaf < 0 && q > 0 {
    remaining_leaf += used
    q -= 1
    used = celt_pulses2bits(band, lm, q)
    remaining_leaf -= used
  }
  let mut pulses : Array[Int] = []
  let mut leaf_cm = 0
  if q != 0 {
    pulses = celt_decode_pulses(dec, n, celt_get_pulses(q))
    leaf_cm = celt_extract_collapse_mask(pulses, n, blocks)
    if ctx.active {
      let k = celt_get_pulses(q)
      let mut yy = 0.0
      for y in pulses {
        let yd = y.to_double()
        yy += yd * yd
      }
      let g = gain / @math.pow(yy, 0.5)
      for j in 0..<n {
        ctx.x[x_off + j] = pulses[j].to_double() * g
      }
      celt_rotate_band(ctx.x, x_off, n, blocks, k, ctx.spread)
    }
  } else {
    let mask = (1 << blocks) - 1
    let f = fill & mask
    if f == 0 {
      // 无填充信号：整段清零（cm 保持 0，且不做重归一化）
      if ctx.active {
        for j in 0..<n {
          ctx.x[x_off + j] = 0.0
        }
      }
    } else if ctx.has_lowband {
      // 折叠：低频带 + ±1/256 的伪随机微扰
      leaf_cm = f
      if ctx.active {
        for j in 0..<n {
          ctx.seed[0] = celt_lcg_rand(ctx.seed[0])
          let s = if (ctx.seed[0] & 0x8000L) != 0L {
            0.00390625
          } else {
            -0.00390625
          }
          ctx.x[x_off + j] = ctx.lowband[lb_off + j] + s
        }
        celt_renormalise_vector(ctx.x, x_off, n, gain)
      }
    } else {
      // 噪声：int32(seed)>>20 的伪随机样值
      leaf_cm = mask
      if ctx.active {
        for j in 0..<n {
          ctx.seed[0] = celt_lcg_rand(ctx.seed[0])
          ctx.x[x_off + j] = celt_fill_sample(ctx.seed[0])
        }
        celt_renormalise_vector(ctx.x, x_off, n, gain)
      }
    }
  }
  leaves.push({ n, blocks, lm, b, q, used, fill, pulses, })
  (remaining_leaf, leaf_cm)
}
