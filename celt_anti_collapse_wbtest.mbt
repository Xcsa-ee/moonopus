// celt_anti_collapse_wbtest.mbt
//
// 反塌缩（RFC 6716 §4.3.5）的白盒测试。
//
// 金标由 tools/gen_anti_collapse_goldens.py 的独立 Python 参考端算出
// （比对助手 expect_dn_close 复用反归一化那套相对容差），本文件另外
// 提供不依赖金标的锚点与不变量：lcg 常量与序列、归一化的增益语义、
// 预留位公式的边界网格。

///|
/// celt_lcg_rand：C 源里的常量锚点 + 10 步推进序列（金标文件提供）。
test "lcg 常量锚点与 10 步序列" {
  // celt_bands.c：1664525 * seed + 1013904223（uint32 环绕）
  @test.assert_eq(celt_lcg_rand(0L), 1013904223L)
  @test.assert_eq(celt_lcg_rand(1L), 1015568748L)
  // 高位进位必须按 32 位回绕：seed=0xFFFFFFFF 的下一步
  // （Python 端独立算出 (1664525×(2^32−1)+1013904223) mod 2^32）
  @test.assert_eq(celt_lcg_rand(4294967295L), 1012239698L)
  let mut s = 0L
  for i in 0..<ac_lcg_seq.length() {
    s = celt_lcg_rand(s)
    if s != ac_lcg_seq[i] {
      @test.fail("lcg 步 \{i}: \{s} != \{ac_lcg_seq[i]}")
    }
  }
}

///|
/// 归一化的增益语义：单位增益把 Σx² 拉到 1，非单位增益拉到 gain²，
/// 且所有分量同比缩放（方向不变）。
test "renorm 的增益与方向不变量" {
  let x : Array[Double] = [3.0, 4.0]
  celt_renormalise_vector(x, 0, 2, 1.0)
  let want : Array[Double] = [0.6, 0.8]
  for j in 0..<2 {
    let d = if x[j] > want[j] { x[j] - want[j] } else { want[j] - x[j] }
    if d > 0.000000000001 {
      @test.fail("renorm 分量 \{j}: \{x[j]} != \{want[j]}")
    }
  }
  let x2 : Array[Double] = [3.0, 4.0, 0.0]
  celt_renormalise_vector(x2, 0, 3, 2.0)
  let mut e = 0.0
  for j in 0..<3 {
    e += x2[j] * x2[j]
  }
  // gain=2 → Σx² = 4（EPSILON 只是 1e-15 量级的防零除下界）
  let de = if e > 4.0 { e - 4.0 } else { 4.0 - e }
  if de > 0.000000000001 {
    @test.fail("renorm 能量 \{e} != 4")
  }
  // 方向不变：x1/x0 比值保持 4/3
  let ratio = x2[1] / x2[0]
  let dr = if ratio > 1.3333333333333333 {
    ratio - 1.3333333333333333
  } else {
    1.3333333333333333 - ratio
  }
  if dr > 0.000000000001 {
    @test.fail("renorm 方向比 \{ratio} 漂移")
  }
}

///|
/// 预留位公式的边界网格（celt_decoder.c 的 anti_collapse_rsv）：
/// 瞬态、LM≥2、预算 ≥ (LM+2)<<3 三条同时满足才预留 1<<3。
test "反塌缩预留位边界网格" {
  if celt_anti_collapse_rsv(false, 3, 1000) != 0 {
    @test.fail("非瞬态不该预留")
  }
  if celt_anti_collapse_rsv(true, 1, 1000) != 0 {
    @test.fail("LM=1 不该预留")
  }
  if celt_anti_collapse_rsv(true, 2, 31) != 0 {
    @test.fail("预算 31 < 32 不该预留")
  }
  if celt_anti_collapse_rsv(true, 2, 32) != 8 {
    @test.fail("预算 32 = (2+2)<<3 应预留 8")
  }
  if celt_anti_collapse_rsv(true, 3, 39) != 0 {
    @test.fail("预算 39 < 40 不该预留")
  }
  if celt_anti_collapse_rsv(true, 3, 40) != 8 {
    @test.fail("预算 40 = (3+2)<<3 应预留 8")
  }
}
