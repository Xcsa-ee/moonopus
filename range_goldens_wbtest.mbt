// 由 tools/gen_range_goldens.py 生成，请勿手改。
//
// 范围解码器（RFC 6716 §4.1）金标：比特流与逐轨迹期望值由本脚本内
// 独立实现的参考解码端算出（不同语言、不同实现路径），MoonBit 解码端
// 重放同一操作序列后逐项比对 (sym, rng, val, tell, tell_frac)。
//
// 端到端正确性另由 M3b 的真实 libopus 比特流 PCM 差分兜底——任何
// 熵解码错误都会让解出的 PCM 完全失真。

///|

///|
const RANGE_UNIFORM16_BITS : Bytes = b"\xfd\x29\x92\x93\x64\x77\x10\x37\x05\x78\x3b\x29\x83\xec\xda\xbc\x6f\x02\x2b\x53\xff\x44\x6c\x41\x55\xea\x1e\x0e\x31\xdf\x20\x5d\x8b\x3f\xc6\xf8\x74\x51\xb6\x74\x13\xfd\x00\x7d\x6b\x32\x3f\x14\xd2\xfe\x56\x14\xda\xb3\x3b\xa9\x13\x9d\x96\xf7\x5e\xfe\x4e\x17"

///|
fn play_uniform16(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_UNIFORM16_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_ctx([4, 4, 4, 4], 3, 536870912L, 23803574L, 3, 24)
  dec.expect_ctx([4, 4, 4, 4], 3, 134217728L, 23803574L, 5, 40)
  dec.expect_ctx([4, 4, 4, 4], 3, 33554432L, 23803574L, 7, 56)
  dec.expect_ctx([4, 4, 4, 4], 1, 2147483648L, 1798747725L, 9, 72)
  dec.expect_ctx([4, 4, 4, 4], 0, 536870912L, 1798747725L, 11, 88)
  dec.expect_ctx([4, 4, 4, 4], 0, 134217728L, 1798747725L, 13, 104)
  dec.expect_ctx([4, 4, 4, 4], 0, 33554432L, 1798747725L, 15, 120)
  dec.expect_ctx([4, 4, 4, 4], 0, 2147483648L, 917917124L, 17, 136)
  dec.expect_ctx([4, 4, 4, 4], 2, 536870912L, 381046212L, 19, 152)
  dec.expect_ctx([4, 4, 4, 4], 1, 134217728L, 112610756L, 21, 168)
  dec.expect_ctx([4, 4, 4, 4], 0, 33554432L, 112610756L, 23, 184)
  dec.expect_ctx([4, 4, 4, 4], 0, 2147483648L, 911066231L, 25, 200)
  dec.expect_ctx([4, 4, 4, 4], 2, 536870912L, 374195319L, 27, 216)
  dec.expect_ctx([4, 4, 4, 4], 1, 134217728L, 105759863L, 29, 232)
  dec.expect_ctx([4, 4, 4, 4], 0, 33554432L, 105759863L, 31, 248)
  dec.expect_ctx([4, 4, 4, 4], 0, 2147483648L, 1304721380L, 33, 264)
}

///|
const RANGE_BITLOGP_BITS : Bytes = b"\x42\x39\xed\x11\x36\xfc\x75\xf7\x9a\x48\x24\x25\x21\xe3\x3a\xee\x5a\x6f\x82\x35\x26\xd4\x5d\x0b\xce\x04\xea\x37\xbe\x3a\xf1\x21\xdd\x56\xa5\xfb\x74\x26\xd3\xf9\xe8\xb7\x1b\x94\xd4\x20\x6b\xe3"

///|
fn play_bitlogp(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_BITLOGP_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_bit(1, 0, 1073741824L, 1591937399L, 2, 16)
  dec.expect_bit(2, 0, 805306368L, 1591937399L, 3, 20)
  dec.expect_bit(3, 0, 704643072L, 1591937399L, 3, 21)
  dec.expect_bit(4, 0, 660602880L, 1591937399L, 3, 22)
  dec.expect_bit(5, 0, 639959040L, 1591937399L, 3, 22)
  dec.expect_bit(6, 0, 629959680L, 1591937399L, 3, 23)
  dec.expect_bit(7, 0, 625038120L, 1591937399L, 3, 23)
  dec.expect_bit(8, 0, 622596565L, 1591937399L, 3, 23)
  dec.expect_bit(1, 0, 311298283L, 1591937399L, 4, 31)
  dec.expect_bit(3, 0, 272385998L, 1591937399L, 4, 32)
  dec.expect_bit(5, 0, 263873936L, 1591937399L, 5, 33)
  dec.expect_bit(7, 0, 261812421L, 1591937399L, 5, 33)
  dec.expect_bit(2, 0, 196359316L, 1591937399L, 5, 36)
  dec.expect_bit(4, 0, 184086859L, 1591937399L, 5, 37)
  dec.expect_bit(6, 0, 181210502L, 1591937399L, 5, 37)
  dec.expect_bit(8, 0, 180502649L, 1591937399L, 5, 37)
  dec.expect_bit(3, 0, 157939818L, 1591937399L, 5, 39)
  dec.expect_bit(3, 0, 138197341L, 1591937399L, 5, 40)
  dec.expect_bit(1, 0, 69098671L, 1591937399L, 6, 48)
  dec.expect_bit(8, 0, 68828755L, 1591937399L, 6, 48)
}

///|
const RANGE_ICDF8_BITS : Bytes = b"\x2d\x2a\xcf\x91\xf3\xdd\x3a\xe2\x45\xf7\x07\xfd\x03\xe9\x4e\xe0\xda\xb6\x32\x50\x9d\x06\xd5\x13\xdc\x0f\x88\x90\xea\x7c\x39\x48\xcc\x22\x5b\xdc\xbb\x0c\x8a\xf8\x6c\xd2\x20\xb0\x53\xd9\x6e\xda"

///|
fn play_icdf8(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_ICDF8_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_icdf(8, 0, 469762048L, 1768593463L, 4, 26)
  dec.expect_icdf(8, 0, 102760448L, 1768593463L, 6, 44)
  dec.expect_icdf(8, 0, 22478848L, 1768593463L, 8, 61)
  dec.expect_icdf(8, 0, 1258815488L, 1788360454L, 10, 79)
  dec.expect_icdf(8, 0, 275365888L, 1788360454L, 12, 96)
  dec.expect_icdf(8, 0, 60236288L, 1788360454L, 15, 114)
  dec.expect_icdf(8, 0, 13176688L, 1788360454L, 17, 131)
  dec.expect_icdf(8, 0, 737916928L, 406259217L, 19, 149)
  dec.expect_icdf(8, 2, 144124400L, 118010417L, 21, 168)
  dec.expect_icdf(8, 0, 31527400L, 118010417L, 24, 185)
  dec.expect_icdf(8, 0, 1765580800L, 145895778L, 26, 203)
  dec.expect_icdf(8, 4, 275872000L, 145895778L, 28, 224)
  dec.expect_icdf(8, 2, 53881250L, 38133278L, 31, 243)
  dec.expect_icdf(8, 1, 10523650L, 6562328L, 33, 262)
  dec.expect_icdf(8, 1, 526182400L, 101408910L, 36, 281)
  dec.expect_icdf(8, 3, 123324000L, 19192910L, 38, 297)
}

///|
const RANGE_UINT_BITS : Bytes = b"\xf1\x44\x74\x90\xf9\x31\x85\xd8\x9f\x27\xd5\x86\xc8\x0f\x52\x8a\x4a\x48\x76\x56\xef\x87\x7a\xf1\x7d\x72\xdb\xc2\x3e\x00\xed\x38\xe6\x4e\x2a\xa1\xcb\x00\x16\x69\x77\x26\x65\x4c\xba\xe0\x46\x5c\xcc\x00\x04\x67\x7c\x12\x3b\xc0\x1e\xd8\x7e\x72\x38\xe1\x42\x95"

///|
fn play_uint(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_UINT_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_uint(16, 15, 134217728L, 123585975L, 5, 40)
  dec.expect_uint(100, 7, 343597312L, 27057027L, 12, 94)
  dec.expect_uint(10000, 9237, 560260352L, 203474791L, 25, 200)
  dec.expect_uint(70000, 44810, 1046909696L, 790971453L, 42, 329)
  dec.expect_uint(65536, 16066, 1046909696L, 435120659L, 58, 457)
}

///|
const RANGE_MIXED_BITS : Bytes = b"\xcd\xbb\xbf\x62\xde\x4b\x7f\xae\xdc\x77\x6e\x0e\x9c\x0d\x6a\x04\x75\x68\xd3\x71\x95\x75\x22\x3e\x44\x0f\xaa\x36\xf1\xc5\xef\x21\xff\x2e\xfd\x91\x5a\x8b\x3a\xb8\x23\x41\x01\xe5\x03\x32\xc8\x37\x9d\x4e\x27\xfc\x28\x85\x7e\xc5\x26\xb0\x0c\x50\xcb\xe6\x96\xae\x95\x45\x21\x91\x3e\xa5\x06\x60\x31\x76\x29\x40\xe3\x10\xa5\xa4"

///|
fn play_mixed(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_MIXED_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_bit(3, 0, 1879048192L, 421666894L, 2, 10)
  dec.expect_bit(3, 0, 1644167168L, 421666894L, 2, 12)
  dec.expect_icdf(8, 3, 385351680L, 164765774L, 4, 28)
  dec.expect_icdf(8, 2, 75264000L, 14237774L, 6, 47)
  dec.expect_icdf(8, 3, 17640000L, 2477774L, 8, 64)
  dec.expect_icdf(8, 4, 705597440L, 634310288L, 11, 85)
  dec.expect_icdf(8, 0, 154349440L, 634310288L, 13, 103)
  dec.expect_icdf(8, 0, 33764040L, 634310288L, 15, 120)
  dec.expect_icdf(8, 0, 1890826240L, 1322160346L, 18, 138)
  dec.expect_uint(32, 9, 59088320L, 22217306L, 23, 178)
  dec.expect_bit(8, 0, 58857507L, 22217306L, 23, 178)
  dec.expect_bin(4, 0, 55178913L, 22217306L, 23, 179)
  dec.expect_ctx([8, 8, 8, 8], 2, 13794728L, 8422578L, 25, 195)
  dec.expect_ctx([8, 8, 8, 8], 1, 882862080L, 390455872L, 27, 211)
  dec.expect_ctx([8, 8, 8, 8], 2, 220715520L, 169740352L, 29, 227)
  dec.expect_ctx([8, 8, 8, 8], 0, 55178880L, 169740352L, 31, 243)
}

///|
const RANGE_RANDOM300_BITS : Bytes = b"\x60\x5e\x03\x80\xb5\xd5\xd2\xf8\x03\xa7\x7f\x83\xbe\xa9\x4b\x58\x54\xbf\xfc\xb5\x9e\x45\x4c\xd9\x55\x3d\x61\x24\x36\xfd\x7d\x19\xcf\xdd\x1d\x60\x28\x38\xa8\xdc\x71\x87\x51\xb5\xc5\xe1\x91\xb5\x3d\xeb\x3e\xcc\x19\x60\x2c\x66\x50\x78\x0f\x80\xa6\x26\x39\xee\x5b\x39\xb1\x88\x52\x1b\x8e\x06\x56\x46\xfb\x84\x44\x62\x98\xab\xe0\xfa\x22\x84\x69\x7e\x6b\x62\x88\x50\xb8\xd0\xb8\x1d\xf9\xee\xe9\x77\xf1\x1d\xfc\x8c\xf4\x8f\x6d\xd1\x5c\xeb\x04\x0d\xae\x1f\x72\xeb\x75\x14\xa0\xbc\xbc\xa2\xfa\xff\xd6\x4d\xa6\xf4\xf4\x2e"

///|
fn play_random300(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_RANDOM300_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_uint(1000, 378, 8589934L, 7656869L, 11, 88)
  dec.expect_bit(6, 0, 8455717L, 7656869L, 11, 88)
  dec.expect_bin(4, 0, 2029372160L, 1960158629L, 12, 89)
  dec.expect_bit(7, 0, 2013517690L, 1960158629L, 12, 89)
  dec.expect_uint(100, 2, 20135176L, 7046557L, 18, 142)
  dec.expect_bit(1, 1, 10067588L, 7046557L, 19, 150)
  dec.expect_bin(7, 0, 9988935L, 7046557L, 19, 150)
  dec.expect_bit(2, 0, 1917875712L, 1803918613L, 20, 154)
  dec.expect_bit(8, 0, 1910384010L, 1803918613L, 20, 154)
  dec.expect_bin(3, 0, 1671586009L, 1803918613L, 20, 155)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    0,
    104474134L,
    1803918613L,
    24,
    187,
  )
  dec.expect_bin(2, 0, 78355601L, 1803918613L, 24, 191)
  dec.expect_bit(5, 0, 75906989L, 1803918613L, 24, 191)
  dec.expect_uint(10, 0, 1943220992L, 94180630L, 28, 218)
  dec.expect_bin(6, 0, 1912858164L, 94180630L, 28, 218)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 7, 239107270L, 94180630L, 31, 242)
  dec.expect_uint(5, 3, 47821454L, 46359176L, 33, 260)
  dec.expect_bin(4, 0, 44832614L, 46359176L, 33, 261)
  dec.expect_bit(1, 0, 22416307L, 46359176L, 34, 269)
  dec.expect_bit(5, 0, 21715798L, 46359176L, 34, 270)
  dec.expect_bin(6, 0, 21376489L, 46359176L, 34, 270)
  dec.expect_bit(1, 0, 10688245L, 46359176L, 35, 278)
  dec.expect_uint(65536, 11, 10750720L, 1130530947L, 51, 406)
  dec.expect_bit(4, 0, 10078800L, 1130530947L, 51, 406)
  dec.expect_bit(4, 0, 9448875L, 1130530947L, 51, 407)
  dec.expect_bit(2, 0, 1814184192L, 1653113854L, 52, 410)
  dec.expect_uint(65536, 5693, 1814184192L, 492229932L, 68, 538)
  dec.expect_bit(3, 0, 1587411168L, 492229932L, 68, 540)
  dec.expect_bit(5, 0, 1537804569L, 492229932L, 68, 540)
  dec.expect_bit(6, 0, 1513776373L, 492229932L, 68, 541)
  dec.expect_bit(2, 0, 1135332280L, 492229932L, 68, 544)
  dec.expect_bin(8, 0, 1130897389L, 492229932L, 68, 544)
  dec.expect_uint(1000, 565, 1158038784L, 942673984L, 78, 624)
  dec.expect_ctx([4, 4, 4, 4], 0, 289509696L, 942673984L, 80, 640)
  dec.expect_bit(7, 0, 287247902L, 942673984L, 80, 640)
  dec.expect_bit(2, 0, 215435927L, 942673984L, 81, 643)
  dec.expect_uint(65536, 111, 215474432L, 806371390L, 97, 771)
  dec.expect_uint(65536, 218, 215474432L, 272645664L, 113, 899)
  dec.expect_bin(2, 0, 161605824L, 272645664L, 113, 902)
  dec.expect_bit(6, 0, 159080733L, 272645664L, 113, 903)
  dec.expect_uint(10, 0, 15908076L, 272645664L, 117, 929)
  dec.expect_uint(100, 0, 40743936L, 1077813419L, 123, 982)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    0,
    651902976L,
    1042328410L,
    127,
    1014,
  )
  dec.expect_bin(4, 0, 611159040L, 1042328410L, 127, 1015)
  dec.expect_bit(3, 0, 534764160L, 1042328410L, 128, 1017)
  dec.expect_bit(4, 0, 501341400L, 1042328410L, 128, 1017)
  dec.expect_bit(5, 0, 485674482L, 1042328410L, 128, 1018)
  dec.expect_bin(8, 0, 483777317L, 1042328410L, 128, 1018)
  dec.expect_bin(5, 0, 468659276L, 1042328410L, 128, 1018)
  dec.expect_bin(1, 0, 234329638L, 1042328410L, 129, 1026)
  dec.expect_bit(3, 0, 205038434L, 1042328410L, 129, 1028)
  dec.expect_uint(10, 0, 20503847L, 1042328410L, 132, 1054)
  dec.expect_bit(5, 0, 19863102L, 1042328410L, 132, 1055)
  dec.expect_bit(1, 0, 9931551L, 1042328410L, 133, 1063)
  dec.expect_uint(65536, 100, 9939456L, 548100691L, 149, 1191)
  dec.expect_bit(3, 0, 8697024L, 548100691L, 149, 1192)
  dec.expect_bin(3, 0, 1948133376L, 727339989L, 150, 1194)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 5, 243516672L, 240306645L, 153, 1218)
  dec.expect_bin(3, 0, 213077088L, 240306645L, 153, 1219)
  dec.expect_bin(5, 0, 206418429L, 240306645L, 153, 1220)
  dec.expect_bit(7, 0, 204805786L, 240306645L, 153, 1220)
  dec.expect_uint(65536, 253, 204845056L, 1388959136L, 169, 1348)
  dec.expect_bin(1, 0, 102422528L, 1388959136L, 170, 1356)
  dec.expect_bit(6, 0, 100822176L, 1388959136L, 170, 1356)
  dec.expect_bin(6, 0, 99246830L, 1388959136L, 170, 1356)
  dec.expect_ctx([4, 4, 4, 4], 0, 24811718L, 1388959136L, 172, 1372)
  dec.expect_ctx([1, 2, 3, 10], 0, 396988928L, 1238736897L, 176, 1404)
  dec.expect_bin(8, 0, 395438190L, 1238736897L, 176, 1404)
  dec.expect_bin(4, 0, 370723304L, 1238736897L, 176, 1405)
  dec.expect_uint(10, 0, 37072334L, 1238736897L, 179, 1431)
  dec.expect_bin(3, 0, 32438293L, 1238736897L, 180, 1433)
  dec.expect_bit(2, 0, 24328720L, 1238736897L, 180, 1436)
  dec.expect_bit(4, 0, 22808175L, 1238736897L, 180, 1437)
  dec.expect_bin(6, 0, 22451798L, 1238736897L, 180, 1437)
  dec.expect_ctx([4, 4, 4, 4], 0, 1436916224L, 1436549541L, 182, 1453)
  dec.expect_uint(100, 0, 14369186L, 1436549541L, 189, 1506)
  dec.expect_bin(3, 0, 12573038L, 1436549541L, 189, 1508)
  dec.expect_bin(7, 0, 12474812L, 1436549541L, 189, 1508)
  dec.expect_ctx([4, 4, 4, 4], 0, 798390272L, 536978736L, 191, 1524)
  dec.expect_bit(7, 0, 792152848L, 536978736L, 191, 1524)
  dec.expect_uint(70000, 22959, 1480227072L, 1285666013L, 207, 1653)
  dec.expect_bin(7, 0, 1468662798L, 1285666013L, 207, 1653)
  dec.expect_ctx([1, 2, 3, 10], 1, 183582848L, 92377501L, 210, 1677)
  dec.expect_bit(2, 0, 137687136L, 92377501L, 210, 1680)
  dec.expect_bit(5, 0, 133384413L, 92377501L, 211, 1681)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 2, 16673051L, 9012246L, 214, 1705)
  dec.expect_uint(5, 2, 853660160L, 599814745L, 216, 1723)
  dec.expect_uint(100, 29, 8536601L, 2252675L, 222, 1776)
  dec.expect_bin(3, 0, 1912198656L, 576684947L, 223, 1778)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 5, 239024832L, 98635283L, 226, 1802)
  dec.expect_bit(8, 0, 238091142L, 98635283L, 226, 1802)
  dec.expect_bin(3, 0, 208329750L, 98635283L, 226, 1803)
  dec.expect_bit(3, 0, 182288532L, 98635283L, 226, 1805)
  dec.expect_bin(1, 0, 91144266L, 98635283L, 227, 1813)
  dec.expect_bin(7, 0, 90432202L, 98635283L, 227, 1813)
  dec.expect_bit(8, 0, 90078952L, 98635283L, 227, 1813)
  dec.expect_bit(8, 0, 89727082L, 98635283L, 227, 1813)
  dec.expect_bin(4, 0, 84119140L, 98635283L, 227, 1814)
  dec.expect_bin(7, 0, 83461960L, 98635283L, 227, 1814)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    0,
    1335393280L,
    1628312405L,
    231,
    1846,
  )
  dec.expect_uint(100, 0, 13354012L, 1628312405L, 238, 1899)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 0, 427329280L, 236148065L, 241, 1923)
  dec.expect_bin(4, 0, 400621200L, 236148065L, 241, 1924)
  dec.expect_uint(5, 2, 80124240L, 75899585L, 243, 1942)
  dec.expect_uint(1000, 55, 82046976L, 67207503L, 253, 2022)
  dec.expect_bin(6, 0, 80764992L, 67207503L, 253, 2022)
  dec.expect_bin(7, 0, 80134016L, 67207503L, 253, 2022)
  dec.expect_bit(5, 0, 77629828L, 67207503L, 253, 2023)
  dec.expect_uint(5, 0, 15525968L, 67207503L, 256, 2041)
  dec.expect_bin(6, 0, 15283375L, 67207503L, 256, 2042)
  dec.expect_bit(7, 0, 15163974L, 67207503L, 256, 2042)
  dec.expect_bit(2, 0, 11372981L, 67207503L, 256, 2045)
  dec.expect_bit(4, 0, 10662170L, 67207503L, 256, 2046)
  dec.expect_uint(70000, 325, 19925504L, 25251693L, 272, 2175)
  dec.expect_bit(2, 0, 14944128L, 25251693L, 273, 2178)
  dec.expect_bin(2, 0, 11208096L, 25251693L, 273, 2181)
  dec.expect_uint(100, 0, 28717056L, 21982692L, 280, 2234)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    3,
    459472896L,
    113894529L,
    284,
    2266,
  )
  dec.expect_bit(8, 0, 457678080L, 113894529L, 284, 2266)
  dec.expect_bin(7, 0, 454102470L, 113894529L, 284, 2266)
  dec.expect_bin(1, 1, 227051235L, 113894529L, 285, 2274)
  dec.expect_bit(1, 0, 113525618L, 113894529L, 286, 2282)
  dec.expect_bit(3, 0, 99334916L, 113894529L, 286, 2284)
  dec.expect_uint(65536, 188, 99335936L, 1239712065L, 302, 2412)
  dec.expect_uint(70000, 188, 185649152L, 1686192499L, 318, 2541)
  dec.expect_uint(1000, 0, 190143488L, 21066520L, 328, 2620)
  dec.expect_bin(1, 1, 95071744L, 21066520L, 329, 2628)
  dec.expect_uint(100, 77, 243383552L, 38590993L, 336, 2682)
  dec.expect_bin(2, 1, 60845888L, 38590993L, 338, 2698)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1],
    2,
    1947068416L,
    143952241L,
    341,
    2722,
  )
  dec.expect_bin(8, 0, 1939462680L, 143952241L, 341, 2722)
  dec.expect_bit(3, 1, 242432835L, 143952241L, 344, 2746)
  dec.expect_uint(65536, 26516, 242432768L, 1993039L, 360, 2874)
  dec.expect_uint(70000, 69282, 453012992L, 57205227L, 376, 3002)
  dec.expect_ctx([4, 4, 4, 4], 3, 113253248L, 57205227L, 378, 3018)
  dec.expect_bit(2, 0, 84939936L, 57205227L, 378, 3022)
  dec.expect_bin(2, 0, 63704952L, 57205227L, 379, 3025)
  dec.expect_bin(8, 0, 63456105L, 57205227L, 379, 3025)
  dec.expect_bit(1, 0, 31728053L, 57205227L, 380, 3033)
  dec.expect_bit(5, 0, 30736552L, 57205227L, 380, 3034)
  dec.expect_uint(10, 0, 786856192L, 1759636451L, 383, 3060)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 0, 98357024L, 1759636451L, 386, 3084)
  dec.expect_bin(6, 0, 96820196L, 1759636451L, 386, 3084)
  dec.expect_uint(65536, 183, 96878336L, 1642849195L, 402, 3212)
  dec.expect_bin(8, 0, 96499905L, 1642849195L, 402, 3212)
  dec.expect_bin(3, 0, 84437417L, 1642849195L, 402, 3214)
  dec.expect_bit(1, 0, 42218709L, 1642849195L, 403, 3222)
  dec.expect_bin(1, 0, 21109355L, 1642849195L, 404, 3230)
  dec.expect_bit(4, 0, 19790021L, 1642849195L, 404, 3231)
  dec.expect_bin(6, 0, 19480802L, 1642849195L, 404, 3231)
  dec.expect_bin(3, 0, 17045702L, 1642849195L, 404, 3232)
  dec.expect_bit(3, 0, 14914990L, 1642849195L, 405, 3234)
  dec.expect_bit(1, 0, 1909118720L, 1810082705L, 406, 3242)
  dec.expect_uint(100, 5, 19091187L, 15511127L, 412, 3295)
  dec.expect_ctx([1, 2, 3, 10], 2, 916376832L, 916259271L, 415, 3314)
  dec.expect_ctx([1, 2, 3, 10], 0, 57273552L, 916259271L, 419, 3346)
  dec.expect_bit(4, 0, 53693955L, 916259271L, 419, 3347)
  dec.expect_bit(7, 0, 53274471L, 916259271L, 419, 3347)
  dec.expect_bit(8, 0, 53066368L, 916259271L, 419, 3347)
  dec.expect_bin(3, 0, 46433072L, 916259271L, 419, 3349)
  dec.expect_bin(7, 0, 46070314L, 916259271L, 419, 3349)
  dec.expect_ctx([4, 4, 4, 4], 0, 11517586L, 916259271L, 421, 3365)
  dec.expect_bit(1, 0, 1474251008L, 486655804L, 422, 3373)
  dec.expect_bit(4, 0, 1382110320L, 486655804L, 422, 3374)
  dec.expect_bit(7, 0, 1371312584L, 486655804L, 422, 3374)
  dec.expect_uint(1000, 646, 1404224000L, 1012173911L, 432, 3453)
  dec.expect_ctx([4, 4, 4, 4], 1, 351056000L, 310061911L, 434, 3469)
  dec.expect_bit(3, 0, 307174000L, 310061911L, 434, 3471)
  dec.expect_bin(6, 0, 302374407L, 310061911L, 434, 3471)
  dec.expect_bit(1, 0, 151187204L, 310061911L, 435, 3479)
  dec.expect_bin(4, 0, 141738004L, 310061911L, 435, 3480)
  dec.expect_ctx([1, 2, 3, 10], 0, 8858629L, 310061911L, 439, 3512)
  dec.expect_bit(3, 0, 1984333056L, 2066437925L, 440, 3513)
  dec.expect_bin(7, 0, 1968830454L, 2066437925L, 440, 3514)
  dec.expect_bin(3, 0, 1722726648L, 2066437925L, 440, 3515)
  dec.expect_bit(3, 0, 1507385817L, 2066437925L, 440, 3517)
  dec.expect_bit(7, 0, 1495609366L, 2066437925L, 440, 3517)
  dec.expect_bin(5, 0, 1448871574L, 2066437925L, 440, 3517)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1],
    0,
    181108952L,
    2066437925L,
    443,
    3541,
  )
  dec.expect_bin(6, 0, 178279125L, 2066437925L, 443, 3541)
  dec.expect_uint(100, 0, 456400896L, 727131421L, 450, 3594)
  dec.expect_bin(3, 0, 399350784L, 727131421L, 450, 3596)
  dec.expect_uint(10, 0, 39935082L, 727131421L, 453, 3622)
  dec.expect_uint(5, 0, 2044676608L, 1462050063L, 456, 3641)
  dec.expect_bit(4, 0, 1916884320L, 1462050063L, 456, 3642)
  dec.expect_uint(70000, 16843, 13991856L, 6897039L, 472, 3771)
  dec.expect_bit(7, 0, 13882545L, 6897039L, 472, 3771)
  dec.expect_bin(1, 1, 1776965632L, 1765642039L, 473, 3779)
  dec.expect_uint(100, 0, 17769688L, 1765642039L, 479, 3832)
  dec.expect_bin(2, 0, 13327266L, 1765642039L, 480, 3835)
  dec.expect_bin(8, 0, 13275207L, 1765642039L, 480, 3835)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1],
    0,
    424808192L,
    1032795941L,
    483,
    3859,
  )
  dec.expect_bit(3, 0, 371707168L, 1032795941L, 483, 3861)
  dec.expect_uint(100, 0, 951587584L, 255272289L, 490, 3914)
  dec.expect_uint(1000, 730, 974425600L, 63190794L, 500, 3994)
  dec.expect_bit(7, 0, 966812900L, 63190794L, 500, 3994)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    14,
    60425806L,
    2764988L,
    504,
    4026,
  )
  dec.expect_bit(8, 0, 60189768L, 2764988L, 504, 4026)
  dec.expect_bit(1, 1, 30094884L, 2764988L, 505, 4034)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    14,
    481518080L,
    226318944L,
    509,
    4066,
  )
  dec.expect_bit(4, 0, 451423200L, 226318944L, 509, 4067)
  dec.expect_bin(2, 0, 338567400L, 226318944L, 509, 4070)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    5,
    21160462L,
    14714324L,
    513,
    4102,
  )
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 2, 677134592L, 381194137L, 516, 4126)
  dec.expect_bin(8, 0, 674489535L, 381194137L, 516, 4126)
  dec.expect_uint(1000, 435, 690677248L, 200207347L, 526, 4206)
  dec.expect_bin(3, 0, 604342592L, 200207347L, 526, 4207)
  dec.expect_uint(5, 3, 120868518L, 79338829L, 529, 4226)
  dec.expect_uint(100, 34, 309423360L, 198221903L, 535, 4279)
  dec.expect_bit(2, 0, 232067520L, 198221903L, 536, 4282)
  dec.expect_ctx([4, 4, 4, 4], 0, 58016880L, 198221903L, 538, 4298)
  dec.expect_bin(5, 0, 56203853L, 198221903L, 538, 4299)
  dec.expect_bin(2, 0, 42152890L, 198221903L, 538, 4302)
  dec.expect_bit(1, 0, 21076445L, 198221903L, 539, 4310)
  dec.expect_bit(8, 0, 20994116L, 198221903L, 539, 4310)
  dec.expect_bit(4, 0, 19681984L, 198221903L, 539, 4311)
  dec.expect_uint(65536, 195, 19730944L, 1352683497L, 555, 4439)
  dec.expect_uint(1000, 1, 20253952L, 542108108L, 565, 4518)
  dec.expect_bit(7, 0, 20095718L, 542108108L, 565, 4518)
  dec.expect_bin(2, 0, 15071789L, 542108108L, 566, 4522)
  dec.expect_bit(2, 0, 11303842L, 542108108L, 566, 4525)
  dec.expect_bin(5, 0, 10950597L, 542108108L, 566, 4525)
  dec.expect_bit(3, 0, 9581773L, 542108108L, 566, 4527)
  dec.expect_bit(4, 0, 8982913L, 542108108L, 566, 4528)
  dec.expect_bin(6, 0, 8842555L, 542108108L, 566, 4528)
  dec.expect_bit(5, 0, 8566226L, 542108108L, 566, 4528)
  dec.expect_bit(7, 0, 8499303L, 542108108L, 566, 4528)
  dec.expect_bin(7, 0, 8432903L, 542108108L, 566, 4528)
  dec.expect_ctx([4, 4, 4, 4], 0, 539707136L, 1340722391L, 568, 4544)
  dec.expect_ctx([1, 2, 3, 10], 0, 33731696L, 1340722391L, 572, 4576)
  dec.expect_bit(4, 0, 31623465L, 1340722391L, 573, 4577)
  dec.expect_bit(3, 0, 27670532L, 1340722391L, 573, 4579)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    0,
    442729472L,
    1775032259L,
    577,
    4611,
  )
  dec.expect_bin(7, 0, 439270648L, 1775032259L, 577, 4611)
  dec.expect_bin(8, 0, 437554748L, 1775032259L, 577, 4611)
  dec.expect_bit(2, 0, 328166061L, 1775032259L, 577, 4614)
  dec.expect_bit(1, 0, 164083031L, 1775032259L, 578, 4622)
  dec.expect_bin(8, 0, 163442082L, 1775032259L, 578, 4622)
  dec.expect_bit(4, 0, 153226952L, 1775032259L, 578, 4623)
  dec.expect_bit(3, 0, 134073583L, 1775032259L, 579, 4625)
  dec.expect_uint(65536, 109, 134134528L, 1289208824L, 595, 4753)
  dec.expect_ctx([1, 2, 3, 10], 0, 2146152448L, 1472460863L, 599, 4785)
  dec.expect_bin(5, 0, 2079085184L, 1472460863L, 599, 4785)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 2, 259885648L, 173032623L, 602, 4809)
  dec.expect_bit(6, 0, 255824935L, 173032623L, 602, 4809)
  dec.expect_bit(2, 0, 191868702L, 173032623L, 602, 4812)
  dec.expect_bit(2, 0, 143901527L, 173032623L, 602, 4816)
  dec.expect_uint(1000, 0, 147362048L, 1346678700L, 612, 4895)
  dec.expect_bit(7, 0, 146210782L, 1346678700L, 612, 4896)
  dec.expect_bit(6, 0, 143926239L, 1346678700L, 612, 4896)
  dec.expect_bin(5, 0, 139428545L, 1346678700L, 612, 4896)
  dec.expect_bin(1, 0, 69714273L, 1346678700L, 613, 4904)
  dec.expect_ctx([1, 2, 3, 10], 0, 1115428608L, 1152363756L, 617, 4936)
  dec.expect_bit(1, 0, 557714304L, 1152363756L, 618, 4944)
  dec.expect_bit(3, 0, 488000016L, 1152363756L, 619, 4946)
  dec.expect_ctx([4, 4, 4, 4], 0, 122000004L, 1152363756L, 621, 4962)
  dec.expect_uint(100, 0, 312321024L, 799861987L, 627, 5015)
  dec.expect_bit(2, 0, 234240768L, 799861987L, 628, 5018)
  dec.expect_bin(7, 0, 232410762L, 799861987L, 628, 5018)
  dec.expect_bin(1, 0, 116205381L, 799861987L, 629, 5026)
  dec.expect_bin(1, 0, 58102691L, 799861987L, 630, 5034)
  dec.expect_bit(3, 0, 50839855L, 799861987L, 630, 5036)
  dec.expect_bit(8, 0, 50641262L, 799861987L, 630, 5036)
  dec.expect_bit(5, 0, 49058723L, 799861987L, 630, 5036)
  dec.expect_bin(4, 0, 45992553L, 799861987L, 630, 5037)
  dec.expect_bit(6, 0, 45273920L, 799861987L, 630, 5037)
  dec.expect_bin(8, 0, 45097069L, 799861987L, 630, 5037)
  dec.expect_bit(4, 0, 42278503L, 799861987L, 630, 5038)
  dec.expect_bin(4, 0, 39636097L, 799861987L, 630, 5039)
  dec.expect_bin(6, 0, 39016783L, 799861987L, 630, 5039)
  dec.expect_bit(7, 0, 38711965L, 799861987L, 630, 5039)
  dec.expect_bin(2, 0, 29033974L, 799861987L, 631, 5042)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    0,
    464545024L,
    753722120L,
    635,
    5074,
  )
  dec.expect_bit(1, 0, 232272512L, 753722120L, 636, 5082)
  dec.expect_bit(8, 0, 231365198L, 753722120L, 636, 5082)
  dec.expect_bit(8, 0, 230461428L, 753722120L, 636, 5082)
  dec.expect_bin(6, 0, 226860469L, 753722120L, 636, 5082)
  dec.expect_bin(6, 0, 223315775L, 753722120L, 636, 5083)
  dec.expect_bit(5, 0, 216337158L, 753722120L, 636, 5083)
  dec.expect_bit(1, 0, 108168579L, 753722120L, 637, 5091)
  dec.expect_uint(10, 0, 10816866L, 753722120L, 640, 5118)
  dec.expect_bin(8, 0, 10774613L, 753722120L, 640, 5118)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    0,
    172395008L,
    1826818258L,
    644,
    5150,
  )
  dec.expect_bit(7, 0, 171048172L, 1826818258L, 644, 5150)
  dec.expect_bin(5, 0, 165702917L, 1826818258L, 644, 5150)
  dec.expect_ctx([1, 2, 3, 10], 0, 10356437L, 1826818258L, 648, 5182)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1],
    0,
    331407104L,
    1661522531L,
    651,
    5206,
  )
  dec.expect_bin(6, 0, 326228868L, 1661522531L, 651, 5206)
  dec.expect_bit(5, 0, 316034216L, 1661522531L, 651, 5207)
  dec.expect_uint(65536, 8, 316077056L, 148005671L, 667, 5335)
  dec.expect_uint(1000, 530, 323662848L, 20898619L, 677, 5414)
  dec.expect_bin(1, 1, 161831424L, 20898619L, 678, 5422)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    13,
    10114464L,
    669691L,
    682,
    5454,
  )
  dec.expect_bit(5, 0, 9798387L, 669691L, 682, 5455)
  dec.expect_uint(100, 93, 25083648L, 20939222L, 689, 5508)
  dec.expect_bit(3, 0, 21948192L, 20939222L, 689, 5509)
  dec.expect_uint(5, 0, 1123747840L, 1065473778L, 691, 5528)
  dec.expect_ctx([4, 4, 4, 4], 0, 280936960L, 1065473778L, 693, 5544)
  dec.expect_uint(65536, 117, 280936960L, 30863928L, 709, 5672)
  dec.expect_uint(5, 4, 56187392L, 30863928L, 712, 5691)
}

///|
const RANGE_SHORT_BITS : Bytes = b"\x5a\xa5"

///|
fn play_short(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_SHORT_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_bit(2, 0, 1610612736L, 1387102207L, 2, 12)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 1, 201326592L, 179142655L, 5, 36)
}

///|
const RANGE_LONG_BITS : Bytes = b"\x29\x7d\x86\x55\x4a\x62\xb6\x6c\x97\xd7\x59\x94\x11\xec\x79\xc5\xe7\x45\x3a\xa1\x6c\x3f\xef\xdb\x0a\x7a\xda\x31\xcf\xc6\x9a\x17\x12\xc4\x79\xc9\x3d\x85\x46\x1d\xdc\x50\xc0\x99\x85\xe9\x6c\xaa\x75\xc0\x04\x92\xca\xd9\x89\xb4\x02\xc6\x9f\xeb\x4b\x60\x42\x85\xb9\x79\x8c\xc5\x3a\xf7\x50\xe4\xfa\x84\x7c\x10\x41\x7e\x67\xf6\x82\x3c\xd9\x56\x4f\x4c\x80\x22\xca\xa6\xe8\xc5\x44\x68\x36\x25\x21\x0a\xd3\xf6\xff\x49\xb9\xa1\x53\x1b\xe3\x9c\xb2\x2e\x9c\x18\xf0\x51\xd9\xe8\x71\x2d\x1b\x98\x52\xad\x57\x7c\x34\x67\x8d\x72\xf8\x0e\x73\x2a\x6e\x2c\x77\x08\x96\x0c\x9b\xd2\xc8\x95\x8f\x40\x5d\xc6\x3f\x3f\xa2\x3f\xcc\xac\x16\xca\x76\xc5\x20\x45\x2b\x0e\xba\x79\x06\x6a\x24\x35\x27\x4e\x56\x8a\x5f\x95\x43\xd1\xe9\xcf\x43\x3d\x17\xcc\xf1\x81\x67\x00\x84\x0c\xd9\x3b\x88\x04\x94\xc8\x8c\x2e\x36\x98\x0c\x9f\x11\x49\x66\xa7\xaa\x4d\xbc\xd5\x03\xc6\x05\x23\xee\xee\x75\x82\x8e\xb3\x78\x30\xd7\xcd\x98\xb1\x1a\xa9\x0a\x7d\xbd\x65\x1d\xab\x10\x72\x52\x8b\xfa\x9e\x21\x4f\xc7\x34\xca\xbb\x9b\xf2\xe3\x57\x8d\x89\x6c\xda\x40\x91\x88\xbd\x78\x2d"

///|
fn play_long(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_LONG_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_uint(65536, 10541, 2147483648L, 1094505818L, 17, 136)
  dec.expect_bit(4, 0, 2013265920L, 1094505818L, 18, 137)
  dec.expect_ctx([4, 4, 4, 4], 1, 503316480L, 87872858L, 20, 153)
  dec.expect_bit(4, 0, 471859200L, 87872858L, 20, 154)
  dec.expect_ctx([4, 4, 4, 4], 3, 117964800L, 87872858L, 22, 170)
  dec.expect_bit(4, 0, 110592000L, 87872858L, 22, 171)
  dec.expect_ctx([4, 4, 4, 4], 0, 27648000L, 87872858L, 24, 187)
  dec.expect_bit(4, 0, 25920000L, 87872858L, 24, 187)
  dec.expect_ctx([4, 4, 4, 4], 0, 1658880000L, 1020615374L, 26, 203)
  dec.expect_bit(4, 0, 1555200000L, 1020615374L, 26, 204)
  dec.expect_ctx([4, 4, 4, 4], 1, 388800000L, 243015374L, 28, 220)
  dec.expect_bit(4, 0, 364500000L, 243015374L, 28, 221)
  dec.expect_ctx([4, 4, 4, 4], 1, 91125000L, 60765374L, 30, 237)
  dec.expect_bit(4, 0, 85429688L, 60765374L, 30, 238)
  dec.expect_ctx([4, 4, 4, 4], 1, 21357420L, 18050534L, 32, 254)
  dec.expect_bit(4, 0, 20022582L, 18050534L, 32, 254)
  dec.expect_ctx([4, 4, 4, 4], 0, 1281446400L, 325969572L, 34, 270)
  dec.expect_bit(4, 0, 1201356000L, 325969572L, 34, 271)
  dec.expect_ctx([4, 4, 4, 4], 2, 300339000L, 25630572L, 36, 287)
  dec.expect_bit(4, 0, 281567813L, 25630572L, 36, 288)
  dec.expect_ctx([4, 4, 4, 4], 3, 70391952L, 25630572L, 38, 304)
  dec.expect_bit(4, 0, 65992455L, 25630572L, 39, 305)
  dec.expect_ctx([4, 4, 4, 4], 2, 16498112L, 9132460L, 41, 321)
  dec.expect_bit(4, 0, 15466980L, 9132460L, 41, 321)
  dec.expect_ctx([4, 4, 4, 4], 1, 989886464L, 358137033L, 43, 337)
  dec.expect_bit(4, 0, 928018560L, 358137033L, 43, 338)
  dec.expect_ctx([4, 4, 4, 4], 2, 232004640L, 126132393L, 45, 354)
  dec.expect_bit(4, 0, 217504350L, 126132393L, 45, 355)
  dec.expect_ctx([4, 4, 4, 4], 1, 54376084L, 17380225L, 47, 371)
  dec.expect_bit(4, 0, 50977579L, 17380225L, 47, 372)
  dec.expect_ctx([4, 4, 4, 4], 2, 12744392L, 4635833L, 49, 388)
  dec.expect_bit(4, 0, 11947868L, 4635833L, 49, 388)
  dec.expect_ctx([4, 4, 4, 4], 2, 764662784L, 422110644L, 51, 404)
  dec.expect_bit(4, 0, 716871360L, 422110644L, 51, 405)
  dec.expect_ctx([4, 4, 4, 4], 1, 179217840L, 63674964L, 53, 421)
  dec.expect_bit(4, 0, 168016725L, 63674964L, 53, 422)
  dec.expect_ctx([4, 4, 4, 4], 2, 42004180L, 21670784L, 55, 438)
  dec.expect_bit(4, 0, 39378919L, 21670784L, 55, 439)
  dec.expect_ctx([4, 4, 4, 4], 1, 9844728L, 1981328L, 57, 455)
  dec.expect_bit(4, 0, 9229433L, 1981328L, 57, 455)
  dec.expect_ctx([4, 4, 4, 4], 3, 590683136L, 507219988L, 59, 471)
  dec.expect_bit(4, 0, 553765440L, 507219988L, 59, 472)
  dec.expect_ctx([4, 4, 4, 4], 0, 138441360L, 507219988L, 61, 488)
  dec.expect_bit(4, 0, 129788775L, 507219988L, 62, 489)
  dec.expect_ctx([4, 4, 4, 4], 0, 32447199L, 507219988L, 64, 505)
  dec.expect_bit(4, 0, 30419250L, 507219988L, 64, 506)
  dec.expect_ctx([4, 4, 4, 4], 0, 1946832384L, 999298131L, 66, 522)
  dec.expect_bit(4, 0, 1825155360L, 999298131L, 66, 522)
  dec.expect_ctx([4, 4, 4, 4], 1, 456288840L, 86720451L, 68, 538)
  dec.expect_bit(4, 0, 427770788L, 86720451L, 68, 539)
  dec.expect_ctx([4, 4, 4, 4], 3, 106942696L, 86720451L, 70, 555)
  dec.expect_bit(4, 0, 100258778L, 86720451L, 70, 556)
  dec.expect_ctx([4, 4, 4, 4], 0, 25064702L, 86720451L, 72, 572)
  dec.expect_bit(4, 0, 23498159L, 86720451L, 72, 573)
  dec.expect_ctx([4, 4, 4, 4], 0, 1503885056L, 725599029L, 74, 589)
  dec.expect_bit(4, 0, 1409892240L, 725599029L, 74, 589)
  dec.expect_ctx([4, 4, 4, 4], 1, 352473060L, 20652909L, 76, 605)
  dec.expect_bit(4, 1, 22029566L, 20652909L, 80, 637)
  dec.expect_ctx([4, 4, 4, 4], 0, 1409894912L, 992177655L, 82, 653)
  dec.expect_bit(4, 0, 1321776480L, 992177655L, 82, 654)
  dec.expect_ctx([4, 4, 4, 4], 0, 330444120L, 992177655L, 84, 670)
  dec.expect_bit(4, 0, 309791363L, 992177655L, 84, 671)
  dec.expect_ctx([4, 4, 4, 4], 0, 77447843L, 992177655L, 86, 687)
  dec.expect_bit(4, 0, 72607353L, 992177655L, 86, 688)
  dec.expect_ctx([4, 4, 4, 4], 0, 18151845L, 992177655L, 88, 704)
  dec.expect_bit(4, 0, 17017355L, 992177655L, 88, 704)
  dec.expect_ctx([4, 4, 4, 4], 0, 1089112832L, 594409225L, 90, 720)
  dec.expect_bit(4, 0, 1021043280L, 594409225L, 91, 721)
  dec.expect_ctx([4, 4, 4, 4], 1, 255260820L, 83887585L, 93, 737)
  dec.expect_bit(4, 0, 239307019L, 83887585L, 93, 738)
  dec.expect_ctx([4, 4, 4, 4], 2, 59826752L, 24060833L, 95, 754)
  dec.expect_bit(4, 0, 56087580L, 24060833L, 95, 755)
  dec.expect_ctx([4, 4, 4, 4], 2, 14021892L, 10038941L, 97, 771)
  dec.expect_bit(4, 0, 13145524L, 10038941L, 97, 771)
  dec.expect_ctx([4, 4, 4, 4], 0, 841314304L, 422485443L, 99, 787)
  dec.expect_bit(4, 0, 788732160L, 422485443L, 99, 788)
  dec.expect_ctx([4, 4, 4, 4], 1, 197183040L, 28119363L, 101, 804)
  dec.expect_bit(4, 0, 184859100L, 28119363L, 101, 805)
  dec.expect_ctx([4, 4, 4, 4], 3, 46214772L, 28119363L, 103, 821)
  dec.expect_bit(4, 0, 43326349L, 28119363L, 103, 822)
  dec.expect_ctx([4, 4, 4, 4], 1, 10831584L, 6456195L, 105, 838)
}
