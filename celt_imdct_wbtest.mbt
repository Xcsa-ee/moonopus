// celt_imdct_wbtest.mbt
//
// IMDCT 与帧合成（§4.3.7）的白盒测试。
//
// 主测试不依赖参考端，靠规范与实现结构自身的性质：
//   1. DFT 帕塞瓦尔：未缩放变换满足 Σ|X|² = N·Σ|x|²；
//   2. DFT δ 探针：单点输入的谱是纯平面波（符号与归一化一并钉死）；
//   3. raw 中段恒等：缓冲 raw 段逐点等于 RFC 余弦和
//      `Σ_k x[k]·cos(π/M·(j+M+1/2)·(k+1/2))`（2×1/2 已折叠），测试
//      内的直接三重循环与被测的 FFT 路径完全独立；
//   4. 镜像能量守恒：窗互补 w[i]²+w[L-1-i]² = 1 使每对镜像前后
//      平方和不变；
//   5. 线性性（pending 全 0 时整条合成管线是线性的）；
//   6. 零谱 -> 全零输出与零 pending（精确相等）；
//   7. pending 贯穿：第二帧零谱时，帧首 120 个样本只由上一帧尾巴
//      加窗得到，逐点闭式可验。
//
// 金标（独立 Python 端：RFC 余弦和直接定义）另在 imdct_goldens_wbtest.mbt。

///|
/// RFC 余弦和直接算 raw 段：`Σ_k x[k]·cos(π/M·(j+M+1/2)·(k+1/2))`。
/// 与被测实现的 FFT 路径不共享任何代码。
fn imdct_raw_direct(x : Array[Double]) -> Array[Double] {
  let m = x.length()
  let md = m.to_double()
  let pi = 3.141592653589793
  let raw = Array::make(m, 0.0)
  for j in 0..<m {
    let arg0 = pi / md * (j.to_double() + md + 0.5)
    let mut acc = 0.0
    for k in 0..<m {
      if x[k] != 0.0 {
        acc = acc + x[k] * @math.cos(arg0 * (k.to_double() + 0.5))
      }
    }
    raw[j] = acc
  }
  raw
}

///|
/// 确定性形状向量：1/8 的倍数，有正有负也有零。
fn imdct_shape(n : Int) -> Array[Double] {
  let x = Array::make(n, 0.0)
  for j in 0..<n {
    x[j] = ((j * 7 + 3) % 19).to_double() / 8.0 - 1.0
  }
  x
}

///|
/// 取预旋转 + DFT + 后旋转（不镜像），返回缓冲 raw 段。
fn imdct_raw_segment(x : Array[Double], shift : Int) -> Array[Double] {
  let m = x.length()
  let z = imdct_pre_rotate(x, shift)
  let n4 = imdct_len(shift) >> 2
  let zf = imdct_dft(z, n4)
  let buf = Array::make(m + CEL_OVERLAP, 0.0)
  imdct_post_rotate(buf, 0, zf, shift)
  let raw = Array::make(m, 0.0)
  for j in 0..<m {
    raw[j] = buf[(CEL_OVERLAP >> 1) + j]
  }
  raw
}

///|
test "IMDCT：raw 段逐点等于 RFC 余弦和（各 shift）" {
  for shift in 0..<4 {
    let m = imdct_len(shift) >> 1
    let x = imdct_shape(m)
    let got = imdct_raw_segment(x, shift)
    let want = imdct_raw_direct(x)
    for j in 0..<m {
      let w = want[j]
      let d = if got[j] > w { got[j] - w } else { w - got[j] }
      // 容差 1e-9：两条路径都是 f64，但求和次序不同，M=960 的相消和
      // 会累积到 ~1e-11 量级（Python 端交叉对拍同量级）；结构性错误
      // 的偏差在 1e-3 以上，不会被放过。
      if d > 0.000000001 * (1.0 + (if w < 0.0 { -w } else { w })) {
        @test.fail(
          "shift=\{shift} 下标 \{j}：\{got[j]} != \{w}（差 \{d}）",
        )
      }
    }
  }
}

///|
test "IMDCT：DFT 帕塞瓦尔恒等（未缩放）" {
  for shift in 0..<4 {
    let n4 = imdct_len(shift) >> 2
    let x = imdct_shape(n4 << 1)
    let z = imdct_pre_rotate(x, shift)
    let zf = imdct_dft(z, n4)
    let mut e_in = 0.0
    let mut e_out = 0.0
    for j in 0..<n4 {
      e_in = e_in + z[2 * j] * z[2 * j] + z[2 * j + 1] * z[2 * j + 1]
      e_out = e_out + zf[2 * j] * zf[2 * j] + zf[2 * j + 1] * zf[2 * j + 1]
    }
    let want = e_in * n4.to_double()
    let d = if e_out > want { e_out - want } else { want - e_out }
    if d > 0.000000000001 * want {
      @test.fail("shift=\{shift}：\{e_out} != \{want}")
    }
  }
}

///|
test "IMDCT：DFT δ 探针是纯平面波（符号与归一化）" {
  let n4 = 60
  for k in [0, 5, 31, 59] {
    let z = Array::make(n4 << 1, 0.0)
    z[2 * k] = 1.0
    let zf = imdct_dft(z, n4)
    let a = 6.283185307179586 * k.to_double() / n4.to_double()
    for j in 0..<n4 {
      let ph = a * j.to_double()
      let want_r = @math.cos(ph)
      let want_i = 0.0 - @math.sin(ph)
      if (zf[2 * j] - want_r).abs() > 0.000000000001 ||
        (zf[2 * j + 1] - want_i).abs() > 0.000000000001 {
        @test.fail("k=\{k} 下标 \{j}：(\{zf[2 * j]}, \{zf[2 * j + 1]})")
      }
    }
  }
}

///|
test "IMDCT：镜像逐对能量守恒（窗互补）" {
  let ov = CEL_OVERLAP
  let win = Array::make(ov, 0.0)
  for i in 0..<ov {
    win[i] = celt_window(i, ov)
  }
  // 窗互补本身：w[i]² + w[L-1-i]² = 1（约到 1e-15）
  for i in 0..<(ov >> 1) {
    let s = win[i] * win[i] + win[ov - 1 - i] * win[ov - 1 - i]
    if (s - 1.0).abs() > 0.000000000001 {
      @test.fail("窗互补下标 \{i}：\{s} != 1")
    }
  }
  let buf = Array::make(ov + 8, 0.0)
  for i in 0..<(ov + 8) {
    buf[i] = ((i * 5 + 1) % 17).to_double() / 4.0 - 2.0
  }
  let before = Array::make(ov >> 1, 0.0)
  for i in 0..<(ov >> 1) {
    before[i] = buf[i] * buf[i] + buf[ov - 1 - i] * buf[ov - 1 - i]
  }
  imdct_mirror(buf, 0, win)
  for i in 0..<(ov >> 1) {
    let e = buf[i] * buf[i] + buf[ov - 1 - i] * buf[ov - 1 - i]
    if (e - before[i]).abs() > 0.000000000001 * (1.0 + before[i].abs()) {
      @test.fail("镜像能量下标 \{i}：\{e} != \{before[i]}")
    }
  }
}

///|
test "IMDCT：pending 全 0 时合成管线线性" {
  let lm = 2
  let n = CEL_SHORT_MDCT << lm
  let x0 = imdct_shape(n)
  let x1 = Array::make(n, 0.0)
  for j in 0..<n {
    x1[j] = ((j * 3 + 11) % 13).to_double() / 16.0
  }
  let a = 2.5
  let b = -0.75
  let mixed = Array::make(n, 0.0)
  for j in 0..<n {
    mixed[j] = a * x0[j] + b * x1[j]
  }
  let zpend = Array::make(CEL_OVERLAP >> 1, 0.0)
  let (out_a, pa) = celt_imdct_frame(x0, lm, false, zpend)
  let (out_b, pb) = celt_imdct_frame(x1, lm, false, zpend)
  let (out_m, pm) = celt_imdct_frame(mixed, lm, false, zpend)
  for j in 0..<n {
    let want = a * out_a[j] + b * out_b[j]
    if (out_m[j] - want).abs() > 0.000000000001 * (1.0 + want.abs()) {
      @test.fail("输出线性下标 \{j}：\{out_m[j]} != \{want}")
    }
  }
  for j in 0..<(CEL_OVERLAP >> 1) {
    let want = a * pa[j] + b * pb[j]
    if (pm[j] - want).abs() > 0.000000000001 * (1.0 + want.abs()) {
      @test.fail("pending 线性下标 \{j}：\{pm[j]} != \{want}")
    }
  }
}

///|
test "IMDCT：零谱 -> 全零输出与零 pending（精确）" {
  for lm in 0..<4 {
    let n = CEL_SHORT_MDCT << lm
    let x = Array::make(n, 0.0)
    let zpend = Array::make(CEL_OVERLAP >> 1, 0.0)
    let (out, pend) = celt_imdct_frame(x, lm, false, zpend)
    for j in 0..<n {
      if out[j] != 0.0 {
        @test.fail("lm=\{lm} 输出下标 \{j} 非 0")
      }
    }
    for j in 0..<(CEL_OVERLAP >> 1) {
      if pend[j] != 0.0 {
        @test.fail("lm=\{lm} pending 下标 \{j} 非 0")
      }
    }
  }
}

///|
test "IMDCT：零谱第二帧的帧首只由上一帧尾巴加窗" {
  let lm = 2
  let n = CEL_SHORT_MDCT << lm
  let ov = CEL_OVERLAP
  let x0 = imdct_shape(n)
  let pend0 = Array::make(ov >> 1, 0.0)
  let (_, pend) = celt_imdct_frame(x0, lm, false, pend0)
  let zero = Array::make(n, 0.0)
  let (out, newp) = celt_imdct_frame(zero, lm, false, pend)
  // [0, ov/2)：out[i] = pend[i]·w[L-1-i]（raw 头为 0）
  // [ov/2, ov)：out[L-1-i] = pend[i]·w[i]
  // [ov, N)：raw 全 0
  for i in 0..<(ov >> 1) {
    let w_hi = celt_window(ov - 1 - i, ov)
    let w_lo = celt_window(i, ov)
    let want0 = pend[i] * w_hi
    let want1 = pend[i] * w_lo
    if (out[i] - want0).abs() > 0.000000000001 * (1.0 + want0.abs()) {
      @test.fail("帧首下标 \{i}：\{out[i]} != \{want0}")
    }
    let d1 = (out[ov - 1 - i] - want1).abs()
    if d1 > 0.000000000001 * (1.0 + want1.abs()) {
      @test.fail("帧首下标 \{ov - 1 - i}：\{out[ov - 1 - i]} != \{want1}")
    }
  }
  for j in ov..<n {
    if out[j] != 0.0 {
      @test.fail("零谱帧下标 \{j} 非 0")
    }
  }
  for j in 0..<(ov >> 1) {
    if newp[j] != 0.0 {
      @test.fail("零谱帧 pending 下标 \{j} 非 0")
    }
  }
}
