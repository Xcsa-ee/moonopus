// celt_postfilter.mbt
//
// 后滤波（RFC 6716 §4.3.7.1）：基音周期 comb 滤波，输出
//
//     y(n) = x(n) + G·(g0·y(n-T) + g1·(y(n-T+1)+y(n-T-1))
//                       + g2·(y(n-T+2)+y(n-T-2)))
//
// RFC 正文式子有排版重复（两侧写成同一下标），这里按参考实现
// celt_celt.c 的 comb_filter / comb_filter_const 浮点路径逐项对齐：
//
//   - 抽头 = G 不参与逐项相乘，而是分成 g0·gains[ts]、g1·gains[ts] 两组，
//     gains 表就是 RFC 给的三组 tapset 系数（float 构建 QCONST16 恒等）；
//   - 过渡段（前 overlap 个样本）用 MDCT 窗平方做逐点插值：f = w[i]²，
//     (1−f) 加权旧参数（T0/ts0）、f 加权新参数（T1/ts1），且 y 逐点
//     回读——必须在位滤波，先读后写，后面的项读到的已是插值后的值；
//   - 周期钳到 ≥ COMBFILTER_MINPERIOD（调用方与函数内双重钳制，同 C）；
//     旧新参数全等时过渡段整体跳过（窗只用于参数切换）；
//   - 过渡段之后若新增益为 0，后段原样保留；否则跑常数段
//     （comb_filter_const，固定 T1/ts1 的直接递推）。
//
// 调用形态（celt_decode_frame）：帧首 120 样本用（旧→新）过渡，
// LM≠0 时其余样本再以（新→新）跑一遍（参数全等自动走常数段）。
// 解码器随后把旧参数轮换为新参数。
//
// 对 buf 的要求：`base` 之前需保留 ≥ 1022 个历史样本（解码端的
// decode_mem 提供），函数只写 `buf[base, base+n)`，且 n ≥ overlap
// （过渡段激活时，同参考实现的调用约定）。

///|
/// 最小基音周期（celt_celt.h 的 COMBFILTER_MINPERIOD）。
pub const CEL_COMB_MINPERIOD : Int = 15

///|
/// tapset 抽头系数表（RFC §4.3.7.1），行 = tapset 0/1/2，
/// 列 = (g0 分量的 3 个系数)。索引 `3*ts + j`。
let cel_tap_gains : Array[Double] = [
  0.306640625, 0.2170410156, 0.1296386719, 0.4638671875, 0.2680664062, 0.0, 0.7998046875,
  0.1000976562, 0.0,
]

///|
/// 后滤波 comb 滤波，就地作用于 `buf[base, base+n)`。
///
/// `t0/g0/ts0` 为旧参数、`t1/g1/ts1` 为新参数（G 已折算进 g），
/// `win` 为预取的 MDCT 窗（长度即 overlap）。实现顺序与参考实现
/// 一致：全零捷径 → 钳制 → 过渡段（滑动状态读 f 分支的四个历史
/// 样本）→ 新增益零捷径 → 常数段。
pub fn celt_comb_filter(
  buf : Array[Double],
  base : Int,
  t0 : Int,
  t1 : Int,
  n : Int,
  g0 : Double,
  g1 : Double,
  ts0 : Int,
  ts1 : Int,
  win : Array[Double],
) -> Unit {
  if g0 == 0.0 && g1 == 0.0 {
    return
  }
  let tp0 = if t0 < CEL_COMB_MINPERIOD { CEL_COMB_MINPERIOD } else { t0 }
  let tp1 = if t1 < CEL_COMB_MINPERIOD { CEL_COMB_MINPERIOD } else { t1 }
  let g00 = g0 * cel_tap_gains[3 * ts0]
  let g01 = g0 * cel_tap_gains[3 * ts0 + 1]
  let g02 = g0 * cel_tap_gains[3 * ts0 + 2]
  let g10 = g1 * cel_tap_gains[3 * ts1]
  let g11 = g1 * cel_tap_gains[3 * ts1 + 1]
  let g12 = g1 * cel_tap_gains[3 * ts1 + 2]
  let mut overlap = win.length()
  if g0 == g1 && tp0 == tp1 && ts0 == ts1 {
    overlap = 0
  }
  // f 分支的四个滑动样本：等价于逐点直读（t≥15 保证读取位点在当前
  // 写入位点之前，原值/插值后值一致），保持与参考实现同一读取顺序
  let mut x1 = buf[base - tp1 + 1]
  let mut x2 = buf[base - tp1]
  let mut x3 = buf[base - tp1 - 1]
  let mut x4 = buf[base - tp1 - 2]
  let mut i = 0
  while i < overlap {
    let x0 = buf[base + i - tp1 + 2]
    let w = win[i]
    let f = w * w
    let omf = 1.0 - f
    let mut acc = buf[base + i]
    acc = acc + omf * g00 * buf[base + i - tp0]
    acc = acc + omf * g01 * (buf[base + i - tp0 + 1] + buf[base + i - tp0 - 1])
    acc = acc + omf * g02 * (buf[base + i - tp0 + 2] + buf[base + i - tp0 - 2])
    acc = acc + f * g10 * x2
    acc = acc + f * g11 * (x1 + x3)
    acc = acc + f * g12 * (x0 + x4)
    buf[base + i] = acc
    x4 = x3
    x3 = x2
    x2 = x1
    x1 = x0
    i = i + 1
  }
  if g1 == 0.0 {
    return
  }
  while i < n {
    let mut acc = buf[base + i]
    acc = acc + g10 * buf[base + i - tp1]
    acc = acc + g11 * (buf[base + i - tp1 + 1] + buf[base + i - tp1 - 1])
    acc = acc + g12 * (buf[base + i - tp1 + 2] + buf[base + i - tp1 - 2])
    buf[base + i] = acc
    i = i + 1
  }
}
