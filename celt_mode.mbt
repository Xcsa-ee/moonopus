// celt_mode.mbt
//
// CELT 层的模式结构：频带布局、帧长参数、去重 emphasis 系数与窗函数。
//
// 频带边界不存静态表，而是由 eband5ms（libopus celt/modes.c）乘以帧长
// 缩放因子 M = frame_size/120 得到——参考实现对所有 2.5ms 短块模式
// （含标准 48kHz）走这一分支。由此算出的每带 MDCT bin 数与 RFC 6716
// Table 55 完全一致（测试侧独立核对）。
//
// 版权归属（eband5ms 提取自 xiph/opus 的 celt/modes.c，BSD-3-Clause，
// 完整文本见仓库 LICENSE-LIBOPUS）：
// Copyright 2001-2023 Xiph.Org, Skype Limited, Octasic,
// Jean-Marc Valin, Timothy B. Terriberry, CSIRO, Gregory Maxwell,
// Mark Borgerding, Erik de Castro Lopo, Mozilla, Amazon
// 来源文件自带的声明：
// Copyright (c) 2007-2008 CSIRO
// Copyright (c) 2007-2009 Xiph.Org Foundation
// Copyright (c) 2008 Gregory Maxwell
// Written by Jean-Marc Valin and Gregory Maxwell

///|
/// 5ms 分辨率的频带边界（nbEBands + 1 = 22 项）。单位是「5ms 短块」，
/// 实际 bin 索引 = 值 × M，M = frame_size / 120。
let cel_eband5ms : Array[Int] = [
  0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24, 28, 34, 40, 48, 60, 78, 100,
]

///|
/// 标准 CELT 模式的带数（§4.3 说正常使用 21 个带）。
pub const CEL_NB_EBANDS : Int = 21

///|
/// 2.5ms 短块的样本数（48 kHz），也是 eband5ms 的单位基准。
pub const CEL_SHORT_MDCT : Int = 120

///|
/// 频带 i 的起始 bin（已乘缩放因子 M）。
///
/// `m` 为帧长缩放（2.5ms→1、5ms→2、10ms→4、20ms→8）。
pub fn celt_eband(i : Int, m : Int) -> Int {
  cel_eband5ms[i] * m
}

///|
/// 频带 i 的 MDCT bin 数。
pub fn celt_band_bins(i : Int, m : Int) -> Int {
  (cel_eband5ms[i + 1] - cel_eband5ms[i]) * m
}

///|
/// 编码覆盖的最大 bin 数（band 21 的边界）。
///
/// 注意它小于 MDCT 长度 `120*m`：20ms 帧为 800 < 960，即 20–24 kHz
/// 不参与编码（§4.3 的 band 20 终止于 20000 Hz）。
pub fn celt_max_bin(m : Int) -> Int {
  cel_eband5ms[CEL_NB_EBANDS] * m
}

///|
/// 帧长缩放 LM（§4.3 Table 55 的帧尺寸列）：120×2^LM 样本。
///
/// 2.5/5/10/20 ms 对应 LM = 0/1/2/3。
pub fn celt_lm_of_frame_samples(samples : Int) -> Int? {
  if samples == 120 {
    Some(0)
  } else if samples == 240 {
    Some(1)
  } else if samples == 480 {
    Some(2)
  } else if samples == 960 {
    Some(3)
  } else {
    None
  }
}

///|
/// 去重 emphasis 系数（48 kHz）：`alpha_p = 0.8500061035`。
///
/// 对应 §4.3.7.2 的 `1/A(z) = 1/(1 - alpha_p·z⁻¹)`，也即编码端
/// `A(z) = 1 - 0.85·z⁻¹`（48 kHz 标准预加重）的逆。参考实现
/// modes.c 对 48 kHz 的 preemph[1..3] 均为 0/1/1，故只有一个有效系数。
pub const CEL_DEEMPH_COEF : Double = 0.8500061035

///|
/// 去重 emphasis（§4.3.7.2）：一阶 IIR，`y[n] = x[n] + alpha_p·y[n-1]`。
///
/// 输入为 post-filter 后的时域样本，结果就地写入 `out`。`mem` 是上一帧
/// 保留的递推状态，返回值是本帧结束后的状态（解码器跨帧保存）。与参考
/// 实现 `celt_deemphasis_c` 的内层循环一致。
pub fn celt_deemphasis(
  input : Array[Double],
  out : Array[Double],
  mem : Double,
) -> Double {
  let mut m = mem
  for j in 0..<input.length() {
    let tmp = input[j] + m
    out[j] = tmp
    m = CEL_DEEMPH_COEF * tmp
  }
  m
}

///|
/// sine 窗：`sin(π/2 · sin²(π/2 · (i+0.5)/overlap))`。
///
/// 直接对应 libopus modes.c 的 window 生成式（float 构建）。用于 IMDCT
/// 的 50% 重叠合成与 post-filter 的窗控。
pub fn celt_window(i : Int, overlap : Int) -> Double {
  let half_pi = 1.5707963267948966
  let u = half_pi * (i.to_double() + 0.5) / overlap.to_double()
  let s = @math.sin(u)
  @math.sin(half_pi * s * s)
}

///|
/// §4.3.3 各带的最大分配上限 cap[]（0 号声道到 nbEBands-1）。
///
/// 表按 `caps[nbEBands*(2*LM + C - 1) + i]` 取值——与 §4.3.3 描述的
/// 「i = nbBands*(2*LM+stereo)」同式，再按 `(值+64)*C*N>>2` 换算成该带
/// 最多可用的比特数（N 为该带的 MDCT bin 数，`>>2` 即规范的「除以 4」）。
///
/// 这一步是规范点名要与参考实现一致的换算，后续比特分配直接消费结果。
pub fn celt_init_caps(lm : Int, channels : Int) -> Array[Int] {
  let base = CEL_NB_EBANDS * (2 * lm + channels - 1)
  let cap = Array::make(CEL_NB_EBANDS, 0)
  for i in 0..<CEL_NB_EBANDS {
    let n = celt_band_bins(i, 1 << lm)
    cap[i] = ((cel_cache_caps50[base + i].to_int() + 64) * channels * n) >> 2
  }
  cap
}
