// celt_frame_header_wbtest.mbt
//
// 帧首四符号（RFC 6716 Table 56 前四项）的白盒测试。
//
// 金标由 tools/gen_frame_header_goldens.py 的独立 Python 参考端算出；载荷
// 常量、重放函数与 test 块都在生成的 frame_header_goldens_wbtest.mbt 里。

///|
/// 逐项比对帧首四符号的解码结果，另带两条来自 §4.3.7.1 的规范断言——
/// 它们不依赖金标，能独立抓出 octave/tapset/gain 解码越界。
fn expect_frame_header(
  got : CeltFrameHeader,
  want_silence : Bool,
  want_postfilter_on : Bool,
  want_pitch : Int,
  want_gain : Double,
  want_tapset : Int,
  want_transient : Bool,
  want_intra : Bool,
  tag : String,
) -> Unit raise {
  if got.silence != want_silence {
    @test.fail("\{tag}: silence \{got.silence} != \{want_silence}")
  }
  if got.is_transient != want_transient {
    @test.fail("\{tag}: is_transient \{got.is_transient} != \{want_transient}")
  }
  if got.intra != want_intra {
    @test.fail("\{tag}: intra \{got.intra} != \{want_intra}")
  }
  if got.postfilter_on != want_postfilter_on {
    @test.fail(
      "\{tag}: postfilter_on \{got.postfilter_on} != \{want_postfilter_on}",
    )
  }
  if got.postfilter_on {
    // §4.3.7.1：octave 取 0..5，故周期落在 15..1022（含两端）
    if got.postfilter_pitch < 15 || got.postfilter_pitch > 1022 {
      @test.fail(
        "\{tag}: postfilter_pitch \{got.postfilter_pitch} 超出 15..1022",
      )
    }
    // tapset 的 PDF 是 {2,1,1}/4，三个取值
    if got.postfilter_tapset < 0 || got.postfilter_tapset > 2 {
      @test.fail("\{tag}: tapset \{got.postfilter_tapset} 超出 0..2")
    }
    // G = 3*(int_gain+1)/32，int_gain 为 0..7
    if got.postfilter_gain <= 0.0 || got.postfilter_gain > 0.75 {
      @test.fail("\{tag}: gain \{got.postfilter_gain} 超出 (0, 0.75]")
    }
    if got.postfilter_pitch != want_pitch {
      @test.fail("\{tag}: pitch \{got.postfilter_pitch} != \{want_pitch}")
    }
    if got.postfilter_gain != want_gain {
      @test.fail("\{tag}: gain \{got.postfilter_gain} != \{want_gain}")
    }
    if got.postfilter_tapset != want_tapset {
      @test.fail("\{tag}: tapset \{got.postfilter_tapset} != \{want_tapset}")
    }
  } else if want_pitch != 0 || want_tapset != 0 || want_gain != 0.0 {
    // 未启用时三个字段必须停在 0，不能留着上一帧的值
    @test.fail("\{tag}: 未启用后滤波却带出了参数")
  }
}

///|
/// 静音帧的位计数推进：只移动计数，不消费比特，也不动位置状态。
test "静音跳位只改位计数" {
  let dec = RangeDecoder::new(b"\x5a\xa5\x3c\xff\x11\x22\x33\x44")
  let before_rng = dec.rng
  let before_val = dec.val
  let before_tell = dec.tell()
  let before_bits = dec.nbits_total()
  dec.skip_bits_to(before_bits + 100)
  // skip 推进的是 nbits_total；rng/val 没动，故 tell 同步前进 100
  @test.assert_eq(dec.nbits_total(), before_bits + 100)
  @test.assert_eq(dec.tell(), before_tell + 100)
  @test.assert_eq(dec.rng, before_rng)
  @test.assert_eq(dec.val, before_val)
  // 目标比当前位置更靠前时没有副作用
  dec.skip_bits_to(before_bits)
  @test.assert_eq(dec.nbits_total(), before_bits + 100)
}
