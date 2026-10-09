// opus_packet.mbt
//
// RFC 6716 §3：Opus 音频包的 TOC 解析与帧打包布局。
// 本模块只解析包的自描述结构（模式/带宽/帧时长/帧数/帧长/VBR/填充），
// 不触碰任何压缩系数；畸形包按 §3.4 摘要的 [R1]–[R7] 约束分类返回 Err，
// 调用方（解码器）据此丢弃或做丢包隐藏。

///|
/// 三种工作模式（RFC 6716 §3.1）：SILK-only / Hybrid / CELT-only。
pub enum OpusMode {
  Silk
  Hybrid
  Celt
}

///|
/// 五档音频带宽（RFC 6716 §3.1 Table 2）：NB / MB / WB / SWB / FB。
pub enum OpusBandwidth {
  Nb
  Mb
  Wb
  Swb
  Fb
}

///|
/// 解析后的 Opus 音频包结构。
pub struct OpusPacket {
  config : Int
  stereo : Bool
  mode : OpusMode
  bandwidth : OpusBandwidth
  frame_samples : Int
  frame_count : Int
  frame_lengths : Array[Int]
  is_vbr : Bool
  padding_bytes : Int
  /// 原始包字节（frame_data 切片来源）
  data : Bytes
  /// 帧数据区起点：越过 TOC、帧长字段与填充头（§3.2）
  payload_off : Int
}

///|
/// Table 2 帧时长换算到 48 kHz 采样数。
/// SILK-only（配置 0..11）：10/20/40/60 ms → 480/960/1920/2880。
fn silk_frame_samples(i : Int) -> Int {
  if i == 0 {
    480
  } else if i == 1 {
    960
  } else if i == 2 {
    1920
  } else {
    2880
  }
}

///|
/// CELT-only（配置 16..31）：2.5/5/10/20 ms → 120/240/480/960。
fn celt_frame_samples(i : Int) -> Int {
  if i == 0 {
    120
  } else if i == 1 {
    240
  } else if i == 2 {
    480
  } else {
    960
  }
}

///|
/// RFC 6716 §3.1 Table 2：配置号 → (模式, 带宽, 每帧 48 kHz 采样数)。
/// 同区间内的配置号按帧尺寸同序对应（如 0→10 ms、3→60 ms）。
fn opus_config_params(config : Int) -> (OpusMode, OpusBandwidth, Int) {
  if config < 12 {
    let bw = if config < 4 {
      OpusBandwidth::Nb
    } else if config < 8 {
      OpusBandwidth::Mb
    } else {
      OpusBandwidth::Wb
    }
    (OpusMode::Silk, bw, silk_frame_samples(config % 4))
  } else if config < 16 {
    // Hybrid：12..13 SWB、14..15 FB，各只有 10/20 ms 两档
    let bw = if config < 14 { OpusBandwidth::Swb } else { OpusBandwidth::Fb }
    (OpusMode::Hybrid, bw, if config % 2 == 0 { 480 } else { 960 })
  } else {
    let bw = if config < 20 {
      OpusBandwidth::Nb
    } else if config < 24 {
      OpusBandwidth::Wb
    } else if config < 28 {
      OpusBandwidth::Swb
    } else {
      OpusBandwidth::Fb
    }
    (OpusMode::Celt, bw, celt_frame_samples(config % 4))
  }
}

///|
/// §3.2.1 帧长编码：0 → 零长帧（DTX）；1..251 → 单字节；
/// 252..255 → 需第二字节，总长 = second*4 + first（最大 1275）。
/// 返回 (帧长, 消耗字节数)；字节不足时返回 Err。
fn decode_frame_length(
  data : Bytes,
  pos : Int,
  end : Int,
) -> Result[(Int, Int), String] {
  if pos >= end {
    return Err("truncated frame length")
  }
  let b1 = data.unsafe_get(pos).to_int()
  if b1 < 252 {
    return Ok((b1, 1))
  }
  if pos + 1 >= end {
    return Err("frame length needs a second byte")
  }
  let b2 = data.unsafe_get(pos + 1).to_int()
  Ok((b2 * 4 + b1, 2))
}

///|
/// 解析一个 Opus 音频包的结构（RFC 6716 §3.1–§3.2）。
///
/// 畸形包按 §3.4 的 [R1]–[R7] 约束拒绝：
///   * [R1] 至少 1 字节；
///   * [R2] 隐式/显式帧长不超过 1275 字节；
///   * [R3] code 1 包总长必须为奇数；
///   * [R4] code 2 首帧长字段完整且不超过剩余字节；
///   * [R5] code 3 至少 1 帧、总时长不超过 120 ms；
///   * [R6] code 3 CBR：≥2 字节、填充开销 P ≤ N-2、R 是 M 的整数倍；
///   * [R7] code 3 VBR：头部与显式帧长之和不超过包长。
pub fn parse_opus_packet(data : Bytes) -> Result[OpusPacket, String] {
  let n = data.length()
  if n == 0 {
    return Err("malformed packet [R1]: empty packet")
  }
  let toc = data.unsafe_get(0).to_int()
  let config = toc >> 3
  let stereo = (toc & 4) != 0
  let code = toc & 3
  let (mode, bandwidth, frame_samples) = opus_config_params(config)
  let frame_lengths : Array[Int] = []
  let mut frame_count = 0
  let mut is_vbr = false
  let mut padding_bytes = 0
  let mut payload_off = 0
  if code == 0 {
    // §3.2.2：TOC 之后全部是唯一一帧的数据
    if n - 1 > 1275 {
      return Err("malformed packet [R2]: implicit frame exceeds 1275 bytes")
    }
    frame_count = 1
    frame_lengths.push(n - 1)
    payload_off = 1
  } else if code == 1 {
    // §3.2.3：[R3] N 必须为奇数，两帧各 (N-1)/2 字节
    if n % 2 == 0 {
      return Err("malformed packet [R3]: code 1 packet length must be odd")
    }
    let half = (n - 1) / 2
    if half > 1275 {
      return Err("malformed packet [R2]: implicit frame exceeds 1275 bytes")
    }
    frame_count = 2
    frame_lengths.push(half)
    frame_lengths.push(half)
    payload_off = 1
  } else if code == 2 {
    // §3.2.4：[R4] 需足以解出首帧长，且首帧长不超过剩余字节
    if n < 2 {
      return Err(
        "malformed packet [R4]: code 2 packet too short for a frame length",
      )
    }
    let (n1, used) = match decode_frame_length(data, 1, n) {
      Ok(v) => v
      Err(e) => return Err("malformed packet [R4]: \{e}")
    }
    payload_off = 1 + used
    let rest = n - 1 - used
    if n1 > rest {
      return Err(
        "malformed packet [R4]: first frame length exceeds remaining bytes",
      )
    }
    let second = rest - n1
    if second > 1275 {
      return Err("malformed packet [R2]: implicit frame exceeds 1275 bytes")
    }
    frame_count = 2
    frame_lengths.push(n1)
    frame_lengths.push(second)
    is_vbr = true
  } else {
    // §3.2.5：code 3 —— 帧数字节 (v|p|M) + 可选填充 + CBR/VBR 帧数据
    if n < 2 {
      return Err(
        "malformed packet [R6]: code 3 packet needs a frame count byte",
      )
    }
    let fcb = data.unsafe_get(1).to_int()
    let vbr = (fcb & 1) != 0
    let has_padding = (fcb & 2) != 0
    let m = fcb >> 2
    if m == 0 {
      return Err("malformed packet [R5]: frame count must not be zero")
    }
    // [R5] 总时长 ≤ 120 ms = 5760 采样 @48 kHz
    if m * frame_samples > 5760 {
      return Err("malformed packet [R5]: packet longer than 120 ms")
    }
    let mut pos = 2
    if has_padding {
      if pos >= n {
        return Err("malformed packet [R6]: missing padding length")
      }
      let first = data.unsafe_get(pos).to_int()
      pos += 1
      if first < 255 {
        padding_bytes = first
      } else {
        if pos >= n {
          return Err(
            "malformed packet [R6]: missing second padding length byte",
          )
        }
        padding_bytes = 254 + data.unsafe_get(pos).to_int()
        pos += 1
      }
      // [R6] P = 填充长度头字节 + 尾部填充字节 ≤ N-2
      if pos - 2 + padding_bytes > n - 2 {
        return Err("malformed packet [R6]: padding exceeds packet bounds")
      }
    }
    let content_end = n - padding_bytes
    // 上面的 P ≤ N-2 已保证 content_end ≥ pos
    if vbr {
      // [R7] M-1 个显式帧长；总和不得超过解码后的剩余字节
      let mut sum = 0
      for _ in 1..<m {
        let (len, used) = match decode_frame_length(data, pos, content_end) {
          Ok(v) => v
          Err(e) => return Err("malformed packet [R7]: \{e}")
        }
        pos += used
        sum += len
        frame_lengths.push(len)
      }
      if sum > content_end - pos {
        return Err(
          "malformed packet [R7]: explicit frame lengths exceed packet",
        )
      }
      // pos 此时越过的是长度字段区；前 M-1 帧的数据还要再占 sum 字节，
      // 末帧吃掉填充之前的剩余全部（§3.2.5）
      let last = content_end - pos - sum
      if last > 1275 {
        return Err("malformed packet [R2]: implicit frame exceeds 1275 bytes")
      }
      frame_lengths.push(last)
      is_vbr = true
    } else {
      // [R6] R = N-2-P 必须是非负整数倍的 M（R ≥ 0 由 P ≤ N-2 保证）
      let r = content_end - pos
      if r % m != 0 {
        return Err(
          "malformed packet [R6]: CBR payload is not a multiple of the frame count",
        )
      }
      let flen = r / m
      if flen > 1275 {
        return Err("malformed packet [R2]: implicit frame exceeds 1275 bytes")
      }
      for _ in 0..<m {
        frame_lengths.push(flen)
      }
    }
    frame_count = m
    payload_off = pos
  }
  Ok({
    config,
    stereo,
    mode,
    bandwidth,
    frame_samples,
    frame_count,
    frame_lengths,
    is_vbr,
    padding_bytes,
    data,
    payload_off,
  })
}

///|
/// 第 i 帧的压缩载荷（§3.2 帧数据区，不含 TOC/帧长/填充）。
/// 越界或负索引返回 None。
pub fn OpusPacket::frame_data(self : OpusPacket, i : Int) -> Bytes? {
  if i < 0 || i >= self.frame_count {
    return None
  }
  let mut off = self.payload_off
  for k in 0..<i {
    off += self.frame_lengths[k]
  }
  let n = self.frame_lengths[i]
  let buf = @buffer.Buffer()
  for j in 0..<n {
    buf.write_byte(self.data.unsafe_get(off + j))
  }
  Some(buf.to_bytes())
}

///|
/// 配置号（0..31）。
pub fn OpusPacket::config(self : OpusPacket) -> Int {
  self.config
}

///|
/// 立体声标志（TOC 的 s 位）。
pub fn OpusPacket::stereo(self : OpusPacket) -> Bool {
  self.stereo
}

///|
/// 工作模式。
pub fn OpusPacket::mode(self : OpusPacket) -> OpusMode {
  self.mode
}

///|
/// 音频带宽。
pub fn OpusPacket::bandwidth(self : OpusPacket) -> OpusBandwidth {
  self.bandwidth
}

///|
/// 每帧时长（48 kHz 采样数；2.5 ms=120 … 60 ms=2880）。
pub fn OpusPacket::frame_samples(self : OpusPacket) -> Int {
  self.frame_samples
}

///|
/// 包内帧数（code 0/1/2 为 1/2/2，code 3 为 M）。
pub fn OpusPacket::frame_count(self : OpusPacket) -> Int {
  self.frame_count
}

///|
/// 第 `i` 帧的压缩字节长；越界返回 `None`。
pub fn OpusPacket::frame_length(self : OpusPacket, i : Int) -> Int? {
  if i < 0 || i >= self.frame_lengths.length() {
    None
  } else {
    Some(self.frame_lengths[i])
  }
}

///|
/// 是否为变码率打包（code 2，或 code 3 的 v 位）。
pub fn OpusPacket::is_vbr(self : OpusPacket) -> Bool {
  self.is_vbr
}

///|
/// Opus 层尾部填充字节数（无填充时为 0）。
pub fn OpusPacket::padding_bytes(self : OpusPacket) -> Int {
  self.padding_bytes
}

///|
/// 包内音频总时长（48 kHz 采样数）。
pub fn OpusPacket::duration_48k(self : OpusPacket) -> Int {
  self.frame_count * self.frame_samples
}
