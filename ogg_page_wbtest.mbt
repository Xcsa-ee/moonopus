// Whitebox tests for ogg_page.mbt.
// 页样例全部由 tools/gen_fixtures.py 独立构造（CRC 真实计算），与本实现
// 交叉验证；非法样例每条对应一条 RFC 7845 页级规则。

///|
/// 顺序解析流内全部页（任一页失败即返回 Err）。
fn walk_pages(data : Bytes) -> Result[Array[OggPage], String] {
  let pages : Array[OggPage] = []
  let mut offset = 0
  while offset < data.length() {
    let page = match OggPage::parse(data, offset) {
      Ok(p) => p
      Err(e) => return Err(e)
    }
    let size = page.total_size()
    pages.push(page)
    offset += size
  }
  Ok(pages)
}

///|
/// 常规三页流：BOS/头页 granule 0、OpusHead 独占首页、EOS 页字段正确。
test "SIMPLE：三页结构与字段" {
  match walk_pages(FIX_SIMPLE) {
    Ok(pages) => {
      @test.assert_eq(pages.length(), 3)
      @test.assert_eq(pages[0].header_type, 0x02)
      @test.assert_eq(pages[0].granule_position, 0L)
      @test.assert_eq(pages[0].page_sequence, 0U)
      @test.assert_eq(pages[0].n_segments, 1)
      @test.assert_eq(pages[0].segment_len(0), 19)
      @test.assert_eq(pages[1].granule_position, 0L)
      @test.assert_eq(pages[2].header_type, 0x04)
      @test.assert_eq(pages[2].granule_position, 2880L)
      @test.assert_eq(pages[2].n_segments, 3)
      @test.assert_eq(pages[2].segment_len(0), 3)
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// §4：完全被单个未完 packet 占据的页 granule 取 -1；
/// CONTINUED|EOS 组合页标志保留。
test "SPANNED：跨页样例的页级字段" {
  match walk_pages(FIX_SPANNED) {
    Ok(pages) => {
      @test.assert_eq(pages.length(), 4)
      @test.assert_eq(pages[2].granule_position, -1L)
      @test.assert_eq(pages[2].n_segments, 1)
      @test.assert_eq(pages[2].segment_len(0), 255)
      @test.assert_eq(pages[3].header_type, 0x05)
    }
    Err(e) => @test.fail(e)
  }
}

///|
/// 页级三个否定规则：magic、CRC、截断（其余规则在 open_opus 流级测）。
test "页级非法样例被拒" {
  match OggPage::parse(FIX_BAD_MAGIC, 0) {
    Ok(_) => @test.fail("expected magic error")
    Err(e) => if !e.contains("bad magic") { @test.fail("wrong error: \{e}") }
  }
  match OggPage::parse(FIX_BAD_CRC, 0) {
    Ok(_) => @test.fail("expected CRC error")
    Err(e) => if !e.contains("CRC") { @test.fail("wrong error: \{e}") }
  }
  match walk_pages(FIX_TRUNCATED) {
    Ok(_) => @test.fail("expected truncation error")
    Err(e) => if !e.contains("truncated") { @test.fail("wrong error: \{e}") }
  }
}
