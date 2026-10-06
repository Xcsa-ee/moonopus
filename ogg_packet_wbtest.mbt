// Whitebox tests for ogg_packet.mbt.

///|
/// 收集流内全部逻辑包（页级解析 + 重组，不做流级规则校验），
/// 供头部解析与组装单测复用。
fn stream_packets(data : Bytes) -> Result[Array[Bytes], String] {
  let packets : Array[Bytes] = []
  let mut offset = 0
  let assembler = PacketAssembler::new()
  while offset < data.length() {
    let page = match OggPage::parse(data, offset) {
      Ok(p) => p
      Err(e) => return Err(e)
    }
    let size = page.total_size()
    for pkt in assembler.push_page(page) {
      packets.push(pkt)
    }
    offset += size
  }
  Ok(packets)
}

///|
/// 常规流：两个头包 + 三个音频包按序产出，音频包字节精确。
test "SIMPLE：5 个逻辑包按序组装" {
  match stream_packets(FIX_SIMPLE) {
    Ok(all) => {
      @test.assert_eq(all.length(), 5)
      @test.assert_eq(all[0].length(), 19) // OpusHead
      @test.assert_eq(all[2], b"\xf8\xff\xfe")
      @test.assert_eq(all[3], b"ABC")
      @test.assert_eq(all[4], b"123456")
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// 跨页包：300 字节音频包在两页间被切成 255 + 45，
/// 重组结果必须与构造模式逐字节一致。
test "SPANNED：300 字节包跨页重组" {
  match stream_packets(FIX_SPANNED) {
    Ok(all) => {
      @test.assert_eq(all.length(), 4)
      let a = all[2]
      @test.assert_eq(a.length(), 300)
      let mut bad = -1
      for i in 0..<300 {
        if a.unsafe_get(i).to_int() != ((i * 7 + 3) & 0xFF) {
          bad = i
          break
        }
      }
      @test.assert_eq(bad, -1)
      @test.assert_eq(all[3], b"XYZXYZ")
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// 多包页：同页两个音频包都完整产出。
test "FAM1：多包页组装" {
  match stream_packets(FIX_FAM1) {
    Ok(all) => {
      @test.assert_eq(all.length(), 4) // head + tags + "XY" + "Z"
      @test.assert_eq(all[2], b"XY")
      @test.assert_eq(all[3], b"Z")
    }
    Err(e) => @test.fail(e)
  }
}
