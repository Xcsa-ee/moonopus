// celt_mode_wbtest.mbt
//
// CELT 模式结构（celt_mode.mbt）的白盒测试。
//
// Table 55 的期望值来自 celt_rfc_goldens_wbtest.mbt——那份数据直接解析自
// RFC 正文，而实现侧的频带布局来自 libopus 的 eband5ms，两条来源独立，
// 对不上就说明其中一侧读错了。

///|
/// RFC Table 55 交叉核对：21 带 × 4 种帧长的 MDCT bin 数必须与实现侧
/// 逐项相等。`cel_rfc_band_bins` 按「带 × 帧长」展开，帧长顺序为
/// 2.5/5/10/20 ms，对应 LM = 0/1/2/3。
test "频带 bin 数与 RFC Table 55 一致" {
  for lm in 0..<4 {
    let m = 1 << lm
    for i in 0..<CEL_NB_EBANDS {
      let got = celt_band_bins(i, m)
      let want = cel_rfc_band_bins[i * 4 + lm]
      if got != want {
        @test.fail("band \{i} LM=\{lm}: \{got} != RFC \{want}")
      }
    }
  }
}

///|
/// 频带边界必须严格递增，且编码覆盖范围始终落在 MDCT 长度之内——
/// 20 ms 帧的 band 20 止于 800 bin < 960，顶端那 160 bin 不参与编码。
test "频带边界递增且不越界" {
  let mut prev = -1
  for i in 0..<(CEL_NB_EBANDS + 1) {
    let e = celt_eband(i, 8)
    if e <= prev {
      @test.fail("eband[\{i}]=\{e} 未大于上一项 \{prev}")
    }
    prev = e
  }
  if celt_max_bin(8) != 800 {
    @test.fail("20ms 的 max_bin \{celt_max_bin(8)} != 800")
  }
  if celt_max_bin(8) >= 120 * 8 {
    @test.fail("max_bin 覆盖了整个 MDCT")
  }
}

///|
/// 帧长 → LM 的映射（Table 55 的帧尺寸列）。
test "帧长到 LM 的映射" {
  @test.assert_eq(celt_lm_of_frame_samples(120), Some(0))
  @test.assert_eq(celt_lm_of_frame_samples(240), Some(1))
  @test.assert_eq(celt_lm_of_frame_samples(480), Some(2))
  @test.assert_eq(celt_lm_of_frame_samples(960), Some(3))
  @test.assert_eq(celt_lm_of_frame_samples(961), None)
}

///|
/// §4.3.3 的 cap 展开。带 0 在 LM=0 时 N=1，于是结果直接暴露所选分组的
/// 原始表值；带 8 在 LM=0 时 N=2，单声道取第 0 组（原始 160）、立体声
/// 取第 1 组（原始 240）。任一处算错（分组下标、N 的 LM 缩放、右移）都
/// 会让这四个期望值对不上。
test "caps 表按 §4.3.3 展开" {
  for lm in 0..<4 {
    for channels in [1, 2] {
      let cap = celt_init_caps(lm, channels)
      if cap.length() != CEL_NB_EBANDS {
        @test.fail("lm=\{lm} ch=\{channels}: 长度 \{cap.length()}")
      }
      for i in 0..<cap.length() {
        // §4.3.3：换算结果「fits in signed 16-bit integers」
        if cap[i] < 0 || cap[i] > 32767 {
          @test.fail(
            "lm=\{lm} ch=\{channels} band \{i}: cap \{cap[i]} 超出 int16",
          )
        }
      }
    }
  }
  @test.assert_eq(celt_init_caps(0, 1)[0], 72)
  @test.assert_eq(celt_init_caps(1, 1)[0], 112)
  @test.assert_eq(celt_init_caps(2, 1)[0], 249)
  @test.assert_eq(celt_init_caps(3, 1)[0], 514)
  @test.assert_eq(celt_init_caps(0, 1)[8], 112)
  @test.assert_eq(celt_init_caps(0, 2)[8], 304)
}

///|
/// 去重 emphasis 的递推：输出是上一帧**输出**的递推，不是输入的差分；
/// 返回值必须等于本帧最后一个状态，供下一帧续用。
test "去重 emphasis 的递推与状态回传" {
  let x = [1.0, 2.0, 3.0]
  let out = Array::make(3, 0.0)
  let m = celt_deemphasis(x, out, 0.5)
  @test.assert_eq(out[0], 1.5) // x[0] + mem，精确可表示
  @test.assert_eq(out[1], 2.0 + CEL_DEEMPH_COEF * out[0])
  @test.assert_eq(out[2], 3.0 + CEL_DEEMPH_COEF * out[1])
  @test.assert_eq(m, CEL_DEEMPH_COEF * out[2])
}

///|
/// 首帧无历史状态时 mem=0，首样本原样通过。
test "去重 emphasis 的零初值" {
  let x = [4.0, 0.0]
  let out = Array::make(2, 0.0)
  let m = celt_deemphasis(x, out, 0.0)
  @test.assert_eq(out[0], 4.0)
  @test.assert_eq(m, CEL_DEEMPH_COEF * out[1])
}

///|
/// sine 窗的功率互补：50% 重叠相加时，前半窗与后半窗（索引翻转）必须
/// 满足 w(i)² + w(N-1-i)² = 1，否则重叠区会整体放大或衰减。
///
/// 这是公式 sin(π/2·sin²(π/2·(i+.5)/N)) 的结构性质：两处自变量之和为
/// π/2，平方后互补，故功率和恰为 1（浮点下留 1e-12 余量）。
test "sine 窗功率互补" {
  let n = 120
  for i in 0..<n {
    let w1 = celt_window(i, n)
    let w2 = celt_window(n - 1 - i, n)
    let s = w1 * w1 + w2 * w2 - 1.0
    if s > 0.000000000001 || s < -0.000000000001 {
      @test.fail("i=\{i}: w1²+w2² = \{w1 * w1 + w2 * w2} != 1")
    }
  }
}

///|
/// 窗的两端：起点几乎为 0、终点几乎为 1，否则重叠相加会在帧边界留痕。
test "sine 窗端点" {
  let n = 120
  if celt_window(0, n) > 0.001 {
    @test.fail("窗起点 \{celt_window(0, n)} 过大")
  }
  if celt_window(n - 1, n) < 0.999 {
    @test.fail("窗终点 \{celt_window(n - 1, n)} 过小")
  }
}
