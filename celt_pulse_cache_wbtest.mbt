// celt_pulse_cache_wbtest.mbt
//
// 位数↔脉冲换算（§4.3.4.1）的白盒测试。
//
// 金标来自 tools/gen_pulse_cache_goldens.py：Python 端按 rate.c 的
// compute_pulse_cache 从 RFC Table 55 带宽独立重建两张缓存表
// （V(N,K) 闭式计数，非参考实现的 U 表递推），与从 libopus 头文件解析
// 的静态产物逐项对拍通过后才落盘。本文件覆盖：表重建比对、bits2pulses
// 采样与 tie 点、pulses2bits 特征点、get_pulses 全表，以及不依赖金标
// 的结构性质（单调不降、argmin 下界、边界位数）。

///|
/// 展平采样点的下标 → (lm, band)：金标按 lm×band 主序、每带定长步进。
fn pc_cell(i : Int) -> (Int, Int) {
  let cell = i / PC_B2P_STRIDE
  (cell / CEL_NB_EBANDS, cell % CEL_NB_EBANDS)
}

///|
/// 金标里覆盖的 LM 档数（lm = 0..3），由采样总点数反推。
fn pc_lm_count() -> Int {
  pc_b2p_b.length() / PC_B2P_STRIDE / CEL_NB_EBANDS
}

///|
/// 某 (lm, band) 条目的 Kmax（条目首槽）。
fn pc_kmax(band : Int, lm : Int) -> Int {
  cel_cache_bits50[cel_cache_index50[(lm + 1) * CEL_NB_EBANDS + band]].to_int()
}

///|
/// 两张缓存表 == Python 端从 RFC Table 55 的独立重建（逐项比对）。
test "脉冲缓存表与独立重建逐项一致" {
  for i in 0..<pc_index.length() {
    if cel_cache_index50[i] != pc_index[i] {
      @test.fail("index[\{i}] = \{cel_cache_index50[i]} != \{pc_index[i]}")
    }
  }
  for i in 0..<pc_bits.length() {
    let got = cel_cache_bits50[i].to_int()
    if got != pc_bits[i] {
      @test.fail("bits[\{i}] = \{got} != \{pc_bits[i]}")
    }
  }
}

///|
/// get_pulses：0..40 全表与金标一致（金标是公式直出的独立计算）。
test "get_pulses 全表与金标一致" {
  for i in 0..<pc_get_pulses.length() {
    @test.assert_eq(celt_get_pulses(i), pc_get_pulses[i])
  }
}

///|
/// bits2pulses：每个 (lm, band) 固定 21 个采样 b（公共点 + 表特征点
/// + 极端点 16383）全部与金标一致。
test "bits2pulses 采样金标每带 21 点" {
  for i in 0..<pc_b2p_b.length() {
    let (lm, band) = pc_cell(i)
    let got = celt_bits2pulses(band, lm, pc_b2p_b[i])
    if got != pc_b2p_q[i] {
      @test.fail(
        "lm=\{lm} band=\{band} b=\{pc_b2p_b[i]}: \{got} != \{pc_b2p_q[i]}",
      )
    }
  }
}

///|
/// bits2pulses 的 tie-break 平局点：这些 b 上 `<=`/`<` 的选择会翻转
/// 结果，缺了任何一侧变异都会在这里变红。
test "bits2pulses tie-break 平局点金标" {
  for i in 0..<pc_tie_b.length() {
    let got = celt_bits2pulses(pc_tie_band[i], pc_tie_lm[i], pc_tie_b[i])
    if got != pc_tie_q[i] {
      @test.fail(
        "lm=\{pc_tie_lm[i]} band=\{pc_tie_band[i]} b=\{pc_tie_b[i]}: \{got} != \{pc_tie_q[i]}",
      )
    }
  }
}

///|
/// pulses2bits：每 (lm, band) 的 q ∈ {0, 1, 2, Kmax} 特征点与金标一致
/// ——钉死 0 特判、条目偏移与「+1」的存法。
test "pulses2bits 特征点金标" {
  for i in 0..<pc_p2b_q.length() {
    let got = celt_pulses2bits(pc_p2b_band[i], pc_p2b_lm[i], pc_p2b_q[i])
    if got != pc_p2b_p[i] {
      @test.fail(
        "lm=\{pc_p2b_lm[i]} band=\{pc_p2b_band[i]} q=\{pc_p2b_q[i]}: \{got} != \{pc_p2b_p[i]}",
      )
    }
  }
}

///|
/// 不依赖金标的下界性质：二分只是在位数曲线上找最近元的加速，其结果
/// 与「扫全条目取 |位数−b| 最小者」的最小距离必须相等。暴力扫描用的
/// pulses2bits 与二分结果各自有绝对金标钉住，两端不会一起错。
test "bits2pulses 结果达到 argmin 下界" {
  for i in 0..<pc_b2p_b.length() {
    let (lm, band) = pc_cell(i)
    let b = pc_b2p_b[i]
    let kmax = pc_kmax(band, lm)
    let mut dmin = 1 << 30
    for q in 0..<(kmax + 1) {
      let p = celt_pulses2bits(band, lm, q)
      let d = if p >= b { p - b } else { b - p }
      if d < dmin {
        dmin = d
      }
    }
    let got = celt_bits2pulses(band, lm, b)
    let pg = celt_pulses2bits(band, lm, got)
    let dg = if pg >= b { pg - b } else { b - pg }
    if dg != dmin {
      @test.fail("lm=\{lm} band=\{band} b=\{b}: 距离 \{dg} != 最小 \{dmin}")
    }
  }
}

///|
/// pulses2bits 的结构性质：0 恒为 0，且沿条目单调不降——位数曲线是
/// 二分能成立的前提，单调被破坏时二分就会选错端点。
test "pulses2bits 单调不降且零点归零" {
  for lm in 0..<pc_lm_count() {
    for band in 0..<CEL_NB_EBANDS {
      if celt_pulses2bits(band, lm, 0) != 0 {
        @test.fail("lm=\{lm} band=\{band}: p(0) != 0")
      }
      let kmax = pc_kmax(band, lm)
      let mut prev = 0
      for q in 1..<(kmax + 1) {
        let p = celt_pulses2bits(band, lm, q)
        if p < prev {
          @test.fail("lm=\{lm} band=\{band} q=\{q}: \{p} < \{prev}")
        }
        prev = p
      }
    }
  }
}

///|
/// bits2pulses 的边界：0 位必归 0；超大位数（16383 ≫ 表内最大位数）
/// 必收敛到条目 Kmax——二分窗口被整体推到上端。
test "bits2pulses 边界位数钉死" {
  for lm in 0..<pc_lm_count() {
    for band in 0..<CEL_NB_EBANDS {
      let got0 = celt_bits2pulses(band, lm, 0)
      if got0 != 0 {
        @test.fail("lm=\{lm} band=\{band}: b=0 → \{got0} != 0")
      }
      let got1 = celt_bits2pulses(band, lm, 16383)
      let kmax = pc_kmax(band, lm)
      if got1 != kmax {
        @test.fail("lm=\{lm} band=\{band}: b=16383 → \{got1} != \{kmax}")
      }
    }
  }
}
