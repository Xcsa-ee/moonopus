// ogg_packet.mbt
//
// （容器层基础改编自同一作者的 moonvorbis 项目，Apache-2.0。）
//
// OGG packet 重组。OGG 通过 lacing 规则把若干 segment 组成逻辑 packet：
//   * 每个 segment 长度 0~255；
//   * 长度 < 255 表示它是当前 packet 的最后一个 segment；
//   * 长度 == 255 表示 packet 尚未结束，下一个 segment 仍属于同一 packet；
//   * 若页结束时 packet 仍未结束（该页最后一个 segment 长度为 255），
//     则下一个页必须带 CONTINUED 标志，其第一个 segment 延续该 packet。
//
// CONTINUED 标志与未完成状态的逐页一致性校验由 opus_stream.mbt 在调用方
// 侧完成（RFC 7845 §4 的连续性规则）。

///|
/// packet 重组器：跨页累积未完成的 packet。
struct PacketAssembler {
  buf : @buffer.Buffer
  mut active : Bool
}

///|
/// 新建一个空的 packet 重组器。
pub fn PacketAssembler::new() -> PacketAssembler {
  { buf: @buffer.Buffer(), active: false, }
}

///|
/// 处理一个页，返回该页内完成的所有 packet。
///
/// 跨页未完成的 packet 会累积在内部缓冲中，直到遇到长度 < 255 的 segment 才输出。
/// 调用方应保证页按顺序传入，且页的 CONTINUED 标志与上一个页的未完成状态一致。
pub fn PacketAssembler::push_page(
  self : PacketAssembler,
  page : OggPage,
) -> Array[Bytes] {
  let packets : Array[Bytes] = []
  let body_start = page.offset + OGG_HEADER_SIZE + page.n_segments
  let mut cursor = body_start
  for i in 0..<page.n_segments {
    let seg_len = page.segment_len(i)
    for j in 0..<seg_len {
      self.buf.write_byte(page.data.unsafe_get(cursor + j))
    }
    cursor += seg_len
    self.active = true
    if seg_len < 255 {
      packets.push(self.buf.to_bytes())
      self.buf.reset()
      self.active = false
    }
  }
  packets
}

///|
/// 当前是否有跨页未完成的 packet（即上一个页以长度为 255 的 segment 结尾）。
pub fn PacketAssembler::has_partial(self : PacketAssembler) -> Bool {
  self.active
}
