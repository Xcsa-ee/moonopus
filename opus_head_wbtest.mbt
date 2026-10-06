// Whitebox tests for opus_head.mbt（OpusHead / OpusTags 解析）。

///|
/// 取流的全部逻辑包；页级非法样例不进入本文件的用例（流级在 opus_stream 测）。
fn packets_of(blob : Bytes) -> Array[Bytes] {
  match stream_packets(blob) {
    Ok(p) => p
    Err(_) => []
  }
}

///|
/// family 0 单声道：固定 19 字节、无映射表，各字段语义正确。
test "OpusHead：family 0 单声道" {
  match parse_opus_head(packets_of(FIX_SIMPLE)[0]) {
    Ok(h) => {
      @test.assert_eq(h.channels, 1)
      @test.assert_eq(h.pre_skip, 312)
      @test.assert_eq(h.input_sample_rate, 48000U)
      @test.assert_eq(h.output_gain, 0)
      @test.assert_eq(h.mapping_family, 0)
      @test.assert_eq(h.stream_count, 1)
      @test.assert_eq(h.coupled_count, 0)
      @test.assert_eq(h.channel_mapping.length(), 0)
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// family 1 六声道：映射表 N=4/M=2/下标 0..5，负增益按 Q7.8 有符号解析。
test "OpusHead：family 1 六声道与映射表" {
  match parse_opus_head(packets_of(FIX_FAM1)[0]) {
    Ok(h) => {
      @test.assert_eq(h.channels, 6)
      @test.assert_eq(h.pre_skip, 0)
      @test.assert_eq(h.input_sample_rate, 44100U)
      @test.assert_eq(h.output_gain, -12)
      @test.assert_eq(h.mapping_family, 1)
      @test.assert_eq(h.stream_count, 4)
      @test.assert_eq(h.coupled_count, 2)
      @test.assert_eq(h.channel_mapping.length(), 6)
      @test.assert_eq(h.channel_mapping[5].to_int(), 5)
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// vendor + UTF-8 comments 完整解码（含多字节中文）。
test "OpusTags：vendor 与 UTF-8 comments" {
  match parse_opus_tags(packets_of(FIX_SIMPLE)[1]) {
    Ok(t) => {
      @test.assert_eq(t.vendor, "moonopus test encoder")
      @test.assert_eq(t.comments.length(), 2)
      @test.assert_eq(t.comments[0], "TITLE=moonopus 测试")
      @test.assert_eq(t.comments[1], "DATE=2026")
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// 第二个流的 tags 同样正确。
test "OpusTags：FAM1 流" {
  match parse_opus_tags(packets_of(FIX_FAM1)[1]) {
    Ok(t) => {
      @test.assert_eq(t.vendor, "fam1-encoder")
      @test.assert_eq(t.comments.length(), 1)
      @test.assert_eq(t.comments[0], "CHANNELS=6")
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// §5.1 / §5.1.1 各条硬规则：非法样例必须被拒且错误指向对应规则。
test "非法 OpusHead：逐规则拒绝" {
  let cases = [
    (FIX_HEAD_BAD_MAGIC, "OpusHead magic"),
    (FIX_HEAD_VERSION, "version"),
    (FIX_HEAD_CHANNELS0, "channel count"),
    (FIX_FAM0_CHANNELS3, "family 0"),
    (FIX_FAM0_EXTRA, "forbids"),
    (FIX_HEAD_SHORT, "too short"),
    (FIX_FAM1_CHANNELS9, "family 1"),
    (FIX_FAM1_STREAM0, "stream count"),
    (FIX_FAM1_COUPLED_GT, "coupled count"),
    (FIX_FAM1_INDEX_OOB, "mapping index"),
    (FIX_FAM1_LEN, "table length"),
  ]
  for (blob, hint) in cases {
    match parse_opus_head(packets_of(blob)[0]) {
      Ok(_) => @test.fail("expected error containing \{hint}")
      Err(e) => if !e.contains(hint) { @test.fail("error \{e} lacks \{hint}") }
    }
  }
}

///|
/// §5.2 各条硬规则：magic、vendor 越界、尾部字节、计数爆炸。
test "非法 OpusTags：逐规则拒绝" {
  let cases = [
    (FIX_TAGS_BAD_MAGIC, "OpusTags magic"),
    (FIX_TAGS_VENDOR_LEN, "vendor string"),
    (FIX_TAGS_TRAILING, "trailing"),
    (FIX_TAGS_COUNT, "comment count"),
  ]
  for (blob, hint) in cases {
    match parse_opus_tags(packets_of(blob)[1]) {
      Ok(_) => @test.fail("expected error containing \{hint}")
      Err(e) => if !e.contains(hint) { @test.fail("error \{e} lacks \{hint}") }
    }
  }
}
