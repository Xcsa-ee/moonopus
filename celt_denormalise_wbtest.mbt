// celt_denormalise_wbtest.mbt
//
// 反归一化（§4.3.6）的白盒测试。
//
// 主测试不依赖参考端，靠规范与实现结构自身的性质：
//   1. band_log_e 取 k − eMeans（k 整数）时带增益恰为 2^k。所有参与量都是
//      1/16 的倍数，lg 相加回到精确的整数 k；2^k 是二的幂，整条乘法无舍入
//      ——所以这条断言可以**精确相等**、不设容差，任何一处量纲或下标错位
//      都会露出成倍的偏差；
//   2. 带能量按 4^k 缩放，其中 4^k 用连乘算出，不经过被测的 @math.pow；
//   3. 置零区域：start 之前、end 之后、max_bin 之后、静音帧；
//   4. [start,end) 之外的 band_log_e 完全不参与；
//   5. band_log_e 每 +1，该带输出恰好翻倍（log 域的能量单调性）。
//
// 金标（独立 Python 端：逐 bin 增益表 + math.exp2 + Q4 版 eMeans）另在
// denorm_goldens_wbtest.mbt。

///|
/// 相对容差比对，供金标文件共用。
fn expect_dn_close(
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
/// 2^k 的连乘实现（k 为整数，逐次乘/除 2，全部精确）。
///
/// 与被测代码的 @math.pow 是两条不同的实现，能量断言经它计算才不会和被测
/// 路径共用同一个指数函数。
fn dn_pow2i(k : Int) -> Double {
  let mut r = 1.0
  if k < 0 {
    let mut i = 0
    while i < -k {
      r = r * 0.5
      i = i + 1
    }
    r
  } else {
    let mut i = 0
    while i < k {
      r = r * 2.0
      i = i + 1
    }
    r
  }
}

///|
/// 确定性形状向量：1/8 的倍数，有正有负也有零，取值 ∈ [−1, 1]。
fn dn_shape(n : Int) -> Array[Double] {
  let x = Array::make(n, 0.0)
  for j in 0..<n {
    x[j] = ((j * 13 + 5) % 17).to_double() / 8.0 - 1.0
  }
  x
}

///|
/// 由「带 i 的目标 lg = k[i]」反推 band_log_e[i] = k[i] − eMeans[i]。
fn dn_loge_of_k(k : Array[Int]) -> Array[Double] {
  let loge = Array::make(CEL_NB_EBANDS, 0.0)
  for i in 0..<CEL_NB_EBANDS {
    loge[i] = k[i].to_double() - cel_e_means[i]
  }
  loge
}

///|
/// 每个 bin 所属的带；max_bin 之后为 −1，不参与编码。
fn dn_band_of(m : Int) -> Array[Int] {
  let b = Array::make(m * CEL_SHORT_MDCT, -1)
  for i in 0..<CEL_NB_EBANDS {
    for j in celt_eband(i, m)..<celt_eband(i + 1, m) {
      b[j] = i
    }
  }
  b
}

///|
/// 造一组逐带互不相同的 k（严格递增），相邻带增益必然差 2 倍，带界错一位
/// 就对不上。
fn dn_strict_k() -> Array[Int] {
  let k = Array::make(CEL_NB_EBANDS, 0)
  for i in 0..<CEL_NB_EBANDS {
    k[i] = i - 10
  }
  k
}

///|
test "反归一化：lg 取整数 k 时增益恰为 2^k（精确）" {
  for m in [1, 2, 4, 8] {
    let n = m * CEL_SHORT_MDCT
    let x = dn_shape(n)
    let k = dn_strict_k()
    let freq = celt_denormalise(x, dn_loge_of_k(k), 0, CEL_NB_EBANDS, m, false)
    let band = dn_band_of(m)
    for j in 0..<n {
      let i = band[j]
      let want = if i < 0 { 0.0 } else { x[j] * dn_pow2i(k[i]) }
      if freq[j] != want {
        @test.fail("m=\{m} 下标 \{j}（带 \{i}）：\{freq[j]} != \{want}")
      }
    }
  }
}

///|
test "反归一化：带能量按 4^k 缩放（不经 @math.pow）" {
  let m = 4
  let n = m * CEL_SHORT_MDCT
  let x = dn_shape(n)
  let k = Array::make(CEL_NB_EBANDS, 0)
  for i in 0..<CEL_NB_EBANDS {
    k[i] = i % 5 - 2
  }
  let freq = celt_denormalise(x, dn_loge_of_k(k), 0, CEL_NB_EBANDS, m, false)
  for i in 0..<CEL_NB_EBANDS {
    let mut e_in = 0.0
    let mut e_out = 0.0
    for j in celt_eband(i, m)..<celt_eband(i + 1, m) {
      e_in = e_in + x[j] * x[j]
      e_out = e_out + freq[j] * freq[j]
    }
    // 期望能量 = 输入带能量 × 4^k；4^k 由连乘得到，与实现的指数函数无关
    let want = e_in * dn_pow2i(2 * k[i])
    let d = if e_out > want { e_out - want } else { want - e_out }
    if d > 0.000000000001 * (1.0 + want) {
      @test.fail("带 \{i}：能量 \{e_out} != \{want}（k=\{k[i]}）")
    }
  }
}

///|
test "反归一化：start 之前、end 之后、max_bin 之后全为 0" {
  let m = 4
  let n = m * CEL_SHORT_MDCT
  let x = dn_shape(n)
  let k = Array::make(CEL_NB_EBANDS, 0)
  for i in 0..<CEL_NB_EBANDS {
    k[i] = i % 7
  }
  let loge = dn_loge_of_k(k)
  let start = 3
  let end = 17
  let freq = celt_denormalise(x, loge, start, end, m, false)
  if freq.length() != n {
    @test.fail("长度 \{freq.length()} != \{n}")
  }
  for j in 0..<celt_eband(start, m) {
    if freq[j] != 0.0 {
      @test.fail("start 之前非 0：下标 \{j} 处 \{freq[j]}")
    }
  }
  for j in celt_eband(end, m)..<n {
    if freq[j] != 0.0 {
      @test.fail("end 之后非 0：下标 \{j} 处 \{freq[j]}")
    }
  }
  // 活跃区间必须真的写进去了，否则上面两条只是因为整条全 0 而通过
  let mut active = 0
  for j in celt_eband(start, m)..<celt_eband(end, m) {
    if freq[j] != 0.0 {
      active = active + 1
    }
  }
  if active == 0 {
    @test.fail("活跃区间全为 0，本测试是平凡的")
  }
  // end 取到 21 时，尾段 20–24 kHz 依旧不参与编码
  let full = celt_denormalise(x, loge, 0, CEL_NB_EBANDS, m, false)
  for j in celt_max_bin(m)..<n {
    if full[j] != 0.0 {
      @test.fail("max_bin 之后非 0：下标 \{j} 处 \{full[j]}")
    }
  }
}

///|
test "反归一化：静音帧输出全为 0，与形状和能量无关" {
  let m = 4
  let n = m * CEL_SHORT_MDCT
  // 形状取非零常量、能量取偏大的 k，两者都掩盖不了漏掉静音分支的错误
  let x = Array::make(n, 3.5)
  let k = Array::make(CEL_NB_EBANDS, 6)
  let freq = celt_denormalise(x, dn_loge_of_k(k), 0, CEL_NB_EBANDS, m, true)
  if freq.length() != n {
    @test.fail("长度 \{freq.length()} != \{n}")
  }
  for j in 0..<n {
    if freq[j] != 0.0 {
      @test.fail("静音帧下标 \{j} 处 \{freq[j]} 非 0")
    }
  }
}

///|
test "反归一化：lg 超过 32 时增益截到 2^32" {
  let m = 4
  let n = m * CEL_SHORT_MDCT
  let x = dn_shape(n)
  let k = Array::make(CEL_NB_EBANDS, 40)
  let freq = celt_denormalise(x, dn_loge_of_k(k), 0, CEL_NB_EBANDS, m, false)
  let cap = dn_pow2i(32)
  for j in 0..<n {
    let want = if j < celt_max_bin(m) { x[j] * cap } else { 0.0 }
    if freq[j] != want {
      @test.fail(
        "下标 \{j}：\{freq[j]} != \{want}（应为截断后的 2^32）",
      )
    }
  }
}

///|
test "反归一化：[start,end) 之外的 band_log_e 不参与" {
  let m = 4
  let n = m * CEL_SHORT_MDCT
  let x = dn_shape(n)
  let k = Array::make(CEL_NB_EBANDS, 0)
  for i in 0..<CEL_NB_EBANDS {
    k[i] = i % 5 - 2
  }
  let loge = dn_loge_of_k(k)
  let start = 2
  let end = 15
  let base = celt_denormalise(x, loge, start, end, m, false)
  // 窗外换成一个会触发上界截断的值；实现若多读了这些带，输出必然变大
  for i in 0..<CEL_NB_EBANDS {
    if i < start || i >= end {
      loge[i] = 123.4 - cel_e_means[i]
    }
  }
  let again = celt_denormalise(x, loge, start, end, m, false)
  for j in 0..<n {
    if again[j] != base[j] {
      @test.fail(
        "下标 \{j} 受窗外能量影响：\{base[j]} -> \{again[j]}",
      )
    }
  }
}

///|
test "反归一化：band_log_e 每 +1，该带输出恰好翻倍" {
  let m = 4
  let n = m * CEL_SHORT_MDCT
  let x = dn_shape(n)
  let k = Array::make(CEL_NB_EBANDS, 0)
  for i in 0..<CEL_NB_EBANDS {
    k[i] = i % 5 - 2
  }
  let a = celt_denormalise(x, dn_loge_of_k(k), 0, CEL_NB_EBANDS, m, false)
  for i in 0..<CEL_NB_EBANDS {
    k[i] = k[i] + 1
  }
  let b = celt_denormalise(x, dn_loge_of_k(k), 0, CEL_NB_EBANDS, m, false)
  let band = dn_band_of(m)
  for j in 0..<n {
    let i = band[j]
    let want = if i < 0 { 0.0 } else { a[j] * 2.0 }
    if b[j] != want {
      @test.fail("下标 \{j}（带 \{i}）：\{b[j]} != \{want}")
    }
  }
}
