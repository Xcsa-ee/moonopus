// opus_stream.mbt
//
// Ogg Opus 流的打开入口：按 RFC 7845 §4 的页序与连续性规则逐页组装逻辑
// 包，解析两个头包并收集音频数据包。
// 输入为外部不可信字节流：任何越界、顺序或字段非法都返回 Err。

///|
/// 一个已通过全部头部校验的 Ogg Opus 逻辑流。
pub struct OpusStream {
  head : OpusHead
  tags : OpusTags
  audio : Array[Bytes]
  /// 最后完成音频包所在页的 granulepos（RFC 7845 §4.3：48 kHz 总样本
  /// 位置；无音频包完成的页 granule 为 -1，不更新）
  granule : Int64
}

///|
/// 打开一个 Ogg Opus 字节流。
///
/// 校验范围（RFC 7845 §4）：
///   * 首页必须带 BOS 且 granule 为 0，OpusHead 独占首页并完成于首页；
///   * OpusTags 为第二个包，其完成页 granule 必须为 0；
///   * 页序号必须从 0 连续；serial 全程一致；出现第二个 BOS 即为链式流
///     （本项目明确不支持，直接拒绝）；
///   * CONTINUED 标志与上一页未完成状态严格一致，否则该页首包不可解码；
///   * EOS 页之后不得再有页；缺 EOS 的整页截断流按 §4 容忍，
///     但残缺页视为损坏并报错。
///
/// 当前范围：容器层解析，不含音频帧解码。
pub fn open_opus(data : Bytes) -> Result[OpusStream, String] {
  let assembler = PacketAssembler::new()
  let mut head : OpusHead? = None
  let mut tags : OpusTags? = None
  let mut head_done = false
  let mut tags_done = false
  let audio : Array[Bytes] = []
  let mut offset = 0
  let mut page_index = 0
  let mut serial = 0U
  let mut eos_seen = false
  let mut last_granule = 0L
  while offset < data.length() {
    if eos_seen {
      return Err("page after end of stream")
    }
    let page = match OggPage::parse(data, offset) {
      Ok(p) => p
      Err(e) => return Err(e)
    }
    let bos = (page.header_type & FLAG_BOS) != 0
    if page_index == 0 {
      if !bos {
        return Err("first page must have BOS flag")
      }
      serial = page.serial_number
    } else {
      if bos {
        return Err("chained Ogg Opus streams are not supported")
      }
      if page.serial_number != serial {
        return Err("page serial number mismatch")
      }
      if page.page_sequence != page_index.reinterpret_as_uint() {
        return Err("page sequence mismatch")
      }
    }
    // §4：continued 标志必须与上一页的未完成状态严格一致，否则该页
    // 首包不可解码——容器层直接拒绝而不是带病下传。
    let cont = (page.header_type & FLAG_CONTINUED) != 0
    let partial = assembler.has_partial()
    if partial && !cont {
      return Err("continued packet lost its continuation page")
    }
    if !partial && cont {
      return Err("continued flag without a pending packet")
    }
    let size = page.total_size()
    let done = assembler.push_page(page)
    let mut pushed_audio = false
    if page_index == 0 && (done.length() != 1 || assembler.has_partial()) {
      return Err("OpusHead must be alone on the first page")
    }
    for pkt in done {
      if !head_done {
        // §4：ID 头页的 granule 必须为 0
        if page.granule_position != 0L {
          return Err("granule must be zero on ID header page")
        }
        let h = match parse_opus_head(pkt) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        head = Some(h)
        head_done = true
      } else if !tags_done {
        // §4：注释头完成页的 granule 必须为 0
        if page.granule_position != 0L {
          return Err("granule must be zero on comment header page")
        }
        let t = match parse_opus_tags(pkt) {
          Ok(v) => v
          Err(e) => return Err(e)
        }
        tags = Some(t)
        tags_done = true
      } else {
        audio.push(pkt)
        pushed_audio = true
      }
    }
    if pushed_audio && page.granule_position >= 0L {
      last_granule = page.granule_position
    }
    if (page.header_type & FLAG_EOS) != 0 {
      eos_seen = true
    }
    offset += size
    page_index += 1
  }
  let h = match head {
    Some(v) => v
    None => return Err("missing OpusHead")
  }
  let t = match tags {
    Some(v) => v
    None => return Err("missing OpusTags")
  }
  Ok({ head: h, tags: t, audio, granule: last_granule, })
}

///|
/// 输出声道数（OpusHead channel count）。
pub fn OpusStream::channels(self : OpusStream) -> Int {
  self.head.channels
}

///|
/// 起播时应丢弃的 48 kHz 采样数（RFC 7845 §4.2 pre-skip）。
pub fn OpusStream::pre_skip(self : OpusStream) -> Int {
  self.head.pre_skip
}

///|
/// 编码前原始输入采样率（仅元数据，不是播放采样率；0 表示未指定）。
pub fn OpusStream::input_sample_rate(self : OpusStream) -> UInt {
  self.head.input_sample_rate
}

///|
/// 解码输出应施加的增益（Q7.8 dB，带符号）。
pub fn OpusStream::output_gain(self : OpusStream) -> Int {
  self.head.output_gain
}

///|
/// 声道映射族（0 / 1 / 255；保留值 2..254 按 255 语义解析）。
pub fn OpusStream::mapping_family(self : OpusStream) -> Int {
  self.head.mapping_family
}

///|
/// 每包编码流数 N（OpusHead mapping table；family 0 隐含为 1）。
pub fn OpusStream::stream_count(self : OpusStream) -> Int {
  self.head.stream_count
}

///|
/// 其中配置为双声道输出的耦合流数 M（family 0 隐含为 C-1）。
pub fn OpusStream::coupled_count(self : OpusStream) -> Int {
  self.head.coupled_count
}

///|
/// 声道映射表（family 0 为空，语义等价于下标 0..C-1；255 表示纯静音声道）。
pub fn OpusStream::channel_mapping(self : OpusStream) -> Array[Byte] {
  self.head.channel_mapping
}

///|
/// vendor 字符串（OpusTags）。
pub fn OpusStream::vendor(self : OpusStream) -> String {
  self.tags.vendor
}

///|
/// 用户注释列表（OpusTags comments，UTF-8 解码，无效字节替换为 U+FFFD）。
pub fn OpusStream::comments(self : OpusStream) -> Array[String] {
  self.tags.comments
}

///|
/// 最后完成音频包所在页的 granulepos（RFC 7845 §4.3）：流末的 48 kHz
/// 总样本位置，与 pre-skip 相减即有效输出长度。无音频页时为 0。
pub fn OpusStream::granule(self : OpusStream) -> Int64 {
  self.granule
}

///|
/// 音频数据包数量（OpusTags 之后的全部逻辑包，尚未做 TOC 解析）。
pub fn OpusStream::packet_count(self : OpusStream) -> Int {
  self.audio.length()
}

///|
/// 第 `i` 个音频数据包；越界返回 `None`。
pub fn OpusStream::packet(self : OpusStream, i : Int) -> Bytes? {
  if i < 0 || i >= self.audio.length() {
    None
  } else {
    Some(self.audio[i])
  }
}
