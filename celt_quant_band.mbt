// celt_quant_band.mbt
//
// 带级量化解码入口（RFC 6716 §4.3.4 Shape Decoding 的 band 层）。
//
// 对应参考实现 celt_bands.c 的 quant_band() 解码侧，四段结构：
//
//   1. n==1 特例：预算够就读 1 个 raw bit 作符号，输出 ±1（不乘 gain）；
//   2. 前段：按 TF 布局变换 fill 位图；有折叠源时先对它施加前向 TF
//      变换（编码端对 X 做同样的变换，解码端到 lowband 上）；
//   3. 中段：celt_partition_rec 递归分割解码，叶上完成谱应用
//      （归一化/旋转/噪声与折叠填充，见 celt_partition.mbt）；
//   4. 后段：celt_tf_inverse 把已解码向量还原到频序；cm 按同一布局
//      反向变换并按最终 B 掩蔽；可选写 lowband_out（×√N0，供后续
//      等长带折叠）。
//
// 带级 fill 的 TF 位图变换与 cm 的反向变换和 TF 链共用 celt_tf_layout
// 推导出的结构参数，避免两处各写一遍推导。

///|
/// fill 位图的 4 bit 交织表（celt_bands.c 的 bit_interleave_table）。
let cel_bit_interleave : Array[Int] = [
  0, 1, 1, 1, 2, 3, 3, 3, 2, 3, 3, 3, 2, 3, 3, 3,
]

///|
/// cm 的 4 bit 反交织表（celt_bands.c 的 bit_deinterleave_table）。
let cel_bit_deinterleave : Array[Int] = [
  0x00, 0x03, 0x0C, 0x0F, 0x30, 0x33, 0x3C, 0x3F, 0xC0, 0xC3, 0xCC, 0xCF, 0xF0, 0xF3,
  0xFC, 0xFF,
]

///|
/// fill 的正向 TF 位图变换（C 前段循环的 fill 部分：recombine 段按
/// 4 bit 交织表重排，时间段逐级 `fill |= fill<<B`）。
fn celt_fill_transform(fill : Int, lay : CelTfLayout) -> Int {
  let mut f = fill
  for _ in 0..<lay.recombine {
    f = cel_bit_interleave[f & 0xF] | (cel_bit_interleave[f >> 4] << 2)
  }
  let mut bb = lay.b_start
  for _ in 0..<lay.time_divide {
    f = f | (f << bb)
    bb = bb << 1
  }
  f
}

///|
/// cm 的反向 TF 变换（C resynth 段的 cm 部分；X 的变换由 tf_inverse
/// 完成）：时间分辨率循环逐级 `cm |= cm>>B`，recombine 段按 4 bit
/// 反交织表重排，最后按 `B<<=recombine` 后的位宽掩蔽。
fn celt_cm_transform(cm : Int, lay : CelTfLayout) -> Int {
  let mut c = cm
  let mut bb = lay.b_end
  for _ in 0..<lay.time_divide {
    bb = bb >> 1
    c = c | (c >> bb)
  }
  for _ in 0..<lay.recombine {
    c = cel_bit_deinterleave[c]
  }
  bb = bb << lay.recombine
  c & ((1 << bb) - 1)
}

///|
/// 带级解码。`x` 是本带频谱（长度 n，就地写入）；`lowband` 是折叠源
/// （空数组 = 无折叠，q==0 走噪声路径；非空则长度 n，本函数会先对它
/// 做前向 TF 变换，与参考实现同样修改入参）；`lowband_out` 非空时在
/// 末尾写入 ×√N0 的折叠预缩放。`fill` 是带级填充位图（先做 TF 位图
/// 变换再下传）。返回 (collapse mask, seed, 剩余预算)。
pub fn celt_quant_band(
  dec : RangeDecoder,
  x : Array[Double],
  lowband : Array[Double],
  band : Int,
  lm : Int,
  n : Int,
  b : Int,
  blocks : Int,
  tf_change : Int,
  fill : Int,
  gain : Double,
  spread : Int,
  seed : Int64,
  remaining : Int,
  lowband_out : Array[Double],
) -> (Int, Int64, Int) {
  // ---- n==1：quant_band_n1 的符号位 ----
  if n == 1 {
    let mut rem = remaining
    let mut sign = 0
    if rem >= 1 << CEL_BITRES {
      sign = dec.dec_bits(1)
      rem -= 1 << CEL_BITRES
    }
    x[0] = if sign != 0 { -1.0 } else { 1.0 }
    if lowband_out.length() > 0 {
      lowband_out[0] = x[0]
    }
    return (1, seed, rem)
  }
  let lay = celt_tf_layout(n, blocks, tf_change)
  let fill_tf = celt_fill_transform(fill, lay)
  if lowband.length() > 0 {
    celt_tf_forward(lowband, n, blocks, tf_change)
  }
  let splits : Array[CeltThetaSplit] = []
  let leaves : Array[CeltPartitionLeaf] = []
  let ctx = CeltBandCtx::{
    active: true,
    x,
    lowband,
    has_lowband: lowband.length() > 0,
    spread,
    seed: [seed],
  }
  let (rem2, cm_raw) = celt_partition_rec(
    dec,
    band,
    lm,
    n,
    b,
    lay.b_end,
    fill_tf,
    remaining,
    splits,
    leaves,
    ctx,
    0,
    0,
    gain,
  )
  celt_tf_inverse(x, n, blocks, tf_change)
  let cm = celt_cm_transform(cm_raw, lay)
  if lowband_out.length() > 0 {
    let s = @math.pow(n.to_double(), 0.5)
    for j in 0..<n {
      lowband_out[j] = s * x[j]
    }
  }
  (cm, ctx.seed[0], rem2)
}
