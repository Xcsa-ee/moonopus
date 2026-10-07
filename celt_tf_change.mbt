// celt_tf_change.mbt
//
// 带内时间-频率分辨率调整（RFC 6716 §4.3.4.5）。
//
// 每带的 TF 选择（§4.3.1 已解出的 tf_res，取值 −3..+3）要落实到该带的解码
// 向量上：正数提高频率分辨率，负数提高时间分辨率，两者都用 Hadamard 变换
// 实现。参考实现把它放在 quant_band() 里、量化前后各一段，本文件的两条链
// 就分别对应那两段：
//
//   - 前向：解码前作用于折叠源 lowband（编码端作用于待量化的向量）；
//   - 反向：解码后作用于量化域的已解码向量，把它还原到频序。
//
// RFC 对这两段只给了意图（"N levels of the Hadamard transform"），没给步长
// 与次序，所以结构参数一律从参考实现的代码推出，并由两条链共用同一份推导
// ——两处各写一遍才是真正的分叉风险。

///|
/// Haar 归一常数。参考实现 celt/bands.c 写的是 QCONST32(.70710678f,31)，
/// 在 float 构建下退化为字面量 0.70710678f；它只是 1/sqrt(2) 的十进制近似
/// （真值 0.7071067811865475…），故一次 Haar 往返的合成增益是
/// 2*0.70710678² ≈ 1 − 3.36e-9（三级约 1 − 1.01e-8）而非严格的 1，
/// 互逆测试的容差据此放宽。
const CEL_HAAR_C : Double = 0.70710678

///|
/// TF 链的结构参数，由 (n, b, tf_change) 唯一确定，正反两条链共用。
priv struct CelTfLayout {
  // 频率分辨率上调的 Haar 级数（tf_change > 0）
  recombine : Int
  // 时间分辨率上调的 Haar 级数（tf_change < 0）
  time_divide : Int
  // 时间分辨率循环的起点（前向从这里往下走）
  b_start : Int
  nb_start : Int
  // 时间分辨率循环的终点（反向从这里往回退）
  b_end : Int
  nb_end : Int
  // 重排的 (N0, stride)；参考实现 `if (B0>1)` 不成立时置 0 表示跳过
  deint_n0 : Int
  deint_stride : Int
  // §4.3.4.5：提高时间分辨率时解码器按 sequency 序重排（长块帧才走这支）
  long_blocks : Bool
}

///|
/// 推导 TF 链结构。逐行对应参考实现 quant_band() 里 recombine、时间分辨率
/// 循环、以及重排参数的三处赋值。
///
/// `n` 是带的维数，`b` 是时间块数（长块帧为 1，瞬态帧为 M=2^LM）。
fn celt_tf_layout(n : Int, b : Int, tf_change : Int) -> CelTfLayout {
  let long_blocks = b == 1
  let recombine = if tf_change > 0 { tf_change } else { 0 }
  let b_start = b / (1 << recombine)
  let nb_start = n / b * (1 << recombine)
  // 只有块内样本数为偶数才能再对折一级；tf_change 每级 +1，到 0 即停，
  // 故级数不超过 −tf_change ≤ 3——这一上界同时保证下面 hadamard 路径的
  // stride ≤ 8，不会越过 ordery 表覆盖的 16。
  let mut bb = b_start
  let mut nb = nb_start
  let mut tc = tf_change
  let mut time_divide = 0
  while (nb & 1) == 0 && tc < 0 {
    bb = bb * 2
    nb = nb / 2
    time_divide = time_divide + 1
    tc = tc + 1
  }
  let b_end = bb
  let nb_end = nb
  let do_deint = b_end > 1
  CelTfLayout::{
    recombine,
    time_divide,
    b_start,
    nb_start,
    b_end,
    nb_end,
    deint_n0: if do_deint {
      nb_end / (1 << recombine)
    } else {
      0
    },
    deint_stride: if do_deint {
      b_end * (1 << recombine)
    } else {
      0
    },
    long_blocks,
  }
}

///|
/// haar1(X, N0, stride)：把向量看成 stride 条链（链内步长 stride），每条链
/// 两两做一次 Haar 并原地写回。链 j 的第 i 对是
/// (X[stride*2j+i], X[stride*(2j+1)+i])，覆盖 stride*2*(N0/2) 个元素。
fn celt_haar1(x : Array[Double], n0 : Int, stride : Int) -> Unit {
  let half = n0 / 2
  for i in 0..<stride {
    for j in 0..<half {
      let ia = stride * 2 * j + i
      let ib = stride * (2 * j + 1) + i
      let t1 = CEL_HAAR_C * x[ia]
      let t2 = CEL_HAAR_C * x[ib]
      x[ia] = t1 + t2
      x[ib] = t1 - t2
    }
  }
}

///|
/// 把交错序（X[j*stride+i]）还原成分块序：第 i 条链写进第 (hadamard ?
/// ordery[i] : i) 块，块内按 j 连续。覆盖 n0*stride 个元素。
fn celt_deinterleave(
  x : Array[Double],
  n0 : Int,
  stride : Int,
  hadamard : Bool,
) -> Unit {
  let n = n0 * stride
  let tmp = Array::make(n, 0.0)
  for i in 0..<stride {
    let dst = if hadamard { cel_orderery[stride - 2 + i] } else { i }
    for j in 0..<n0 {
      tmp[dst * n0 + j] = x[j * stride + i]
    }
  }
  for k in 0..<n {
    x[k] = tmp[k]
  }
}

///|
/// celt_deinterleave 的逆：分块序 → 交错序。两条互逆是测试里的精确不变量。
fn celt_interleave(
  x : Array[Double],
  n0 : Int,
  stride : Int,
  hadamard : Bool,
) -> Unit {
  let n = n0 * stride
  let tmp = Array::make(n, 0.0)
  for i in 0..<stride {
    let src = if hadamard { cel_orderery[stride - 2 + i] } else { i }
    for j in 0..<n0 {
      tmp[j * stride + i] = x[src * n0 + j]
    }
  }
  for k in 0..<n {
    x[k] = tmp[k]
  }
}

///|
/// 前向 TF 变换：作用于解码前的折叠源（编码端作用于待量化的向量）。
///
/// 三步顺序对应参考实现里 recombine 循环、时间分辨率循环、重排三段代码。
/// 反向链按相反次序撤销，两条链互逆由测试保证。
pub fn celt_tf_forward(
  x : Array[Double],
  n : Int,
  b : Int,
  tf_change : Int,
) -> Unit {
  let lay = celt_tf_layout(n, b, tf_change)
  for k in 0..<lay.recombine {
    celt_haar1(x, n >> k, 1 << k)
  }
  let mut bb = lay.b_start
  let mut nb = lay.nb_start
  let mut td = 0
  while td < lay.time_divide {
    celt_haar1(x, nb, bb)
    bb = bb * 2
    nb = nb / 2
    td = td + 1
  }
  if lay.deint_stride > 0 {
    celt_deinterleave(x, lay.deint_n0, lay.deint_stride, lay.long_blocks)
  }
}

///|
/// 反向 TF 变换：解码后作用于量化域的已解码向量，还原到频序。
pub fn celt_tf_inverse(
  x : Array[Double],
  n : Int,
  b : Int,
  tf_change : Int,
) -> Unit {
  let lay = celt_tf_layout(n, b, tf_change)
  if lay.deint_stride > 0 {
    celt_interleave(x, lay.deint_n0, lay.deint_stride, lay.long_blocks)
  }
  let mut bb = lay.b_end
  let mut nb = lay.nb_end
  let mut td = 0
  while td < lay.time_divide {
    bb = bb / 2
    nb = nb * 2
    celt_haar1(x, nb, bb)
    td = td + 1
  }
  for k in 0..<lay.recombine {
    celt_haar1(x, n >> k, 1 << k)
  }
}
