// opus_decode.mbt
//
// Ogg Opus 字节流 → PCM 的端到端驱动（CELT-only 全频带单声道范围）：
// open_opus 取包序列 → §3 解析取每帧载荷 → celt_decode_frame_audio
// 逐帧解码 → 拼接并按 OpusHead 的 pre-skip 截掉编码器前瞻。
//
// 拒绝条件（与实现能力一致，错误信息直说）：
//   - 仅 CELT-only（config 16..31）且全频带（config 28..31）：后者保证
//     走 48 kHz 标准模式 end=21 的已验证路径，其它带宽 end<21 分支
//     暂无金标覆盖，不接；
//   - 单声道：立体声/多声道映射不在范围；
//   - 帧载荷 ≤1 字节走丢包隐藏（参考实现同式 len≤1 → PLC），本流程
//     无 PLC，遇到 DTX/空帧直接 Err；
//   - 无丢包、无乱序：包序即页序，逐包顺序解码。

///|
/// 解码整个 .opus（Ogg Opus）字节流为 48 kHz 单声道 PCM。
///
/// 跨帧状态（频域 CeltDecoderState + 时域 CeltSynthState）在流内延续，
/// 每条流独立初始化。返回的样本已按 pre-skip 截头，尚未按 granulepos
/// 截尾（与逐包全量解码一致）。
pub fn decode_opus_pcm(data : Bytes) -> Result[Array[Double], String] {
  let stream = match open_opus(data) {
    Ok(s) => s
    Err(e) => return Err("not a valid Ogg Opus stream: \{e}")
  }
  if stream.channels() != 1 {
    return Err(
      "本解码器为单声道 CELT-only，此流 \{stream.channels()} 声道",
    )
  }
  let celt = CeltDecoderState::new()
  let synth = CeltSynthState::new()
  let pcm : Array[Double] = []
  for i in 0..<stream.packet_count() {
    let pkt = match stream.packet(i) {
      Some(b) => b
      None => return Err("packet \{i}: 载荷缺失")
    }
    let p = match parse_opus_packet(pkt) {
      Ok(p) => p
      Err(e) => return Err("packet \{i}: \{e}")
    }
    match p.mode() {
      OpusMode::Celt => ()
      _ =>
        return Err(
          "packet \{i}: config \{p.config()} 非 CELT-only，超出范围",
        )
    }
    match p.bandwidth() {
      OpusBandwidth::Fb => ()
      _ =>
        return Err(
          "packet \{i}: config \{p.config()} 非全频带，超出范围",
        )
    }
    if p.stereo() {
      return Err("packet \{i}: TOC 标记立体声，超出单声道范围")
    }
    let lm = match celt_lm_of_frame_samples(p.frame_samples()) {
      Some(v) => v
      None => return Err("packet \{i}: 非标准 CELT 帧时长")
    }
    for f in 0..<p.frame_count() {
      let fb = match p.frame_data(f) {
        Some(b) => b
        None => return Err("packet \{i} frame \{f}: 载荷缺失")
      }
      if fb.length() <= 1 {
        return Err(
          "packet \{i} frame \{f}: 空帧/DTX 走 PLC，超出无损范围",
        )
      }
      let dec = RangeDecoder::new(fb)
      let res = celt_decode_frame_audio(
        dec,
        fb.length(),
        0,
        21,
        lm,
        celt,
        synth,
      )
      for s in res.pcm {
        pcm.push(s)
      }
    }
  }
  let skip = stream.pre_skip()
  if skip > pcm.length() {
    return Err("pre-skip \{skip} 超过解码总长 \{pcm.length()}")
  }
  // 有效输出 = 末页 granule − pre-skip（RFC 7845 §4.3：granule 即
  // 48 kHz 总样本位置）；granule 超出实解长度说明容器与载荷不自洽，拒绝
  let end = (stream.granule() - skip.to_int64()).to_int()
  if end < 0 {
    return Err("granule \{stream.granule()} 小于 pre-skip \{skip}")
  }
  if end > pcm.length() - skip {
    return Err("granule \{stream.granule()} 超出实解总长 \{pcm.length()}")
  }
  let out = Array::make(end, 0.0)
  for i in 0..<end {
    out[i] = pcm[skip + i]
  }
  Ok(out)
}
