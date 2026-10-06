// Whitebox tests for opus_stream.mbt（open_opus 流级页序规则与总入口）。

///|
/// 三个合法样例端到端打开：字段、元数据、音频包逐项核对。
test "open_opus：三个合法样例" {
  match open_opus(FIX_SIMPLE) {
    Ok(s) => {
      @test.assert_eq(s.channels(), 1)
      @test.assert_eq(s.pre_skip(), 312)
      @test.assert_eq(s.input_sample_rate(), 48000U)
      @test.assert_eq(s.output_gain(), 0)
      @test.assert_eq(s.mapping_family(), 0)
      @test.assert_eq(s.stream_count(), 1)
      @test.assert_eq(s.coupled_count(), 0)
      @test.assert_eq(s.channel_mapping().length(), 0)
      @test.assert_eq(s.vendor(), "moonopus test encoder")
      @test.assert_eq(s.comments().length(), 2)
      @test.assert_eq(s.comments()[0], "TITLE=moonopus 测试")
      @test.assert_eq(s.packet_count(), 3)
      match s.packet(0) {
        Some(b) => @test.assert_eq(b, b"\xf8\xff\xfe")
        None => @test.fail("missing packet 0")
      }
      match s.packet(1) {
        Some(b) => @test.assert_eq(b, b"ABC")
        None => @test.fail("missing packet 1")
      }
      match s.packet(3) {
        Some(_) => @test.fail("packet 3 must not exist")
        None => ()
      }
    }
    Err(e) => @test.fail(e)
  }
  match open_opus(FIX_SPANNED) {
    Ok(s) => {
      @test.assert_eq(s.packet_count(), 2)
      match s.packet(0) {
        Some(a) => {
          @test.assert_eq(a.length(), 300)
          let mut bad = -1
          for i in 0..<300 {
            if a.unsafe_get(i).to_int() != ((i * 7 + 3) & 0xFF) {
              bad = i
              break
            }
          }
          @test.assert_eq(bad, -1)
        }
        None => @test.fail("missing spanned packet")
      }
      match s.packet(1) {
        Some(b) => @test.assert_eq(b, b"XYZXYZ")
        None => @test.fail("missing tail packet")
      }
    }
    Err(e) => @test.fail(e)
  }
  // 缺 EOS 的整页截断流按 §4 容忍
  match open_opus(FIX_FAM1) {
    Ok(s) => {
      @test.assert_eq(s.channels(), 6)
      @test.assert_eq(s.output_gain(), -12)
      @test.assert_eq(s.mapping_family(), 1)
      @test.assert_eq(s.stream_count(), 4)
      @test.assert_eq(s.coupled_count(), 2)
      @test.assert_eq(s.channel_mapping().length(), 6)
      @test.assert_eq(s.vendor(), "fam1-encoder")
      @test.assert_eq(s.packet_count(), 2)
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// 空输入：任何页都没有，直接报缺 OpusHead。
test "open_opus：空输入被拒" {
  match open_opus(b"") {
    Ok(_) => @test.fail("expected error on empty input")
    Err(e) => if !e.contains("OpusHead") { @test.fail("wrong error: \{e}") }
  }
}

///|
/// 28 个非法样例逐规则拒绝：每条错误必须指向被违反的那条规则，
/// 而不是碰巧在更早的环节失败。
test "open_opus：28 个非法样例逐规则拒绝" {
  let cases = [
    // 页级与流级页序
    (FIX_BAD_MAGIC, "bad magic"),
    (FIX_BAD_CRC, "CRC"),
    (FIX_TRUNCATED, "truncated"),
    (FIX_ID_GRANULE, "ID header page"),
    (FIX_NO_BOS, "BOS"),
    (FIX_SERIAL_MISMATCH, "serial"),
    (FIX_SEQ_GAP, "sequence"),
    (FIX_SPURIOUS_CONTINUED, "pending"),
    (FIX_TAGS_GRANULE, "comment header page"),
    (FIX_HEAD_NOT_ALONE, "alone"),
    (FIX_PAGE_AFTER_EOS, "end of stream"),
    (FIX_CHAINED, "chained"),
    (FIX_MISSING_CONTINUED, "continuation"),
    // OpusHead §5.1 / §5.1.1
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
    // OpusTags §5.2
    (FIX_TAGS_BAD_MAGIC, "OpusTags magic"),
    (FIX_TAGS_VENDOR_LEN, "vendor string"),
    (FIX_TAGS_TRAILING, "trailing"),
    (FIX_TAGS_COUNT, "comment count"),
  ]
  for (blob, hint) in cases {
    match open_opus(blob) {
      Ok(_) => @test.fail("expected error containing \{hint}")
      Err(e) => if !e.contains(hint) { @test.fail("error \{e} lacks \{hint}") }
    }
  }
}
