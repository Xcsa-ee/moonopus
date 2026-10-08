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
// 本文件只做控制与熵解码：不碰谱系数（mid/side 缩放、折叠、旋转、
// q==0 的噪声填充都没有熵消费，归入后续帧级组装）。

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
  /// 叶上的 fill 位图（噪声填充路径用，此处只透传记录）
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
/// quant_partition 的解码入口。
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
  let remaining = celt_partition_rec(
    dec, band, lm, n, b, blocks, fill, remaining_bits, splits, leaves,
  )
  { splits, leaves, remaining_bits: remaining, }
}

///|
/// 递归体：分割或落叶，返回更新后的剩余预算。
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
) -> Int {
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
    if mbits >= sbits {
      remaining_after = celt_partition_rec(
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
      )
      let rebalance = mbits - (rebalance0 - remaining_after)
      let mut sbits_r = sbits
      if rebalance > 3 << CEL_BITRES && itheta != 0 {
        sbits_r += rebalance - (3 << CEL_BITRES)
      }
      remaining_after = celt_partition_rec(
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
      )
    } else {
      remaining_after = celt_partition_rec(
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
      )
      let rebalance = sbits - (rebalance0 - remaining_after)
      let mut mbits_r = mbits
      if rebalance > 3 << CEL_BITRES && itheta != 16384 {
        mbits_r += rebalance - (3 << CEL_BITRES)
      }
      remaining_after = celt_partition_rec(
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
      )
    }
    return remaining_after
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
  if q != 0 {
    pulses = celt_decode_pulses(dec, n, celt_get_pulses(q))
  }
  leaves.push({ n, blocks, lm, b, q, used, fill, pulses, })
  remaining_leaf
}
