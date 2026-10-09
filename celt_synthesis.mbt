// celt_synthesis.mbt
//
// 帧级时域合成链（RFC 6716 §4.3.7 合成 + §4.3.7.1 后滤波 + §4.3.7.2
// 去重 emphasis）：把 celt_decode_frame 的 freq 输出接成 PCM。顺序与参考
// 实现 celt_celt_decoder.c 的 celt_decode_frame 逐段对齐（浮点构建路径）：
//
//   - 缓冲衔接：参考实现每帧开头 OPUS_MOVE 左移（1508 行），out_syn 固定
//     落在 decode_mem 的 2048−N 处——其前是连续的 comb 后历史，其头部
//     [0, ov/2) 承接上一帧 raw 尾。这里等价拆成两个独立缓冲：pending
//     （ov/2 = 60，交由 IMDCT 衔接）与 hist（2048−960 = 1088，comb 前
//     历史；comb 最远回读 T(≤1022)+2 = 1024，1088 恒覆盖且与参考实现
//     最小历史区同宽）；
//   - IMDCT（celt_imdct.mbt，含 TDAC 镜像与瞬态分块）；
//   - 两段 comb（1565–1571 行）：首段 [0, 120) 用 旧 → st-> 参数，LM=0
//     时即整帧；LM≠0 时第二段 [120, N) 用 st-> → 本帧帧头局部参数，过渡
//     窗即 comb 自带的 overlap 窗。周期在调用前双双钳到 ≥15（1563–1564
//     行，就地写回——1574 行轮换搬的是钳后值）；
//   - 参数轮换（1574–1579 行）；LM≠0 再把 old 同步成本帧参数（1582–1584
//     行）。由此：LM≠0 的本帧参数过渡发生在本帧 [120, 240)；LM=0 的本帧
//     参数要到下一帧才开始过渡（整帧首段即过渡窗）；
//   - 去重 emphasis（1623 行）：一阶 IIR，状态 st->preemph_memD 跨帧；
//     实现复用 celt_mode.mbt 的 celt_deemphasis（float 构建下 C 端
//     VERY_SMALL = 1e-30 被舍入吸收，不实现，与既有单测口径一致）。
//
// 参考实现 comb 只读不写历史尾，IMDCT 输出的 SATURATE 在浮点构建下是
// 恒等宏——两者均已省略。prefilter_and_fold 只在丢包路径置位（1101 行），
// 正常帧 1630 行清零，本流程无丢包输入，不实现。

///|
/// comb 前历史长度：参考实现 decode_buffer_size(2048) − 最大帧长(960)。
const CEL_SYNTH_HIST : Int = 1088

///|
/// 时域合成状态（跨帧，全零初始化 = 参考实现的 memset 清零）。
pub struct CeltSynthState {
  /// 上一帧 raw 尾部 ov/2 个样本（§4.3.7 TDAC 衔接）
  mut pending : Array[Double]
  /// 连续的 comb 后历史（长度 CEL_SYNTH_HIST，只在尾部滚动）
  hist : Array[Double]
  /// st->postfilter_period_old
  mut pf_period_old : Int
  /// st->postfilter_gain_old
  mut pf_gain_old : Double
  /// st->postfilter_tapset_old
  mut pf_tapset_old : Int
  /// st->postfilter_period（本帧首段的「新」侧）
  mut pf_period : Int
  /// st->postfilter_gain
  mut pf_gain : Double
  /// st->postfilter_tapset
  mut pf_tapset : Int
  /// st->preemph_memD[0]
  mut deemph_mem : Double
}

///|
/// 全零初始状态。
pub fn CeltSynthState::new() -> CeltSynthState {
  CeltSynthState::{
    pending: Array::make(CEL_OVERLAP >> 1, 0.0),
    hist: Array::make(CEL_SYNTH_HIST, 0.0),
    pf_period_old: 0,
    pf_gain_old: 0.0,
    pf_tapset_old: 0,
    pf_period: 0,
    pf_gain: 0.0,
    pf_tapset: 0,
    deemph_mem: 0.0,
  }
}

///|
/// 一帧频谱 → PCM：IMDCT 衔接 → 两段 comb → 参数轮换 → 去重 emphasis。
///
/// `pf_pitch/pf_gain/pf_tapset` 是本帧帧头解出的后滤波参数（未启用时为
/// 0/0.0/0，与参考实现的局部变量一致）。`state` 跨帧就地更新，返回本帧
/// `120 << lm` 个样本。
pub fn celt_synth_frame(
  freq : Array[Double],
  lm : Int,
  is_transient : Bool,
  pf_pitch : Int,
  pf_gain : Double,
  pf_tapset : Int,
  state : CeltSynthState,
) -> Array[Double] {
  let n = CEL_SHORT_MDCT << lm
  // IMDCT：pending 承接上一帧 raw 尾，得到本帧输出与新尾
  let (out, new_pending) = celt_imdct_frame(
    freq,
    lm,
    is_transient,
    state.pending,
  )
  // 工作缓冲 = 历史 + 本帧输出；comb 就地改写本帧段，历史段只读
  let h = state.hist.length()
  let work = Array::make(h + n, 0.0)
  for i in 0..<h {
    work[i] = state.hist[i]
  }
  for i in 0..<n {
    work[h + i] = out[i]
  }
  // 周期钳制就地写回：1574 行的轮换搬的是钳后值
  if state.pf_period < CEL_COMB_MINPERIOD {
    state.pf_period = CEL_COMB_MINPERIOD
  }
  if state.pf_period_old < CEL_COMB_MINPERIOD {
    state.pf_period_old = CEL_COMB_MINPERIOD
  }
  let win = Array::make(CEL_OVERLAP, 0.0)
  for i in 0..<CEL_OVERLAP {
    win[i] = celt_window(i, CEL_OVERLAP)
  }
  // 首段：[0, 120) 旧 → st-> 参数（LM=0 时即整帧）
  celt_comb_filter(
    work,
    h,
    state.pf_period_old,
    state.pf_period,
    CEL_SHORT_MDCT,
    state.pf_gain_old,
    state.pf_gain,
    state.pf_tapset_old,
    state.pf_tapset,
    win,
  )
  if lm != 0 {
    // 第二段：[120, N) st-> → 本帧帧头参数
    celt_comb_filter(
      work,
      h + CEL_SHORT_MDCT,
      state.pf_period,
      pf_pitch,
      n - CEL_SHORT_MDCT,
      state.pf_gain,
      pf_gain,
      state.pf_tapset,
      pf_tapset,
      win,
    )
  }
  // 参数轮换（1574–1579 行）
  state.pf_period_old = state.pf_period
  state.pf_gain_old = state.pf_gain
  state.pf_tapset_old = state.pf_tapset
  state.pf_period = pf_pitch
  state.pf_gain = pf_gain
  state.pf_tapset = pf_tapset
  if lm != 0 {
    // LM≠0：old 同步成本帧参数（1582–1584 行）
    state.pf_period_old = state.pf_period
    state.pf_gain_old = state.pf_gain
    state.pf_tapset_old = state.pf_tapset
  }
  // 去重 emphasis：输入 = comb 后的本帧段，状态跨帧
  let x = Array::make(n, 0.0)
  for j in 0..<n {
    x[j] = work[h + j]
  }
  let pcm = Array::make(n, 0.0)
  state.deemph_mem = celt_deemphasis(x, pcm, state.deemph_mem)
  // 历史滚动：丢最旧 n 个样本、保留其后 h 个（n ≤ h 恒成立：960 ≤ 1088）
  for k in 0..<h {
    state.hist[k] = work[n + k]
  }
  state.pending = new_pending
  pcm
}

///|
/// 帧级解码结果（频域主流程 + 时域合成）。
pub struct CeltAudioResult {
  /// 帧首符号（含后滤波参数）
  header : CeltFrameHeader
  /// 本帧 PCM（120<<lm 个 48 kHz 样本）
  pcm : Array[Double]
}

///|
/// 端到端帧解码：频域主流程接时域合成链。参数与 celt_decode_frame 一致，
/// 另持一份时域状态 `synth`（`celt` 只管频域跨帧状态）。
pub fn celt_decode_frame_audio(
  dec : RangeDecoder,
  frame_bytes : Int,
  start : Int,
  end : Int,
  lm : Int,
  celt : CeltDecoderState,
  synth : CeltSynthState,
) -> CeltAudioResult {
  let r = celt_decode_frame(dec, frame_bytes, start, end, lm, celt)
  let pcm = celt_synth_frame(
    r.freq,
    lm,
    r.header.is_transient,
    r.header.postfilter_pitch,
    r.header.postfilter_gain,
    r.header.postfilter_tapset,
    synth,
  )
  CeltAudioResult::{ header: r.header, pcm, }
}
