// celt_postfilter_wbtest.mbt
//
// 后滤波（§4.3.7.1）的白盒测试。
//
// 主测试不依赖参考端，靠规范与实现结构自身的性质：
//   1. 增益全零恒等：任何输入/周期/tapset 下原样返回（精确相等）；
//   2. 周期钳制等价：t < 15 与 t = 15 的输出逐位一致；
//   3. 常数段等于测试内独立重写的直接递推（含逐点回读顺序）；
//   4. 抽头表功率和 g0+2g1+2g2 ≈ 1（DC 响应，表值排版错位即破）；
//   5. 有界性：|x| ≤ 1 且 G ≤ 0.75 时 |y| ≤ 4.1（1/(1-G) 界）。
//
// 金标（独立 Python 端：逐点直读结构）另在 postfilter_goldens_wbtest.mbt。

///|
/// 确定性输入：幅度 ≤ 1 的历史 + 主体。
fn pf_signal(n : Int) -> Array[Double] {
  let x = Array::make(n, 0.0)
  for k in 0..<n {
    let mut v = 0.55 * @math.sin(6.283185307179586 * k.to_double() / 100.0)
    v = v + 0.3 * @math.sin(6.283185307179586 * k.to_double() / 47.0 + 1.1)
    x[k] = v * 0.5
  }
  x
}

///|
/// 预取窗（与合成侧同式）。
fn pf_win() -> Array[Double] {
  let win = Array::make(CEL_OVERLAP, 0.0)
  for i in 0..<CEL_OVERLAP {
    win[i] = celt_window(i, CEL_OVERLAP)
  }
  win
}

///|
test "后滤波：增益全零恒等（精确）" {
  let base = 1024
  let x = pf_signal(base + 960)
  let want = Array::make(base + 960, 0.0)
  for k in 0..<(base + 960) {
    want[k] = x[k]
  }
  // 周期越界、tapset 任意：全零捷径应先于一切处理
  celt_comb_filter(x, base, 0, 1022, 960, 0.0, 0.0, 2, 0, pf_win())
  for k in 0..<(base + 960) {
    if x[k] != want[k] {
      @test.fail("下标 \{k}：\{x[k]} != \{want[k]}")
    }
  }
}

///|
test "后滤波：周期 t<15 与 t=15 输出逐位一致（钳制）" {
  let base = 1024
  let n = 960
  let a = pf_signal(base + n)
  let b = Array::make(base + n, 0.0)
  for k in 0..<(base + n) {
    b[k] = a[k]
  }
  celt_comb_filter(a, base, 3, 7, n, 0.1875, 0.09375, 0, 2, pf_win())
  celt_comb_filter(b, base, 15, 15, n, 0.1875, 0.09375, 0, 2, pf_win())
  for k in base..<(base + n) {
    if a[k] != b[k] {
      @test.fail("下标 \{k}：\{a[k]} != \{b[k]}")
    }
  }
}

///|
test "后滤波：常数段等于测试内独立直接递推" {
  let base = 1024
  let n = 960
  let t = 100
  let g = 0.375
  let ts = 1
  // 被测实现（参数全等 → 跳过过渡段，全程常数段）
  let x = pf_signal(base + n)
  celt_comb_filter(x, base, t, t, n, g, g, ts, ts, pf_win())
  // 独立重写：同序先读后写的直接递推，回读的是已被滤波改写的 y
  let y = pf_signal(base + n)
  let g00 = g * 0.4638671875
  let g01 = g * 0.2680664062
  let g02 = g * 0.0
  for i in 0..<n {
    let mut v = y[base + i]
    v = v + g00 * y[base + i - t]
    v = v + g01 * (y[base + i - t + 1] + y[base + i - t - 1])
    v = v + g02 * (y[base + i - t + 2] + y[base + i - t - 2])
    y[base + i] = v
  }
  for k in base..<(base + n) {
    if (x[k] - y[k]).abs() > 0.000000000001 * (1.0 + y[k].abs()) {
      @test.fail("下标 \{k}：\{x[k]} != \{y[k]}")
    }
  }
}

///|
test "后滤波：抽头表 DC 功率和 ≈ 1" {
  for t in 0..<3 {
    let s = cel_tap_gains[3 * t] +
      2.0 * cel_tap_gains[3 * t + 1] +
      2.0 * cel_tap_gains[3 * t + 2]
    if (s - 1.0).abs() > 0.000000001 {
      @test.fail("tapset \{t} 功率和 \{s} != 1")
    }
  }
}

///|
test "后滤波：幅度有界 |y| ≤ 4.1（G ≤ 0.75，|x| ≤ 1）" {
  let base = 1024
  let n = 960
  let x = pf_signal(base + n)
  for k in 0..<(base + n) {
    if x[k] > 1.0 || x[k] < -1.0 {
      @test.fail("输入越界 \{k}：\{x[k]}")
    }
  }
  celt_comb_filter(x, base, 100, 1022, n, 0.75, 0.75, 0, 0, pf_win())
  for k in base..<(base + n) {
    if x[k] > 4.1 || x[k] < -4.1 {
      @test.fail("输出越界 \{k}：\{x[k]}")
    }
  }
}
