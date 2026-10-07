// celt_energy.mbt
//
// CELT 能量包络解码（RFC 6716 §4.3.2）：粗量化 → 细量化 → 收尾。
//
// 能量以 2 为底的对数表示（粗量化固定 6 dB/步），与参考实现 float 构建
// 的 celt_glog 同域。能量状态跨帧保留，由调用方持有 Array[Double]——
// 布局同参考实现的 oldBandE，单声道只用前 nbEBands 项。
//
// 参考实现对 C==1 另在后半段存一份副本，帧首取两者较大值；那份副本只在
// 丢包容错路径里会与本体分叉，正常解码下两者恒等，故此处只保留一份。
// 丢包容错（PLC、anti-collapse 的能量侧状态）不在本模块范围。
//
// 三步之间的细能量位数与优先级由比特分配（§4.3.3）产出，本模块只消费。

///|
/// 收尾阶段单带最多再补的细能量位数（quant_bands.c 的 MAX_FINE_BITS）。
pub const CEL_MAX_FINE_BITS : Int = 8

///|
/// Laplace 分布中 0 的最小概率（1/32768）与保证可表示的最小幅度。
const CEL_LAPLACE_MINP : Int = 1

///|
const CEL_LAPLACE_LOG_MINP : Int = 0

///|
const CEL_LAPLACE_NMIN : Int = 16

///|
/// §4.3.2.1 Laplace pdf 中幅度 1 的频率（参考实现 laplace.c 同名函数）。
///
/// `ft` = 总量扣除 0 与两侧各 NMIN 个最小概率格后的剩余质量，再按
/// `(16384-decay)>>15` 的 Q15 衰减取其份额。参数域内乘积不超过 2**31。
fn cel_laplace_get_freq1(fs : Int, decay : Int) -> Int {
  let ft = 32768 - CEL_LAPLACE_MINP * (2 * CEL_LAPLACE_NMIN) - fs
  (ft * (16384 - decay)) >> 15
}

///|
/// 解一个 Laplace 分布的符号增量（§4.3.2.1，参考实现 laplace.c 的
/// ec_laplace_decode）。总量 32768：`fs` 是 0 的频率，`decay` 是衰减率。
///
/// pdf 关于 0 对称，先在 [0,∞) 上按衰减链定位幅度、再由 fm 落在 0 的
/// 正侧还是负侧定符号；状态更新统一放在最后，与参考实现一致——中途
/// 只用 decode_bin_fs 取 fs，不推进解码器。
fn cel_laplace_decode(dec : RangeDecoder, fs : Int, decay : Int) -> Int {
  let fm = dec.decode_bin_fs(15)
  let mut fs = fs
  let mut fl = 0
  let mut val = 0
  if fm >= fs {
    val += 1
    fl = fs
    fs = cel_laplace_get_freq1(fs, decay) + CEL_LAPLACE_MINP
    // 沿衰减链逐级展开：fm 未落进当前格就继续往更大幅度走。
    while fs > CEL_LAPLACE_MINP && fm >= fl + 2 * fs {
      fs = fs * 2
      fl = fl + fs
      fs = ((fs - 2 * CEL_LAPLACE_MINP) * decay) >> 15
      fs = fs + CEL_LAPLACE_MINP
      val += 1
    }
    // 衰减链耗尽后的尾部：每一格恰好 LAPLACE_MINP 的概率质量。
    if fs <= CEL_LAPLACE_MINP {
      let di = (fm - fl) >> (CEL_LAPLACE_LOG_MINP + 1)
      val += di
      fl = fl + 2 * di * CEL_LAPLACE_MINP
    }
    if fm < fl + fs {
      val = -val
    } else {
      fl = fl + fs
    }
  }
  let fh = if fl + fs < 32768 { fl + fs } else { 32768 }
  dec.update(fl, fh, 32768)
  val
}

///|
/// §4.3.2.1 粗能量解码：逐带解 Laplace 增量（或位数不足时的降级路径），
/// 再按 2-D 预测滤波器把能量状态推进一帧。
///
/// `old_e` 进入时是上一帧的最终能量，逐带被本帧结果覆盖。带内还能不能
/// 塞下一个 Laplace 符号，由解码器自身的载荷长度决定（参考实现取
/// ec_dec 的 storage × 8）；`lm` 是帧长索引（0..3 对应 120/240/480/960）。
///
/// 预测式为 §4.3.2.1 的 (1-alpha·z_l^-1)(1-z_b^-1)/(1-beta·z_b^-1)：
/// 时间方向取上帧能量乘 coef（intra 时为 0），频率方向由 prev 累积本帧
/// 已解出的量化误差并按 beta 衰减。浮点构建下 SHL32 是恒等的，故
/// q 就等于解出的整数 qi。
pub fn cel_unquant_coarse_energy(
  dec : RangeDecoder,
  old_e : Array[Double],
  start : Int,
  end : Int,
  intra : Bool,
  lm : Int,
) -> Unit {
  // e_prob_model 扁平布局 [lm][intra][42]，42 = 2 × 21 带（每带一对参数）
  let model = (if intra { lm * 2 + 1 } else { lm * 2 }) * 42
  let mut coef = 0.0
  let mut beta = CEL_BETA_INTRA
  if !intra {
    coef = cel_pred_coef[lm]
    beta = cel_beta_coef[lm]
  }
  let budget = dec.nbytes * 8
  let mut prev = 0.0
  for i in start..<end {
    let tell = dec.tell()
    let qi = if budget - tell >= 15 {
      // 带号超过 20 后共用最后一对参数（参考实现 IMIN(i, 20)）
      let pi = 2 * (if i < 20 { i } else { 20 })
      cel_laplace_decode(
        dec,
        cel_e_prob_model[model + pi].to_int() * 128,
        cel_e_prob_model[model + pi + 1].to_int() * 64,
      )
    } else if budget - tell >= 2 {
      // 小能量的固定 2 位 icdf，解出后按 zigzag 还原符号
      let v = dec.decode_icdf(cel_small_energy_icdf, 2)
      (v >> 1) ^ -(v & 1)
    } else if budget - tell >= 1 {
      -dec.decode_bit_logp(1)
    } else {
      -1
    }
    // 一位都不剩：不读比特，直接按 -1 处理
    let q = qi.to_double()
    let pred_src = if old_e[i] < -9.0 { -9.0 } else { old_e[i] }
    let tmp = coef * pred_src + prev + q
    old_e[i] = tmp
    prev = prev + q - beta * q
  }
}

///|
/// §4.3.2.2 细能量解码：把比特分配给出的 `extra_quant[i]` 位裸比特解释为
/// 粗能量的修正量 `(f+1/2)/2**B_i - 1/2`。
///
/// 位数为 0 或剩余比特不够的带直接跳过（判据同参考实现）。QEXT 扩展
/// 的 prev 缩放因子在此恒为 1，故不出现。
pub fn cel_unquant_fine_energy(
  dec : RangeDecoder,
  old_e : Array[Double],
  start : Int,
  end : Int,
  extra_quant : Array[Int],
) -> Unit {
  for i in start..<end {
    let extra = extra_quant[i]
    if extra <= 0 {
      continue
    }
    if dec.tell() + extra > dec.nbytes * 8 {
      continue
    }
    let f = dec.dec_bits(extra)
    // 先算出修正量再累加——与参考实现 `(a += offset)` 同序，
    // 浮点下换序会改变末位。
    let offset = (f.to_double() + 0.5) / (1 << extra).to_double() - 0.5
    old_e[i] = old_e[i] + offset
  }
}

///|
/// §4.3.2.2 收尾：把所有标志位解完后剩下的比特，按优先级 0→1 依次给
/// 各带再补 1 位细能量；补不动的位就留着不用。
///
/// `bits_left` 是本帧尚余的比特数（参考实现取 len*8 - ec_tell）。
pub fn cel_unquant_energy_finalise(
  dec : RangeDecoder,
  old_e : Array[Double],
  start : Int,
  end : Int,
  fine_quant : Array[Int],
  fine_priority : Array[Int],
  bits_left : Int,
) -> Unit {
  let mut left = bits_left
  for prio in 0..<2 {
    let mut i = start
    while i < end && left >= 1 {
      if fine_quant[i] >= CEL_MAX_FINE_BITS || fine_priority[i] != prio {
        i += 1
        continue
      }
      let q2 = dec.dec_bits(1)
      let offset = (q2.to_double() - 0.5) /
        (1 << (fine_quant[i] + 1)).to_double()
      old_e[i] = old_e[i] + offset
      left -= 1
      i += 1
    }
  }
}
