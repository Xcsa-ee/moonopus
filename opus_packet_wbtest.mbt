// Whitebox tests for opus_packet.mbt（RFC 6716 §3：TOC 与帧打包）。
// 用例逐条对应 §3.4 摘要的 [R1]–[R7] 约束，包全部在测试内按规则构造。

///|
/// 按字节值数组构造包（TOC 字节等手算值写在用例里）。
fn build_packet(bytes : Array[Int]) -> Bytes {
  let buf = @buffer.Buffer()
  for x in bytes {
    buf.write_byte(x.to_byte())
  }
  buf.to_bytes()
}

///|
/// RFC 6716 §3.1 Table 2 的测试侧独立转录（与实现侧 opus_config_params
/// 分开维护，互为交叉检查）。
fn expected_table2(config : Int) -> (String, String, Int) {
  if config < 4 {
    let sizes = [480, 960, 1920, 2880]
    ("silk", "nb", sizes[config % 4])
  } else if config < 8 {
    let sizes = [480, 960, 1920, 2880]
    ("silk", "mb", sizes[config % 4])
  } else if config < 12 {
    let sizes = [480, 960, 1920, 2880]
    ("silk", "wb", sizes[config % 4])
  } else if config < 14 {
    ("hybrid", "swb", if config % 2 == 0 { 480 } else { 960 })
  } else if config < 16 {
    ("hybrid", "fb", if config % 2 == 0 { 480 } else { 960 })
  } else if config < 20 {
    let sizes = [120, 240, 480, 960]
    ("celt", "nb", sizes[config % 4])
  } else if config < 24 {
    let sizes = [120, 240, 480, 960]
    ("celt", "wb", sizes[config % 4])
  } else if config < 28 {
    let sizes = [120, 240, 480, 960]
    ("celt", "swb", sizes[config % 4])
  } else {
    let sizes = [120, 240, 480, 960]
    ("celt", "fb", sizes[config % 4])
  }
}

///|
fn mode_str(m : OpusMode) -> String {
  match m {
    OpusMode::Silk => "silk"
    OpusMode::Hybrid => "hybrid"
    OpusMode::Celt => "celt"
  }
}

///|
fn bw_str(b : OpusBandwidth) -> String {
  match b {
    OpusBandwidth::Nb => "nb"
    OpusBandwidth::Mb => "mb"
    OpusBandwidth::Wb => "wb"
    OpusBandwidth::Swb => "swb"
    OpusBandwidth::Fb => "fb"
  }
}

///|
/// Table 2 全表扫描：32 个配置逐一断言模式/带宽/帧时长。
/// 包 = 单字节 TOC（config<<3，code 0，mono），零长帧合法。
test "Table 2：32 个配置的模式/带宽/帧时长" {
  for config in 0..<32 {
    match parse_opus_packet(build_packet([config << 3])) {
      Ok(p) => {
        let (em, eb, es) = expected_table2(config)
        @test.assert_eq(mode_str(p.mode), em)
        @test.assert_eq(bw_str(p.bandwidth), eb)
        @test.assert_eq(p.frame_samples, es)
        @test.assert_eq(p.config, config)
        @test.assert_eq(p.frame_count, 1)
        @test.assert_eq(p.duration_48k(), es)
        match p.frame_length(0) {
          Some(len) => @test.assert_eq(len, 0)
          None => @test.fail("config \{config}: missing frame 0")
        }
      }
      Err(e) => @test.fail("config \{config}: \{e}")
    }
  }
}

///|
/// [R1] 至少 1 字节。
test "[R1] 空包被拒" {
  match parse_opus_packet(b"") {
    Ok(_) => @test.fail("expected [R1] error")
    Err(e) => if !e.contains("[R1]") { @test.fail("wrong error: \{e}") }
  }
}

///|
/// code 0：单帧占据 TOC 后全部字节；立体声/CELT FB 20 ms 字段正确；
/// [R2] 隐式帧不得超过 1275 字节。
test "code 0：单帧与 [R2]" {
  // config 31（CELT FB 20 ms）stereo code 0：TOC = 31<<3|4 = 0xFC
  let ok = [0xFC]
  for _ in 0..<10 {
    ok.push(0xAA)
  }
  match parse_opus_packet(build_packet(ok)) {
    Ok(p) => {
      @test.assert_eq(p.frame_count, 1)
      @test.assert_eq(p.stereo, true)
      @test.assert_eq(p.is_vbr, false)
      @test.assert_eq(p.frame_samples, 960)
      match p.frame_length(0) {
        Some(len) => @test.assert_eq(len, 10)
        None => @test.fail("missing frame 0")
      }
    }
    Err(e) => @test.fail(e)
  }
  // DTX：TOC 之后零字节 = 零长帧，合法
  match parse_opus_packet(build_packet([0x00])) {
    Ok(p) => @test.assert_eq(p.frame_length(0), Some(0))
    Err(e) => @test.fail(e)
  }
  // [R2] 1276 字节的隐式帧
  let big = [0x00]
  for _ in 0..<1276 {
    big.push(0)
  }
  match parse_opus_packet(build_packet(big)) {
    Ok(_) => @test.fail("expected [R2] error")
    Err(e) => if !e.contains("[R2]") { @test.fail("wrong error: \{e}") }
  }
}

///|
/// code 1：[R3] 总长奇数、两帧等长；偶数长被拒。
test "code 1：等长双帧与 [R3]" {
  // config 0（SILK NB 10 ms）code 1：TOC = 0x01；n=1 → 两零长帧
  match parse_opus_packet(build_packet([0x01])) {
    Ok(p) => {
      @test.assert_eq(p.frame_count, 2)
      @test.assert_eq(p.frame_length(0), Some(0))
      @test.assert_eq(p.frame_length(1), Some(0))
      @test.assert_eq(p.duration_48k(), 960) // 2 × 480
    }
    Err(e) => @test.fail(e)
  }
  // n=7（奇数）→ 两帧各 3 字节
  match parse_opus_packet(build_packet([0x01, 1, 2, 3, 4, 5, 6])) {
    Ok(p) => {
      @test.assert_eq(p.frame_length(0), Some(3))
      @test.assert_eq(p.frame_length(1), Some(3))
    }
    Err(e) => @test.fail(e)
  }
  // n=4（偶数）违反 [R3]
  match parse_opus_packet(build_packet([0x01, 1, 2, 3])) {
    Ok(_) => @test.fail("expected [R3] error")
    Err(e) => if !e.contains("[R3]") { @test.fail("wrong error: \{e}") }
  }
}

///|
/// code 2：单/双字节首帧长、零长帧边界；[R4] 三形态与 [R2] 第二帧。
test "code 2：变长双帧与 [R4]/[R2]" {
  // 单字节 N1=3，帧 2 占剩余 4 字节
  match parse_opus_packet(build_packet([0x02, 3, 10, 11, 12, 20, 21, 22, 23])) {
    Ok(p) => {
      @test.assert_eq(p.frame_count, 2)
      @test.assert_eq(p.is_vbr, true)
      @test.assert_eq(p.frame_length(0), Some(3))
      @test.assert_eq(p.frame_length(1), Some(4))
    }
    Err(e) => @test.fail(e)
  }
  // 双字节 N1 = 10*4+252 = 292（§3.2.1 公式），第二帧 5 字节
  let two = [0x02, 252, 10]
  for _ in 0..<292 {
    two.push(1)
  }
  for _ in 0..<5 {
    two.push(2)
  }
  match parse_opus_packet(build_packet(two)) {
    Ok(p) => {
      @test.assert_eq(p.frame_length(0), Some(292))
      @test.assert_eq(p.frame_length(1), Some(5))
    }
    Err(e) => @test.fail(e)
  }
  // §3.2.4 明示的唯一合法 2 字节 code 2：两帧皆零
  match parse_opus_packet(build_packet([0x02, 0])) {
    Ok(p) => {
      @test.assert_eq(p.frame_length(0), Some(0))
      @test.assert_eq(p.frame_length(1), Some(0))
    }
    Err(e) => @test.fail(e)
  }
  // [R4] n=1：没有首帧长字段
  match parse_opus_packet(build_packet([0x02])) {
    Ok(_) => @test.fail("expected [R4] error")
    Err(e) => if !e.contains("[R4]") { @test.fail("wrong error: \{e}") }
  }
  // [R4] n=2 且 N1=5 > 剩余 0
  match parse_opus_packet(build_packet([0x02, 5])) {
    Ok(_) => @test.fail("expected [R4] error")
    Err(e) => if !e.contains("[R4]") { @test.fail("wrong error: \{e}") }
  }
  // [R4] 首帧长需要第二字节但缺失
  match parse_opus_packet(build_packet([0x02, 252])) {
    Ok(_) => @test.fail("expected [R4] error")
    Err(e) => if !e.contains("[R4]") { @test.fail("wrong error: \{e}") }
  }
  // [R2] 第二帧（隐式）1276 字节
  let big = [0x02, 0]
  for _ in 0..<1276 {
    big.push(0)
  }
  match parse_opus_packet(build_packet(big)) {
    Ok(_) => @test.fail("expected [R2] error")
    Err(e) => if !e.contains("[R2]") { @test.fail("wrong error: \{e}") }
  }
}

///|
/// code 3 CBR：整除分帧、两种填充编码（含非零填充字节被接受）、
/// [R6] 四形态与 [R2]。
test "code 3 CBR：填充与 [R6]/[R2]" {
  // M=2、无填充，R=6 → 两帧各 3 字节。TOC=0x03，帧数字节 = 2<<2 = 0x08
  match parse_opus_packet(build_packet([0x03, 0x08, 3, 3, 3, 3, 3, 3])) {
    Ok(p) => {
      @test.assert_eq(p.frame_count, 2)
      @test.assert_eq(p.is_vbr, false)
      @test.assert_eq(p.padding_bytes, 0)
      @test.assert_eq(p.frame_length(0), Some(3))
      @test.assert_eq(p.frame_length(1), Some(3))
    }
    Err(e) => @test.fail(e)
  }
  // 单字节填充长度 4：帧数据 4 字节 + 尾部 4 字节填充（内容非零，解码端
  // 必须接受——§3.2.5）。帧数字节 = 2<<2|2(p位) = 0x0A
  let pad1 = [0x03, 0x0A, 4, 2, 2, 2, 2]
  for _ in 0..<4 {
    pad1.push(0xAB)
  }
  match parse_opus_packet(build_packet(pad1)) {
    Ok(p) => {
      @test.assert_eq(p.padding_bytes, 4)
      @test.assert_eq(p.frame_count, 2)
      @test.assert_eq(p.frame_length(0), Some(2))
      @test.assert_eq(p.frame_length(1), Some(2))
    }
    Err(e) => @test.fail(e)
  }
  // 双字节填充长度（RFC §3.2.5 例：255,0 → 填充 254 字节，P=256）。
  // 帧数字节 = 1<<2|2 = 0x06；R=2、M=1
  let two_pad = [0x03, 0x06, 0xFF, 0x00, 7, 8]
  for _ in 0..<254 {
    two_pad.push(0)
  }
  match parse_opus_packet(build_packet(two_pad)) {
    Ok(p) => {
      @test.assert_eq(p.padding_bytes, 254)
      @test.assert_eq(p.frame_count, 1)
      @test.assert_eq(p.frame_length(0), Some(2))
    }
    Err(e) => @test.fail(e)
  }
  // [R6] R=5 不是 M=2 的整数倍
  match parse_opus_packet(build_packet([0x03, 0x08, 1, 2, 3, 4, 5])) {
    Ok(_) => @test.fail("expected [R6] error")
    Err(e) => if !e.contains("[R6]") { @test.fail("wrong error: \{e}") }
  }
  // [R6] p=1 但缺失填充长度字节
  match parse_opus_packet(build_packet([0x03, 0x0A])) {
    Ok(_) => @test.fail("expected [R6] error")
    Err(e) => if !e.contains("[R6]") { @test.fail("wrong error: \{e}") }
  }
  // [R6] 填充长度第二字节缺失
  match parse_opus_packet(build_packet([0x03, 0x0A, 0xFF])) {
    Ok(_) => @test.fail("expected [R6] error")
    Err(e) => if !e.contains("[R6]") { @test.fail("wrong error: \{e}") }
  }
  // [R6] P=255 > N-2=2
  match parse_opus_packet(build_packet([0x03, 0x06, 0xFE])) {
    Ok(_) => @test.fail("expected [R6] error")
    Err(e) => if !e.contains("[R6]") { @test.fail("wrong error: \{e}") }
  }
  // [R2] M=1 的 CBR 隐式帧 1276 字节。帧数字节 = 1<<2 = 0x04
  let huge = [0x03, 0x04]
  for _ in 0..<1276 {
    huge.push(0)
  }
  match parse_opus_packet(build_packet(huge)) {
    Ok(_) => @test.fail("expected [R2] error")
    Err(e) => if !e.contains("[R2]") { @test.fail("wrong error: \{e}") }
  }
}

///|
/// code 3 VBR：混合单双字节帧长、M=1 边界；[R7] 两形态；
/// [R5] 零帧数与时长上限。
test "code 3 VBR：帧长与 [R5]/[R7]" {
  // M=3, v=1：帧数字节 = 3<<2|1 = 0x0D；显式长 [2,3]，末帧吃掉剩余 4 字节
  match
    parse_opus_packet(
      build_packet([0x03, 0x0D, 2, 3, 1, 1, 2, 2, 2, 3, 3, 3, 3]),
    ) {
    Ok(p) => {
      @test.assert_eq(p.frame_count, 3)
      @test.assert_eq(p.is_vbr, true)
      @test.assert_eq(p.frame_length(0), Some(2))
      @test.assert_eq(p.frame_length(1), Some(3))
      @test.assert_eq(p.frame_length(2), Some(4))
      @test.assert_eq(p.duration_48k(), 1440) // 3 × 480
    }
    Err(e) => @test.fail(e)
  }
  // M=2, v=1，显式长用双字节形式：N1 = 7*4+252 = 280，末帧 10 字节
  // 帧数字节 = 2<<2|1 = 0x09
  let dbl = [0x03, 0x09, 252, 7]
  for _ in 0..<280 {
    dbl.push(1)
  }
  for _ in 0..<10 {
    dbl.push(2)
  }
  match parse_opus_packet(build_packet(dbl)) {
    Ok(p) => {
      @test.assert_eq(p.frame_length(0), Some(280))
      @test.assert_eq(p.frame_length(1), Some(10))
    }
    Err(e) => @test.fail(e)
  }
  // M=1, v=1：没有显式长，整段内容即唯一一帧
  // 帧数字节 = 1<<2|1 = 0x05
  match parse_opus_packet(build_packet([0x03, 0x05, 9, 8, 7, 6, 5])) {
    Ok(p) => {
      @test.assert_eq(p.frame_count, 1)
      @test.assert_eq(p.is_vbr, true)
      @test.assert_eq(p.frame_length(0), Some(5))
    }
    Err(e) => @test.fail(e)
  }
  // [R7] 显式长之和 200 > 剩余 50
  let over = [0x03, 0x0D, 100, 100]
  for _ in 0..<50 {
    over.push(0)
  }
  match parse_opus_packet(build_packet(over)) {
    Ok(_) => @test.fail("expected [R7] error")
    Err(e) => if !e.contains("[R7]") { @test.fail("wrong error: \{e}") }
  }
  // [R7] 读第二条显式长时已无字节
  match parse_opus_packet(build_packet([0x03, 0x0D, 5])) {
    Ok(_) => @test.fail("expected [R7] error")
    Err(e) => if !e.contains("[R7]") { @test.fail("wrong error: \{e}") }
  }
  // [R5] M=0（帧数字节 0x00）
  match parse_opus_packet(build_packet([0x03, 0x00])) {
    Ok(_) => @test.fail("expected [R5] error")
    Err(e) => if !e.contains("[R5]") { @test.fail("wrong error: \{e}") }
  }
  // [R5] config 0（10 ms）× 13 帧 = 6240 采样 > 5760（120 ms）
  // 帧数字节 = 13<<2 = 0x34
  match parse_opus_packet(build_packet([0x03, 0x34])) {
    Ok(_) => @test.fail("expected [R5] error")
    Err(e) => if !e.contains("[R5]") { @test.fail("wrong error: \{e}") }
  }
  // [R5] config 16（CELT 2.5 ms）× 49 帧 = 5880 > 5760
  // TOC = 16<<3|3 = 0x83，帧数字节 = 49<<2 = 0xC4
  match parse_opus_packet(build_packet([0x83, 0xC4])) {
    Ok(_) => @test.fail("expected [R5] error")
    Err(e) => if !e.contains("[R5]") { @test.fail("wrong error: \{e}") }
  }
  // 边界合法：config 16 × 48 帧 = 5760 采样，恰好 120 ms
  // 帧数字节 = 48<<2 = 0xC0，R=48、M=48 → 每帧 1 字节
  let maxd = [0x83, 0xC0]
  for _ in 0..<48 {
    maxd.push(0)
  }
  match parse_opus_packet(build_packet(maxd)) {
    Ok(p) => {
      @test.assert_eq(p.frame_count, 48)
      @test.assert_eq(p.duration_48k(), 5760)
      @test.assert_eq(p.frame_length(47), Some(1))
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// 取第 i 帧载荷，缺失即测试失败（测试内助手）。
fn pkt_frame(p : OpusPacket, i : Int) -> Bytes raise {
  match p.frame_data(i) {
    Some(b) => b
    None => @test.fail("frame \{i} 载荷缺失")
  }
}

///|
/// 两段字节逐字节比对（测试内助手）。
fn pkt_bytes_eq(a : Bytes, b : Bytes, tag : String) -> Unit raise {
  if a.length() != b.length() {
    @test.fail("\{tag}: 长度 \{a.length()} != \{b.length()}")
  }
  for i in 0..<a.length() {
    if a.unsafe_get(i) != b.unsafe_get(i) {
      @test.fail("\{tag}: 字节 \{i} 不等")
    }
  }
}

///|
/// frame_data：四种打包的帧载荷切片与手工预期逐字节一致，
/// 且拼接恰为帧数据区（越过 TOC/帧长/填充头）。
test "frame_data：四种打包的帧载荷切片" {
  // code 0：TOC 之后全部是一帧
  match parse_opus_packet(build_packet([0x60, 10, 20, 30])) {
    Ok(p) => {
      pkt_bytes_eq(pkt_frame(p, 0), b"\x0a\x14\x1e", "code0 f0")
      if p.frame_data(1) != None {
        @test.fail("code0 越界应为 None")
      }
    }
    Err(e) => @test.fail(e)
  }
  // code 1：两帧等长，各 (N-1)/2
  match parse_opus_packet(build_packet([0x01, 1, 2, 3, 4, 5, 6])) {
    Ok(p) => {
      pkt_bytes_eq(pkt_frame(p, 0), b"\x01\x02\x03", "code1 f0")
      pkt_bytes_eq(pkt_frame(p, 1), b"\x04\x05\x06", "code1 f1")
    }
    Err(e) => @test.fail(e)
  }
  // code 2：首帧显式 3 字节，余下归第二帧
  match parse_opus_packet(build_packet([0x02, 3, 10, 11, 12, 20, 21, 22])) {
    Ok(p) => {
      pkt_bytes_eq(pkt_frame(p, 0), b"\x0a\x0b\x0c", "code2 f0")
      pkt_bytes_eq(pkt_frame(p, 1), b"\x14\x15\x16", "code2 f1")
    }
    Err(e) => @test.fail(e)
  }
  // code 3 CBR（fcb=0x08：m=2）：载荷均分
  match parse_opus_packet(build_packet([0x03, 0x08, 7, 7, 7, 7])) {
    Ok(p) => {
      pkt_bytes_eq(pkt_frame(p, 0), b"\x07\x07", "code3c f0")
      pkt_bytes_eq(pkt_frame(p, 1), b"\x07\x07", "code3c f1")
    }
    Err(e) => @test.fail(e)
  }
  // code 3 VBR+填充（fcb=0x0B：v=1,p=1,m=2）：pad 头 1、首帧显式 3，
  // 帧数据区起点越过全部头部，末尾 1 字节填充不入载荷
  match
    parse_opus_packet(
      build_packet([0x03, 0x0B, 1, 3, 10, 20, 30, 40, 50, 60, 99]),
    ) {
    Ok(p) => {
      pkt_bytes_eq(pkt_frame(p, 0), b"\x0a\x14\x1e", "code3v f0")
      pkt_bytes_eq(pkt_frame(p, 1), b"\x28\x32\x3c", "code3v f1")
      if p.frame_data(2) != None {
        @test.fail("code3 越界应为 None")
      }
      if p.frame_data(-1) != None {
        @test.fail("负索引应为 None")
      }
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// 访问器边界：frame_length(i) 越界返回 None。
test "访问器边界" {
  match parse_opus_packet(build_packet([0xFC, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])) {
    Ok(p) => {
      @test.assert_eq(p.frame_length(0), Some(10))
      @test.assert_eq(p.frame_length(1), None)
      @test.assert_eq(p.frame_length(-1), None)
      @test.assert_eq(p.padding_bytes, 0)
      @test.assert_eq(p.duration_48k(), 960)
    }
    Err(e) => @test.fail(e)
  }
}
