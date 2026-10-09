// celt_frame_wbtest.mbt
//
// 帧级主流程（RFC 6716 §4.3 频域段）的白盒测试辅助。
//
// 金标由 tools/gen_frame_goldens.py 的独立 Python 参考端算出：比对
// 助手对频谱/频域输出用相对容差（expect_dn_close），对帧首标志、
// collapse mask、seed、解码器状态与帧间状态用精确比对（能量状态的
// 粗/细解码两侧都是定点化的相同运算，逐位一致是既有金标的判据）。

///|
/// 比对一帧的全部输出：帧首标志、频谱、频域输出、mask、seed 与
/// 解码器终态。
fn expect_frame(
  dec : RangeDecoder,
  res : CeltFrameResult,
  tag : String,
  want_silence : Bool,
  want_transient : Bool,
  want_intra : Bool,
  want_pf_on : Bool,
  want_pitch : Int,
  want_gain : Double,
  want_tapset : Int,
  want_spectrum : Array[Double],
  want_freq : Array[Double],
  want_masks : Array[Int],
  want_seed : Int64,
  want_rng : Int64,
  want_val : Int64,
  want_tell : Int,
  want_tell_frac : Int,
) -> Unit raise {
  let h = res.header
  if h.silence != want_silence {
    @test.fail("\{tag}: silence \{h.silence} != \{want_silence}")
  }
  if h.is_transient != want_transient {
    @test.fail("\{tag}: transient \{h.is_transient} != \{want_transient}")
  }
  if h.intra != want_intra {
    @test.fail("\{tag}: intra \{h.intra} != \{want_intra}")
  }
  if h.postfilter_on != want_pf_on {
    @test.fail("\{tag}: postfilter \{h.postfilter_on} != \{want_pf_on}")
  }
  if want_pf_on {
    if h.postfilter_pitch != want_pitch {
      @test.fail("\{tag}: pitch \{h.postfilter_pitch} != \{want_pitch}")
    }
    if h.postfilter_gain != want_gain {
      @test.fail("\{tag}: gain \{h.postfilter_gain} != \{want_gain}")
    }
    if h.postfilter_tapset != want_tapset {
      @test.fail("\{tag}: tapset \{h.postfilter_tapset} != \{want_tapset}")
    }
  }
  expect_dn_close(res.spectrum, want_spectrum, "\{tag}/spectrum", 0.000000001)
  expect_dn_close(res.freq, want_freq, "\{tag}/freq", 0.000000001)
  if res.collapse_masks.length() != want_masks.length() {
    @test.fail(
      "\{tag}: masks 长度 \{res.collapse_masks.length()} != \{want_masks.length()}",
    )
  }
  for i in 0..<want_masks.length() {
    if res.collapse_masks[i] != want_masks[i] {
      @test.fail(
        "\{tag}: mask[\{i}] \{res.collapse_masks[i]} != \{want_masks[i]}",
      )
    }
  }
  if res.seed != want_seed {
    @test.fail("\{tag}: seed \{res.seed} != \{want_seed}")
  }
  expect_dec_state(dec, tag, want_rng, want_val, want_tell, want_tell_frac)
}

///|
/// 比对帧末状态：三代能量数组精确比对、rng 精确比对，另断言
/// 「前半 == 后半拷贝」这一结构性不变量（帧末拷贝是状态语义本身）。
fn expect_state(
  state : CeltDecoderState,
  tag : String,
  want_old_e : Array[Double],
  want_log_e : Array[Double],
  want_log_e2 : Array[Double],
  want_rng : Int64,
) -> Unit raise {
  for i in 0..<42 {
    if state.old_e[i] != want_old_e[i] {
      @test.fail("\{tag}: old_e[\{i}] \{state.old_e[i]} != \{want_old_e[i]}")
    }
  }
  for i in 0..<42 {
    if state.old_log_e[i] != want_log_e[i] {
      @test.fail(
        "\{tag}: old_log_e[\{i}] \{state.old_log_e[i]} != \{want_log_e[i]}",
      )
    }
  }
  for i in 0..<42 {
    if state.old_log_e2[i] != want_log_e2[i] {
      @test.fail(
        "\{tag}: old_log_e2[\{i}] \{state.old_log_e2[i]} != \{want_log_e2[i]}",
      )
    }
  }
  if state.rng != want_rng {
    @test.fail("\{tag}: state.rng \{state.rng} != \{want_rng}")
  }
  // 结构性不变量：帧末拷贝后前半与后半必须相等
  for i in 0..<21 {
    if state.old_e[i] != state.old_e[21 + i] {
      @test.fail(
        "\{tag}: 帧末拷贝不等 old_e[\{i}]=\{state.old_e[i]} vs \{state.old_e[21 + i]}",
      )
    }
  }
}

///|
/// 独立于金标的结构性边界：全零初始状态的 rng 语义——第一帧的
/// LCG 种子来自初始 st->rng（0），帧末 rng 必须被熵解码器终值覆盖。
test "帧状态初始化与 rng 覆盖语义" {
  let state = CeltDecoderState::new()
  if state.rng != 0L {
    @test.fail("初始 rng 应为 0，得到 \{state.rng}")
  }
  for i in 0..<42 {
    if state.old_e[i] != 0.0 {
      @test.fail("初始 old_e[\{i}] 应为 0")
    }
  }
  // 一帧解码后 rng 必须等于该帧熵解码器终值（st->rng = dec->rng）
  let dec = RangeDecoder::new(b"\x01\x02\x03\x04\x05\x06\x07\x08")
  let _res = celt_decode_frame(dec, 8, 0, 21, 0, state)
  if state.rng != dec.rng {
    @test.fail("帧末 state.rng \{state.rng} != dec.rng \{dec.rng}")
  }
  // 帧末拷贝不变量
  for i in 0..<21 {
    if state.old_e[i] != state.old_e[21 + i] {
      @test.fail("帧末拷贝不等 old_e[\{i}]")
    }
  }
}
