// celt_tf_change_wbtest.mbt
//
// TF 变换（§4.3.4.5）的白盒测试。
//
// 这里的主测试不依赖参考端，靠的是规范自身与实现结构的性质：
//   1. interleave / deinterleave 是互逆的**纯置换**——精确相等，无容差；
//   2. 前向链与反向链必须互逆——两条链取自参考实现中相隔很远的两段代码
//      （量化前与量化后），互逆成立才说明我对那两段的次序读对了；
//   3. 变换是正交的，能量不因 TF 选择而改变。
// 容差只有 Haar 归一常数那一处来源：参考实现用 0.70710678 而非精确的
// 1/sqrt(2)，一次往返的合成增益 ≈ 1 − 3.36e-9，三级约 1 − 1.01e-8。
// 金标（独立 Python 端，矩阵连乘路径）另在 tf_change_goldens_wbtest.mbt。

///|
/// 结构参数网格：b 取 1/2/4/8（长块与 M=2^LM 的瞬态帧），n 取对应的
/// 常见带宽（Table 55 里出现过的 1/2/3/4/8/12/24）。
fn tfc_grid() -> Array[(Int, Int)] {
  [
    (1, 1),
    (2, 1),
    (3, 1),
    (4, 1),
    (8, 1),
    (12, 1),
    (24, 1),
    (2, 2),
    (4, 2),
    (6, 2),
    (8, 2),
    (16, 2),
    (24, 2),
    (4, 4),
    (8, 4),
    (12, 4),
    (16, 4),
    (32, 4),
    (48, 4),
    (8, 8),
    (16, 8),
    (24, 8),
    (32, 8),
    (64, 8),
    (96, 8),
  ]
}

///|
/// §4.3.1 解出的 TF 调整取值范围（Table 60-63 的最大正值与最小负值）。
fn tfc_changes() -> Array[Int] {
  [-3, -2, -1, 0, 1, 2, 3]
}

///|
/// 确定性测试向量：取值分散且有正有负，恒等/全零向量掩盖不了错误。
fn tfc_input(n : Int) -> Array[Double] {
  let x = Array::make(n, 0.0)
  for i in 0..<n {
    x[i] = ((i * 37 + 11) % 23).to_double() / 11.0 - 1.0
  }
  x
}

///|
/// 逐项精确比对（纯置换类断言用，不设容差）。
fn expect_tfc_exact(
  got : Array[Double],
  want : Array[Double],
  tag : String,
) -> Unit raise {
  if got.length() != want.length() {
    @test.fail("\{tag}: 长度 \{got.length()} != \{want.length()}")
  }
  for i in 0..<want.length() {
    if got[i] != want[i] {
      @test.fail("\{tag}: 下标 \{i} 处 \{got[i]} != \{want[i]}")
    }
  }
}

///|
/// 逐项容差比对。`ulp` 是相对量级，按被比值的幅度缩放。
fn expect_tfc_close(
  got : Array[Double],
  want : Array[Double],
  tag : String,
  ulp : Double,
) -> Unit raise {
  if got.length() != want.length() {
    @test.fail("\{tag}: 长度 \{got.length()} != \{want.length()}")
  }
  for i in 0..<want.length() {
    let w = want[i]
    let d = if got[i] > w { got[i] - w } else { w - got[i] }
    let mag = if w < 0.0 { -w } else { w }
    if d > ulp * (1.0 + mag) {
      @test.fail("\{tag}: 下标 \{i} 处 \{got[i]} != \{w}（差 \{d}）")
    }
  }
}

///|
/// seqency 排列表的分组必须恰好拼满整表，且每组是 0..s-1 的排列——这正是
/// 参考实现 `ordery_table+stride-2` 的取表方式，切偏一组就对不上。
test "seqency 排列表按 stride 分组是排列" {
  if cel_orderery.length() != 30 {
    @test.fail("长度 \{cel_orderery.length()} != 30")
  }
  for s in [2, 4, 8, 16] {
    let seen = Array::make(16, false)
    for i in 0..<s {
      let v = cel_orderery[s - 2 + i]
      if v < 0 || v >= s {
        @test.fail("stride \{s} 的第 \{i} 项越界：\{v}")
      }
      if seen[v] {
        @test.fail("stride \{s} 里 \{v} 重复")
      }
      seen[v] = true
    }
  }
}

///|
/// deinterleave 与 interleave 互逆——两者都是纯置换，所以必须**精确**相等。
/// hadamard 两支都扫：关掉时走恒等索引，打开时走 seqency 序。
test "deinterleave/interleave 互逆（精确）" {
  for n0 in [1, 2, 4, 7, 13] {
    for stride in [1, 2, 4, 8, 16] {
      for hadamard in [false, true] {
        if hadamard && stride < 2 {
          continue
        }
        let a = tfc_input(n0 * stride)
        let b = Array::make(n0 * stride, 0.0)
        for k in 0..<(n0 * stride) {
          b[k] = a[k]
        }
        celt_deinterleave(a, n0, stride, hadamard)
        celt_interleave(a, n0, stride, hadamard)
        expect_tfc_exact(
          a,
          b,
          "roundtrip n0=\{n0} stride=\{stride} hadamard=\{hadamard}",
        )
        // 反方向同样互逆
        let c = tfc_input(n0 * stride)
        let d = Array::make(n0 * stride, 0.0)
        for k in 0..<(n0 * stride) {
          d[k] = c[k]
        }
        celt_interleave(c, n0, stride, hadamard)
        celt_deinterleave(c, n0, stride, hadamard)
        expect_tfc_exact(
          c,
          d,
          "roundtrip(inv) n0=\{n0} stride=\{stride} hadamard=\{hadamard}",
        )
      }
    }
  }
}

///|
/// 两支重排确实不同：否则 seqency 序那条路等于没走，切错也看不出来。
test "seqency 序与恒等序给出不同结果" {
  let n0 = 4
  let stride = 4
  let a = tfc_input(n0 * stride)
  let b = Array::make(n0 * stride, 0.0)
  for k in 0..<(n0 * stride) {
    b[k] = a[k]
  }
  celt_deinterleave(a, n0, stride, false)
  celt_deinterleave(b, n0, stride, true)
  let mut same = true
  for k in 0..<(n0 * stride) {
    if a[k] != b[k] {
      same = false
    }
  }
  if same {
    @test.fail("hadamard 开关没有产生差异")
  }
}

///|
/// haar1 是对合。参考实现的归一常数是 1/sqrt(2) 的近似，两次合成的增益是
/// 2*0.70710678² ≈ 1 − 3.36e-9，所以是容差而不是精确。
test "haar1 两次还原" {
  for n0 in [2, 4, 8, 16] {
    for stride in [1, 2, 4, 8] {
      let a = tfc_input(n0 * stride)
      let want = Array::make(n0 * stride, 0.0)
      for k in 0..<(n0 * stride) {
        want[k] = a[k]
      }
      celt_haar1(a, n0, stride)
      celt_haar1(a, n0, stride)
      expect_tfc_close(a, want, "haar1² n0=\{n0} stride=\{stride}", 0.000001)
    }
  }
}

///|
/// 既不做频率重组合、也不做时间对折时（tf_change=0 且 b=1），整条链一个
/// 步骤都不该执行——严格精确相等。
test "tf_change=0 且长块帧是精确恒等" {
  let a = tfc_input(96)
  let want = Array::make(96, 0.0)
  for k in 0..<96 {
    want[k] = a[k]
  }
  celt_tf_forward(a, 96, 1, 0)
  expect_tfc_exact(a, want, "forward(tf=0,b=1)")
  celt_tf_inverse(a, 96, 1, 0)
  expect_tfc_exact(a, want, "inverse(tf=0,b=1)")
}

///|
/// 奇数带宽在时间分辨率上调时无法再对折，循环一次都不进——与实现里
/// `while (N_B & 1) == 0` 的门一致。
test "奇数带宽不进时间对折循环" {
  let lay = celt_tf_layout(3, 1, -2)
  if lay.time_divide != 0 {
    @test.fail("n=3 b=1 tf=-2 的 time_divide = \{lay.time_divide} != 0")
  }
  if lay.deint_stride != 0 {
    @test.fail("应跳过重排，却得到 stride \{lay.deint_stride}")
  }
}

///|
/// 提高时间分辨率（长块帧）时，重排必须走 seqency 序那一支——即参考实现
/// 的 hadamard 开关为真、步长是 2 的幂且 ≥2。这正是 §4.3.4.5 说的
/// 「the decoder uses the sequency order」。
test "长块帧提高时间分辨率时走 seqency 序" {
  let lay = celt_tf_layout(24, 1, -2)
  if !lay.long_blocks {
    @test.fail("b=1 应判为长块帧")
  }
  if lay.time_divide != 2 {
    @test.fail("n=24 tf=-2 的 time_divide = \{lay.time_divide} != 2")
  }
  if lay.deint_stride != 4 {
    @test.fail("重排步长 \{lay.deint_stride} != 4")
  }
}

///|
/// 核心不变量：前向链之后跟反向链必须回到原向量。两条链分别实现自参考
/// 量化前与量化后两段代码，互逆成立才说明次序与参数都对上了。
test "前向链与反向链互逆" {
  let grid = tfc_grid()
  let changes = tfc_changes()
  for ci in 0..<changes.length() {
    for gi in 0..<grid.length() {
      let (n, b) = grid[gi]
      let tc = changes[ci]
      let x = tfc_input(n)
      let want = tfc_input(n)
      celt_tf_forward(x, n, b, tc)
      celt_tf_inverse(x, n, b, tc)
      expect_tfc_close(x, want, "fwd∘inv n=\{n} b=\{b} tf=\{tc}", 0.000001)
      let y = tfc_input(n)
      celt_tf_inverse(y, n, b, tc)
      celt_tf_forward(y, n, b, tc)
      expect_tfc_close(y, want, "inv∘fwd n=\{n} b=\{b} tf=\{tc}", 0.000001)
    }
  }
}

///|
/// TF 选择只改相位布局、不改能量：Haar 是正交的，重排是置换，两者都保持
/// L2 范数（容差同样只来自归一常数）。
test "正反链各自保持能量" {
  let grid = tfc_grid()
  let changes = tfc_changes()
  for ci in 0..<changes.length() {
    for gi in 0..<grid.length() {
      let (n, b) = grid[gi]
      let tc = changes[ci]
      let mut want = 0.0
      let x = tfc_input(n)
      for k in 0..<n {
        want += x[k] * x[k]
      }
      celt_tf_forward(x, n, b, tc)
      let mut got = 0.0
      for k in 0..<n {
        got += x[k] * x[k]
      }
      if got > want * (1.0 + 0.000001) || got < want * (1.0 - 0.000001) {
        @test.fail("forward n=\{n} b=\{b} tf=\{tc}: 能量 \{got} != \{want}")
      }
      let y = tfc_input(n)
      celt_tf_inverse(y, n, b, tc)
      let mut got2 = 0.0
      for k in 0..<n {
        got2 += y[k] * y[k]
      }
      if got2 > want * (1.0 + 0.000001) || got2 < want * (1.0 - 0.000001) {
        @test.fail("inverse n=\{n} b=\{b} tf=\{tc}: 能量 \{got2} != \{want}")
      }
    }
  }
}
