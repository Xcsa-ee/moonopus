// celt_imdct.mbt
//
// IMDCT 与帧合成缓冲（RFC 6716 §4.3.7）：把频域输出变回时域帧，并维护
// 跨帧的 TDAC 衔接。RFC §4.3.7 只说「N 进 2N 出、缩放 1/2、low-overlap
// 窗」，具体对齐由参考实现 mdct.c / celt_celt_decoder.c 定死，这里逐段
// 对应（浮点构建路径）：
//
//   - 预旋转：x1 = in[2i]，x2 = in[N/2-1-2i]，乘 (−sin, cos) 对
//     t[2i] = −sin(2π(i+1/8)/N)、t[2i+1] = cos(2π(i+1/8)/N)，N 随 shift
//     减半取 trig 表的后段（clt_mdct_init 的生成式）；
//   - FFT：kiss 的输入按 digit-reverse 表就地摆放，opus_fft_impl 原地
//     蝶形、输出自然序——两者复合等价于对自然序 z 做一次未缩放的
//     e^{−2πi} DFT（数值钉定：与 RFC 余弦和逐位吻合到 1e-11），所以
//     这里直接对自然序 z 做 DFT，不必复刻 bitrev 存储；
//   - 后旋转：FFT 输出交错回缓冲 [ov/2, ov/2+N/2)，再按下标对
//     (i, N4-1-i) 成对旋转、读写交换实虚部（"swap real and imag because
//     we're using an FFT instead of an IFFT"）；
//   - 输出对齐：缓冲 raw 段恰为 2M 样本余弦和定义的中段 y[M/2, 3M/2)
//     （数值钉定，gen 端以独立余弦和复核）；
//   - 镜像与衔接：上一帧 raw 尾部 ov/2 个样本先落到缓冲头部（等价
//     celt_decode_frame 开头的 OPUS_MOVE），再对 [base, base+overlap)
//     就地做 power-complementary 镜像，混合就是 §4.3.7 的加权重叠；
//   - 瞬态帧：B = 2^LM 个 120 系数块按 freq[b + B·k] 交错取块，shift
//     恒为 maxLM = 3，逐块 raw（偏移 120·b）与镜像前后衔接成整帧；
//   - 长度恒等：每块 raw 恰好 60+120b 起连续铺满整帧，块间与帧间都只
//     留 ov/2 的衔接尾巴，帧输出 = 缓冲 [0, N)，新 pending = [N, N+60)。
//
// 参考实现对 IMDCT 输出的 SATURATE 在浮点构建下是恒等宏，不实现。

///|
/// 模式 overlap：`(shortMdctSize>>2)<<2`，48 kHz 标准模式为 120。
/// 也是镜像区与跨帧 pending（ov/2 = 60）的长度基准。
pub const CEL_OVERLAP : Int = 120

///|
/// IMDCT 长度基准 l->n = 2·shortMdctSize·nbShortMdcts = 1920，按 shift
/// 减半。
fn imdct_len(shift : Int) -> Int {
  let mut n = 1920
  let mut i = 0
  while i < shift {
    n = n >> 1
    i = i + 1
  }
  n
}

///|
/// 预旋转用的三角表（clt_mdct_init float 生成式，按 shift 取块）：
/// `t[2i] = −sin(2π(i+0.125)/N)`，`t[2i+1] = cos(2π(i+0.125)/N)`。
fn imdct_trig(shift : Int) -> Array[Double] {
  let n = imdct_len(shift)
  let n4 = n >> 2
  let t = Array::make(n4 << 1, 0.0)
  let two_pi = 6.283185307179586
  let nd = n.to_double()
  for i in 0..<n4 {
    let a = two_pi * (i.to_double() + 0.125) / nd
    t[2 * i] = 0.0 - @math.sin(a)
    t[2 * i + 1] = @math.cos(a)
  }
  t
}

///|
/// 预旋转：系数序列 -> 自然序复数（交错 [re0, im0, re1, im1, ...]）。
/// `x1 = x[2i]`、`x2 = x[N/2-1-2i]`；输出槽位 `z[2i] = yi`、
/// `z[2i+1] = yr`（C 端写进 digit-reverse 槽位后即 DFT 的输入，见文件
/// 头注释）。
fn imdct_pre_rotate(x : Array[Double], shift : Int) -> Array[Double] {
  let n = imdct_len(shift)
  let n2 = n >> 1
  let n4 = n >> 2
  let t = imdct_trig(shift)
  let z = Array::make(n4 << 1, 0.0)
  for i in 0..<n4 {
    let x1 = x[2 * i]
    let x2 = x[n2 - 1 - 2 * i]
    let c = t[2 * i + 1]
    let s = t[2 * i]
    let yr = x2 * c + x1 * s
    let yi = x1 * c - x2 * s
    z[2 * i] = yi
    z[2 * i + 1] = yr
  }
  z
}

///|
/// 未缩放的 e^{−2πi} DFT：输出同样是交错复数。twiddle 表按
/// `m = (j·k) mod N4` 索引，O(N²) 直接求和。
fn imdct_dft(z : Array[Double], n4 : Int) -> Array[Double] {
  let two_pi = 6.283185307179586
  let nd = n4.to_double()
  let tw = Array::make(n4 << 1, 0.0)
  for m in 0..<n4 {
    let a = two_pi * m.to_double() / nd
    tw[2 * m] = @math.cos(a)
    tw[2 * m + 1] = 0.0 - @math.sin(a)
  }
  let out = Array::make(n4 << 1, 0.0)
  for j in 0..<n4 {
    let mut sr = 0.0
    let mut si = 0.0
    for k in 0..<n4 {
      let m = j * k % n4
      let cr = tw[2 * m]
      let ci = tw[2 * m + 1]
      let zr = z[2 * k]
      let zi = z[2 * k + 1]
      sr = sr + zr * cr - zi * ci
      si = si + zr * ci + zi * cr
    }
    out[2 * j] = sr
    out[2 * j + 1] = si
  }
  out
}

///|
/// 后旋转与去交错：Z 交错写入 `buf[base+ov/2, base+ov/2+N/2)`，再按
/// (i, N4-1-i) 成对旋转。读写顺序与 mdct.c 一致：两侧的 (re, im) 都先
/// 读完再落笔；N4 为偶数时中间对不重叠。
fn imdct_post_rotate(
  buf : Array[Double],
  base : Int,
  z : Array[Double],
  shift : Int,
) -> Unit {
  let n = imdct_len(shift)
  let n2 = n >> 1
  let n4 = n >> 2
  let t = imdct_trig(shift)
  let yp = base + (CEL_OVERLAP >> 1)
  for j in 0..<n4 {
    buf[yp + 2 * j] = z[2 * j]
    buf[yp + 2 * j + 1] = z[2 * j + 1]
  }
  let mut yp0 = yp
  let mut yp1 = yp + n2 - 2
  let mut i = 0
  while i < (n4 + 1) >> 1 {
    // 实虚交换：用 FFT 顶替 IFFT 的代价是把槽位读反过来
    let re = buf[yp0 + 1]
    let im = buf[yp0]
    let t0 = t[2 * i]
    let t1 = t[2 * i + 1]
    let yr = re * t1 + im * t0
    let yi = re * t0 - im * t1
    let re2 = buf[yp1 + 1]
    let im2 = buf[yp1]
    buf[yp0] = yr
    buf[yp1 + 1] = yi
    let u = n4 - i - 1
    let u0 = t[2 * u]
    let u1 = t[2 * u + 1]
    buf[yp1] = re2 * u1 + im2 * u0
    buf[yp0 + 1] = re2 * u0 - im2 * u1
    yp0 = yp0 + 2
    yp1 = yp1 - 2
    i = i + 1
  }
}

///|
/// TDAC 镜像：就地混合 `buf[base, base+overlap)`（旧值两侧同时读，先读
/// 后写）。`win[i]` 为预取的 sine 窗。
///
///     out[i]     = old[i]·w[L-1-i] - old[L-1-i]·w[i]
///     out[L-1-i] = old[i]·w[i]     + old[L-1-i]·w[L-1-i]
fn imdct_mirror(buf : Array[Double], base : Int, win : Array[Double]) -> Unit {
  let ov = win.length()
  let half = ov >> 1
  for i in 0..<half {
    let x1 = buf[base + ov - 1 - i]
    let x2 = buf[base + i]
    let w1 = win[i]
    let w2 = win[ov - 1 - i]
    buf[base + i] = x2 * w2 - x1 * w1
    buf[base + ov - 1 - i] = x2 * w1 + x1 * w2
  }
}

///|
/// 单块变换写入并镜像：`buf[base .. base+overlap+块长)`。
fn imdct_write_block(
  buf : Array[Double],
  base : Int,
  x : Array[Double],
  shift : Int,
  win : Array[Double],
) -> Unit {
  let z = imdct_pre_rotate(x, shift)
  let n4 = imdct_len(shift) >> 2
  let zf = imdct_dft(z, n4)
  imdct_post_rotate(buf, base, zf, shift)
  imdct_mirror(buf, base, win)
}

///|
/// 一帧频谱 -> 时域帧与新 pending（§4.3.7）。
///
/// `freq` 长 `120 << lm`，瞬态帧按 `freq[b + 2^lm·k]` 交错取块；
/// `pending` 是上一帧 raw 尾部 `CEL_OVERLAP/2` 个样本（首帧全 0）。
/// 返回 `(帧输出[N], 新 pending)`，均为新数组。内部缓冲布局与参考
/// 实现的 out_syn 一致：`[0, ov/2)` 先承接上一帧尾，raw 段从 `ov/2`
/// 起，镜像、取输出、截尾巴一气呵成。
pub fn celt_imdct_frame(
  freq : Array[Double],
  lm : Int,
  is_transient : Bool,
  pending : Array[Double],
) -> (Array[Double], Array[Double]) {
  let n_frame = CEL_SHORT_MDCT << lm
  let ov2 = CEL_OVERLAP >> 1
  let win = Array::make(CEL_OVERLAP, 0.0)
  for i in 0..<CEL_OVERLAP {
    win[i] = celt_window(i, CEL_OVERLAP)
  }
  let buf = Array::make(n_frame + CEL_OVERLAP, 0.0)
  for i in 0..<ov2 {
    buf[i] = pending[i]
  }
  if is_transient {
    let blocks = 1 << lm
    let x = Array::make(CEL_SHORT_MDCT, 0.0)
    for b in 0..<blocks {
      for k in 0..<CEL_SHORT_MDCT {
        x[k] = freq[b + blocks * k]
      }
      imdct_write_block(buf, CEL_SHORT_MDCT * b, x, 3, win)
    }
  } else {
    let x = Array::make(n_frame, 0.0)
    for k in 0..<n_frame {
      x[k] = freq[k]
    }
    imdct_write_block(buf, 0, x, 3 - lm, win)
  }
  let out = Array::make(n_frame, 0.0)
  for i in 0..<n_frame {
    out[i] = buf[i]
  }
  let new_pending = Array::make(ov2, 0.0)
  for i in 0..<ov2 {
    new_pending[i] = buf[n_frame + i]
  }
  (out, new_pending)
}
