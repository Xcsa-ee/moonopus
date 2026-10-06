// ogg_page.mbt
//
// （容器层基础改编自同一作者的 moonvorbis 项目，Apache-2.0。）
//
// OGG 页解析。一个 OGG 页由三部分组成：
//   * 固定 27 字节页头（magic + version + header_type + granule + serial + seq + checksum + segments 计数）
//   * segment table（页头最后一个字节指定条目数，每项是一个 segment 的字节长度）
//   * body（所有 segment 字节的拼接）
//
// 本模块负责解析单个页并做 CRC 校验。把多个页的 segment 重组成逻辑 packet
// 的工作放在 ogg_packet.mbt 实现。

///|
/// OGG 页固定头长度（不含 segment table 和 body）。
const OGG_HEADER_SIZE : Int = 27

///|
/// 页头类型标志位。
pub const FLAG_CONTINUED : Int = 0x01

///|
pub const FLAG_BOS : Int = 0x02

///|
pub const FLAG_EOS : Int = 0x04

///|
/// 解析后的 OGG 页。
///
/// `data` 保存原始字节序列，`offset` 是页在其中的起始位置。
/// segment table 位于 `data[offset + 27 .. offset + 27 + n_segments)`，
/// body 紧随其后，长度为 `body_len`。
pub struct OggPage {
  data : Bytes
  offset : Int
  header_type : Int
  granule_position : Int64
  serial_number : UInt
  page_sequence : UInt
  checksum : UInt
  n_segments : Int
  body_len : Int
}

///|
/// 解析从 `data[offset]` 开始的一个 OGG 页。
///
/// 成功返回页结构；失败返回错误描述（magic 不符 / 版本不支持 / 数据截断 / CRC 校验失败）。
pub fn OggPage::parse(data : Bytes, offset : Int) -> Result[OggPage, String] {
  // 页头长度不足
  if data.length() - offset < OGG_HEADER_SIZE {
    return Err("truncated Ogg page header")
  }
  // magic "OggS"
  if data.unsafe_get(offset) != b'O' ||
    data.unsafe_get(offset + 1) != b'g' ||
    data.unsafe_get(offset + 2) != b'g' ||
    data.unsafe_get(offset + 3) != b'S' {
    return Err("not an Ogg page (bad magic)")
  }
  // version 必须为 0
  if data.unsafe_get(offset + 4) != b'\x00' {
    return Err("unsupported Ogg version")
  }

  let header_type = data.unsafe_get(offset + 5).to_int()
  let granule_position = data
    .unsafe_read_uint64_le(offset + 6)
    .reinterpret_as_int64()
  let serial_number = data.unsafe_read_uint32_le(offset + 14)
  let page_sequence = data.unsafe_read_uint32_le(offset + 18)
  let checksum = data.unsafe_read_uint32_le(offset + 22)
  let n_segments = data.unsafe_get(offset + 26).to_int()

  // segment table 长度足够
  if data.length() - offset < OGG_HEADER_SIZE + n_segments {
    return Err("truncated Ogg segment table")
  }
  // 计算 body 长度（所有 segment 长度之和）
  let mut body_len = 0
  for i in 0..<n_segments {
    body_len += data.unsafe_get(offset + OGG_HEADER_SIZE + i).to_int()
  }
  let total_len = OGG_HEADER_SIZE + n_segments + body_len
  // body 长度足够
  if data.length() - offset < total_len {
    return Err("truncated Ogg page body")
  }

  // CRC 校验：checksum 字段（offset+22 .. offset+26）在计算时当作 4 个 0 字节参与，
  // 而不是跳过——CRC 是非线性累加，两者结果不同。
  let mut crc = ogg_crc32_update(0U, data, offset, 22)
  crc = ogg_crc32_update(crc, b"\x00\x00\x00\x00", 0, 4)
  crc = ogg_crc32_update(crc, data, offset + 26, total_len - 26)
  if crc != checksum {
    return Err("Ogg page CRC mismatch")
  }

  Ok({
    data,
    offset,
    header_type,
    granule_position,
    serial_number,
    page_sequence,
    checksum,
    n_segments,
    body_len,
  })
}

///|
/// 返回整个页的总长度（页头 + segment table + body）。
pub fn OggPage::total_size(self : OggPage) -> Int {
  OGG_HEADER_SIZE + self.n_segments + self.body_len
}

///|
/// 返回 segment table 中第 `i` 项的字节长度（`0 <= i < n_segments`）。
pub fn OggPage::segment_len(self : OggPage, i : Int) -> Int {
  self.data.unsafe_get(self.offset + OGG_HEADER_SIZE + i).to_int()
}
