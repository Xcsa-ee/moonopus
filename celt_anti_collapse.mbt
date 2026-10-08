// celt_anti_collapse.mbt
//
// 反塌缩处理（RFC 6716 §4.3.5 Anti-collapse Processing）。
//
// 瞬态帧的多个短 MDCT 可能让某些带在某些短块上能量归零，产生刺耳
// 伪影。解码端在瞬态且预算够时读一个反塌缩位；置位则对每个「塌缩」
// 的短块注入伪随机信号，幅度由该带两帧历史能量的较小者导出，注入后
// 对带区间重新归一化以保持能量守恒（§4.3.5 的两句要求）。
//
// 对应参考实现 celt_bands.c 的 anti_collapse（浮点路径）与
// celt_vq.c 的 renormalise_vector：
//
//   - 能量域与 §4.3.2 状态一致（log2 幅度），Ediff = logE −
//     min(prev1, prev2) 下限 0；单声道解码还要与 2*nbEBands 布局里
//     本带的声道 1 槽位取 max（参考实现 `!encode && C==1` 分支）；
//   - 注入幅度 r = min(thresh, 2·2^(−Ediff)·[LM=3 ×√2]) / √(N0<<LM)，
//     thresh = 0.5·2^((1+pulses)/N0 >> LM / −8) 按 1/8 bit 深度衰减；
//   - 塌缩判定读 collapse mask 的 bit k（短块序号），噪声符号来自
//     celt_lcg_rand 的 bit15，整段按 uint32 环绕；
//   - 频谱布局与 MDCT 一致：带 i 的带内下标是 (j<<LM)+k（j 为基准
//     bin、k 为短块），区间连续覆盖 [eband(i), eband(i+1))。

///|
/// 伪随机数推进（celt_bands.c 的 celt_lcg_rand），uint32 环绕。
/// 入参与返回值都按 u32 存在 Int64 里。
pub fn celt_lcg_rand(seed : Int64) -> Int64 {
  (seed * 1664525L + 1013904223L) & 0xFFFFFFFFL
}

///|
/// 带区间重新归一化（celt_vq.c 的 renormalise_vector，浮点路径）：
/// `x *= gain / sqrt(EPSILON + Σx²)`，就地修改 `x[off..<off+n]`。
/// EPSILON 是浮点构建的防零除下界（1e-15）。
pub fn celt_renormalise_vector(
  x : Array[Double],
  off : Int,
  n : Int,
  gain : Double,
) -> Unit {
  let mut e = 0.000000000000001
  for j in 0..<n {
    let v = x[off + j]
    e += v * v
  }
  let g = 1.0 / @math.pow(e, 0.5) * gain
  for j in 0..<n {
    x[off + j] = g * x[off + j]
  }
}

///|
/// §4.3.5 反塌缩：就地修正 `x` 中 [start, end) 各带的塌缩短块。
///
/// `collapse_masks[i]` 是带 i 的塌缩位图（bit k = 1<<LM 个短块序号，
/// 0 表示塌缩）；`band_log_e`/`prev1_log_e`/`prev2_log_e` 都按参考实现
/// 的 2*nbEBands 布局取值（单声道只用前半，本函数的 max 分支会读到
/// 声道 1 的占位槽）；`pulses[i]` 是该带分配到的位数（1/8 bit）。
/// `seed` 按值传入，不改解码器状态（参考实现传 st->rng 的拷贝）。
pub fn celt_anti_collapse(
  x : Array[Double],
  collapse_masks : Array[Int],
  lm : Int,
  start : Int,
  end : Int,
  band_log_e : Array[Double],
  prev1_log_e : Array[Double],
  prev2_log_e : Array[Double],
  pulses : Array[Int],
  seed : Int64,
) -> Unit {
  let m = 1 << lm
  let nb = CEL_NB_EBANDS
  let mut rng = seed
  for i in start..<end {
    let n0 = celt_band_bins(i, 1)
    let depth = celt_udiv(1 + pulses[i], n0) >> lm
    let thresh = 0.5 *
      @math.exp(0.6931471805599453094 * (-0.125 * depth.to_double()))
    let sqrt_1 = 1.0 / @math.pow((n0 << lm).to_double(), 0.5)
    // 单声道解码：prev 与 2*nbEBands 布局的声道 1 槽位取 max
    let mut prev1 = prev1_log_e[i]
    let mut prev2 = prev2_log_e[i]
    if prev1_log_e[nb + i] > prev1 {
      prev1 = prev1_log_e[nb + i]
    }
    if prev2_log_e[nb + i] > prev2 {
      prev2 = prev2_log_e[nb + i]
    }
    let mut ediff = band_log_e[i] - (if prev1 < prev2 { prev1 } else { prev2 })
    if ediff < 0.0 {
      ediff = 0.0
    }
    let mut r = 2.0 * @math.exp(0.6931471805599453094 * -ediff)
    if lm == 3 {
      r = r * 1.41421356
    }
    if thresh < r {
      r = thresh
    }
    r = r * sqrt_1
    let base = celt_eband(i, m)
    let mut renormalize = false
    for k in 0..<m {
      if ((collapse_masks[i] >> k) & 1) == 0 {
        for j in 0..<n0 {
          rng = celt_lcg_rand(rng)
          x[base + (j << lm) + k] = if (rng & 0x8000L) != 0L { r } else { -r }
        }
        renormalize = true
      }
    }
    if renormalize {
      celt_renormalise_vector(x, base, n0 << lm, 1.0)
    }
  }
}

///|
/// 反塌缩预留位数（celt_decoder.c 的 anti_collapse_rsv）：瞬态帧、
/// LM≥2 且可用预算不低于 (LM+2) 个 1/8-bit 单位时才预留 1 bit。
pub fn celt_anti_collapse_rsv(is_transient : Bool, lm : Int, bits : Int) -> Int {
  if is_transient && lm >= 2 && bits >= (lm + 2) << CEL_BITRES {
    1 << CEL_BITRES
  } else {
    0
  }
}

///|
/// 反塌缩标志位解码（celt_decoder.c：预留了才读，读 1 个 raw bit）。
pub fn celt_decode_anti_collapse_flag(dec : RangeDecoder, rsv : Int) -> Int {
  if rsv > 0 {
    dec.dec_bits(1)
  } else {
    0
  }
}
