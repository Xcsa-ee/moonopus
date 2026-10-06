// Whitebox tests for ogg_crc.mbt.
// 金标值由 tools/gen_fixtures.py 的独立实现计算，经双算法交叉验证并以
// 真实 muxer 产出的 Ogg 文件页 CRC 锚定（见 fixtures_crc_wbtest.mbt 头注释）。

///|
/// 金标值：独立 Python 实现与本实现对同一输入给出同一结果。
test "CRC 金标值" {
  @test.assert_eq(ogg_crc32(b""), FIX_CRC_EMPTY)
  @test.assert_eq(ogg_crc32(b"OggS"), FIX_CRC_OGGS)
  @test.assert_eq(ogg_crc32(b"123456789"), FIX_CRC_CHECK)
}

///|
/// 分段增量累加必须与一次性整段计算等价（页校验走的就是分段路径）。
test "增量累加与整段计算等价" {
  let split = 50
  let mut acc = ogg_crc32_update(0U, FIX_SIMPLE, 0, split)
  acc = ogg_crc32_update(acc, FIX_SIMPLE, split, FIX_SIMPLE.length() - split)
  @test.assert_eq(acc, ogg_crc32(FIX_SIMPLE))
}
