// celt_exp_rotation_wbtest.mbt
//
// 展宽旋转（§4.3.4.3）的白盒测试。主测试不依赖参考端，靠变换自身的性质：
//   1. 正交性——每一步都是平面旋转，L2 范数必须原样保持；
//   2. 两个早退条件（spread=0、2k≥n）输出精确不变；
//   3. 时间块彼此独立——动后半块不应影响前半块的输出；
//   4. 非平凡性——通用输入确实被改动，且每项都保持有限（NaN/inf 会被
//      `v * 0.0 != 0.0` 拦住）；
//   5. f_r 档位真的进入计算——同一向量 spread=1 与 spread=3 的输出不同。
//
// 金标（独立 Python 端：residue 链分解 + 参考宏结构的 c/s）另在
// exp_rotation_goldens_wbtest.mbt。

///|
/// 相对容差比对，供金标文件共用。
fn expect_rot_close(
  got : Array[Double],
  want : Array[Double],
  tag : String,
  tol : Double,
) -> Unit raise {
  if got.length() != want.length() {
    @test.fail("\{tag}: 长度 \{got.length()} != \{want.length()}")
  }
  for i in 0..<want.length() {
    let w = want[i]
    let d = if got[i] > w { got[i] - w } else { w - got[i] }
    let mag = if w < 0.0 { -w } else { w }
    if d > tol * (1.0 + mag) {
      @test.fail("\{tag}: 下标 \{i} 处 \{got[i]} != \{w}（差 \{d}）")
    }
  }
}

///|
/// 确定性非对称向量：锯齿模数序列，映到约 [−1, 1]。刻意不用对称形状，
/// 免得「回扫整段丢掉」这类方向性错误碰巧对不上。
fn ro_shape(n : Int) -> Array[Double] {
  let x = Array::make(n, 0.0)
  for j in 0..<n {
    x[j] = ((j * 1103 + 12345) % 99991).to_double() / 49996.0 - 1.0
  }
  x
}

///|
/// Σx²。
fn ro_norm2(x : Array[Double]) -> Double {
  let mut e = 0.0
  for v in x {
    e = e + v * v
  }
  e
}

///|
/// 有限值判定：NaN 与 ±∞ 乘 0 都是 NaN，`NaN == 0.0` 为 false。
fn ro_finite(v : Double) -> Bool {
  v * 0.0 == 0.0
}

///|
test "展宽旋转：正交变换保持 L2 范数" {
  let cfgs : Array[(Int, Int, Int)] = [
    (6, 1, 1),
    (16, 1, 1),
    (24, 4, 1),
    (48, 2, 2),
    (64, 2, 3),
  ]
  for i in 0..<cfgs.length() {
    let (n, b, k) = cfgs[i]
    for spread in [1, 2, 3] {
      let x = ro_shape(n)
      let e0 = ro_norm2(x)
      celt_exp_rotation(x, b, k, spread)
      let e1 = ro_norm2(x)
      let d = if e1 > e0 { e1 - e0 } else { e0 - e1 }
      if d > 0.000000000001 * (1.0 + e0) {
        @test.fail(
          "n=\{n} b=\{b} k=\{k} spread=\{spread}：能量 \{e0} -> \{e1}",
        )
      }
    }
  }
}

///|
test "展宽旋转：spread=0 与 2k≥n 时输出精确不变" {
  // spread=0：RFC Table 59 的「不旋转」，任意 k 都早退
  for spread in [0] {
    let x = ro_shape(16)
    let want = ro_shape(16)
    celt_exp_rotation(x, 1, 3, spread)
    for j in 0..<16 {
      if x[j] != want[j] {
        @test.fail("spread=0 下标 \{j}：\{x[j]} != \{want[j]}")
      }
    }
  }
  // 2k≥n：参考实现的早退，k 恰好卡在 2k=n 与越过两档都要走到
  let pairs : Array[(Int, Int)] = [(8, 4), (8, 5), (9, 5), (2, 1)]
  for i in 0..<pairs.length() {
    let (n, k) = pairs[i]
    let x = ro_shape(n)
    let want = ro_shape(n)
    celt_exp_rotation(x, 1, k, 3)
    for j in 0..<n {
      if x[j] != want[j] {
        @test.fail(
          "2k≥n（n=\{n} k=\{k}）下标 \{j}：\{x[j]} != \{want[j]}",
        )
      }
    }
  }
}

///|
test "展宽旋转：时间块之间互不影响" {
  let a = ro_shape(32)
  let b = ro_shape(32)
  // 只改后半块；前半块的输出若不变，说明块循环确实按 base 切段
  for j in 16..<32 {
    b[j] = 123.4 - b[j]
  }
  celt_exp_rotation(a, 2, 2, 2)
  celt_exp_rotation(b, 2, 2, 2)
  for j in 0..<16 {
    if a[j] != b[j] {
      @test.fail(
        "前半块输出受后半块输入影响：下标 \{j} 处 \{a[j]} != \{b[j]}",
      )
    }
  }
}

///|
test "展宽旋转：通用输入确实被改动，且结果保持有限" {
  let cfgs : Array[(Int, Int, Int)] = [(16, 1, 1), (24, 4, 1), (8, 1, 1)]
  for i in 0..<cfgs.length() {
    let (n, b, k) = cfgs[i]
    for spread in [1, 2, 3] {
      let x = ro_shape(n)
      let orig = ro_shape(n)
      celt_exp_rotation(x, b, k, spread)
      let mut changed = 0
      for j in 0..<n {
        if !ro_finite(x[j]) {
          @test.fail("n=\{n} spread=\{spread} 下标 \{j} 非有限：\{x[j]}")
        }
        if x[j] != orig[j] {
          changed = changed + 1
        }
      }
      if changed == 0 {
        @test.fail(
          "n=\{n} b=\{b} spread=\{spread}：旋转没有改动任何一项",
        )
      }
    }
  }
}

///|
test "展宽旋转：f_r 档位进入计算，spread=1 与 3 结果不同" {
  let a = ro_shape(16)
  let orig = ro_shape(16)
  let c3 = ro_shape(16)
  celt_exp_rotation(a, 1, 1, 1)
  celt_exp_rotation(c3, 1, 1, 3)
  let mut diff = 0
  let mut changed = 0
  for j in 0..<16 {
    if a[j] != c3[j] {
      diff = diff + 1
    }
    if a[j] != orig[j] {
      changed = changed + 1
    }
  }
  if changed == 0 {
    @test.fail("spread=1 没有转动，档位测试是平凡的")
  }
  if diff == 0 {
    @test.fail(
      "spread=1 与 spread=3 输出完全相同，f_r 档位没起作用",
    )
  }
}
