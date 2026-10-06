// opus_head.mbt
//
// RFC 7845 §5.1（OpusHead 标识头）与 §5.2（OpusTags 注释头）的解析与校验。
// 校验规则逐条对照 RFC 7845 原文；输入是外部不可信字节流，所有越界与
// 非法字段一律返回 Err，不做部分解析。

///|
/// 解析后的 OpusHead 标识头（RFC 7845 §5.1）。
struct OpusHead {
  channels : Int
  pre_skip : Int
  input_sample_rate : UInt
  output_gain : Int
  mapping_family : Int
  stream_count : Int
  coupled_count : Int
  channel_mapping : Array[Byte]
}

///|
/// 解析后的 OpusTags 注释头（RFC 7845 §5.2）。
struct OpusTags {
  vendor : String
  comments : Array[String]
}

///|
/// OpusHead 固定部分长度：magic(8) + version(1) + channels(1) + pre-skip(2)
/// + input sample rate(4) + output gain(2) + mapping family(1)。
const OPUS_HEAD_FIXED_LEN : Int = 19

///|
/// 解析一个 OpusHead 逻辑包。
///
/// 校验点（RFC 7845）：
///   * §5.1：最小长度 19、magic、版本字节 ≤ 15（≥16 视为不兼容大版本）、
///     声道数非 0；
///   * §5.1.1.1：family 0 只允许 1/2 声道，且禁止携带映射表（恰长 19）；
///   * §5.1.1.2：family 1 允许 1..8 声道；family 255 及保留值 2..254
///     按 255 处理（§5.1.1.3/§5.1.1.4），声道可为 1..255；
///   * §5.1.1：表长 = 21 + C；stream count 非 0；coupled ≤ stream；
///     M + N ≤ 255；映射下标 < M + N 或为 255（纯静音）。
fn parse_opus_head(packet : Bytes) -> Result[OpusHead, String] {
  if packet.length() < OPUS_HEAD_FIXED_LEN {
    return Err("OpusHead too short")
  }
  if packet.unsafe_get(0) != b'O' ||
    packet.unsafe_get(1) != b'p' ||
    packet.unsafe_get(2) != b'u' ||
    packet.unsafe_get(3) != b's' ||
    packet.unsafe_get(4) != b'H' ||
    packet.unsafe_get(5) != b'e' ||
    packet.unsafe_get(6) != b'a' ||
    packet.unsafe_get(7) != b'd' {
    return Err("bad OpusHead magic")
  }
  let version = packet.unsafe_get(8).to_int()
  if version > 15 {
    return Err("unsupported OpusHead version \{version}")
  }
  let channels = packet.unsafe_get(9).to_int()
  if channels == 0 {
    return Err("channel count must not be zero")
  }
  let pre_skip = packet.unsafe_read_uint16_le(10).to_int()
  let input_sample_rate = packet.unsafe_read_uint32_le(12)
  let output_gain = Int16::reinterpret_from_uint16(
    packet.unsafe_read_uint16_le(16),
  ).to_int()
  let family = packet.unsafe_get(18).to_int()
  if family == 0 {
    if channels != 1 && channels != 2 {
      return Err("family 0 allows only 1 or 2 channels")
    }
    if packet.length() != OPUS_HEAD_FIXED_LEN {
      return Err("family 0 forbids the channel mapping table")
    }
    return Ok({
      channels,
      pre_skip,
      input_sample_rate,
      output_gain,
      mapping_family: family,
      stream_count: 1,
      coupled_count: channels - 1,
      channel_mapping: [],
    })
  }
  if family == 1 && channels > 8 {
    return Err("family 1 allows only 1..8 channels")
  }
  if packet.length() != OPUS_HEAD_FIXED_LEN + 2 + channels {
    return Err("bad channel mapping table length")
  }
  let stream_count = packet.unsafe_get(19).to_int()
  if stream_count == 0 {
    return Err("stream count must not be zero")
  }
  let coupled_count = packet.unsafe_get(20).to_int()
  if coupled_count > stream_count {
    return Err("coupled count exceeds stream count")
  }
  if coupled_count + stream_count > 255 {
    return Err("decoded channel count exceeds 255")
  }
  let channel_mapping : Array[Byte] = []
  for i in 0..<channels {
    let idx = packet.unsafe_get(21 + i)
    let v = idx.to_int()
    if v != 255 && v >= stream_count + coupled_count {
      return Err("channel mapping index out of range")
    }
    channel_mapping.push(idx)
  }
  Ok({
    channels,
    pre_skip,
    input_sample_rate,
    output_gain,
    mapping_family: family,
    stream_count,
    coupled_count,
    channel_mapping,
  })
}

///|
/// 解析一个 OpusTags 逻辑包（RFC 7845 §5.2：格式同 Vorbis comment，无 framing bit）。
///
/// 长度字段全部在无符号域与剩余字节数比较，先定界再转换，
/// 避免恶意长度（如 0xFFFFFFFF）引发越界或超长循环。
fn parse_opus_tags(packet : Bytes) -> Result[OpusTags, String] {
  if packet.length() < 16 {
    return Err("OpusTags too short")
  }
  if packet.unsafe_get(0) != b'O' ||
    packet.unsafe_get(1) != b'p' ||
    packet.unsafe_get(2) != b'u' ||
    packet.unsafe_get(3) != b's' ||
    packet.unsafe_get(4) != b'T' ||
    packet.unsafe_get(5) != b'a' ||
    packet.unsafe_get(6) != b'g' ||
    packet.unsafe_get(7) != b's' {
    return Err("bad OpusTags magic")
  }
  let mut pos = 8
  let vendor_len = packet.unsafe_read_uint32_le(pos)
  pos += 4
  // §5.2：vendor 长度不得指示超出包剩余部分
  if vendor_len > (packet.length() - pos).reinterpret_as_uint() {
    return Err("vendor string length exceeds packet")
  }
  let vendor = @utf8.decode_lossy(
    packet.exact_view(start=pos, end=pos + vendor_len.reinterpret_as_int()),
  )
  pos += vendor_len.reinterpret_as_int()
  if packet.length() - pos < 4 {
    return Err("missing comment count")
  }
  let count_raw = packet.unsafe_read_uint32_le(pos)
  pos += 4
  // 每条 comment 至少占 4 字节长度字段：先整体上界断言，杜绝大计数空转
  if count_raw > ((packet.length() - pos) / 4).reinterpret_as_uint() {
    return Err("comment count exceeds packet capacity")
  }
  let count = count_raw.reinterpret_as_int()
  let comments : Array[String] = []
  for _ in 0..<count {
    if packet.length() - pos < 4 {
      return Err("truncated comment length")
    }
    let len_raw = packet.unsafe_read_uint32_le(pos)
    pos += 4
    if len_raw > (packet.length() - pos).reinterpret_as_uint() {
      return Err("comment length exceeds packet")
    }
    let len = len_raw.reinterpret_as_int()
    comments.push(
      @utf8.decode_lossy(packet.exact_view(start=pos, end=pos + len)),
    )
    pos += len
  }
  if pos != packet.length() {
    return Err("trailing bytes after comments")
  }
  Ok({ vendor, comments, })
}
