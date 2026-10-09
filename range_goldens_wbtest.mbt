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
  dec.expect_ctx([4, 4, 4, 4], 0, 536870912L, 188134989L, 11, 88)
  dec.expect_ctx([4, 4, 4, 4], 2, 134217728L, 53917261L, 13, 104)
  dec.expect_ctx([4, 4, 4, 4], 2, 33554432L, 20362829L, 15, 120)
  dec.expect_ctx([4, 4, 4, 4], 1, 2147483648L, 917917124L, 17, 136)
  dec.expect_ctx([4, 4, 4, 4], 2, 536870912L, 381046212L, 19, 152)
  dec.expect_ctx([4, 4, 4, 4], 1, 134217728L, 112610756L, 21, 168)
  dec.expect_ctx([4, 4, 4, 4], 0, 33554432L, 11947460L, 23, 184)
  dec.expect_ctx([4, 4, 4, 4], 2, 2147483648L, 911066231L, 25, 200)
  dec.expect_ctx([4, 4, 4, 4], 2, 536870912L, 374195319L, 27, 216)
  dec.expect_ctx([4, 4, 4, 4], 1, 134217728L, 105759863L, 29, 232)
  dec.expect_ctx([4, 4, 4, 4], 0, 33554432L, 5096567L, 31, 248)
  dec.expect_ctx([4, 4, 4, 4], 3, 2147483648L, 1304721380L, 33, 264)
}

///|
const RANGE_BITLOGP_BITS : Bytes = b"\x42\x39\xed\x11\x36\xfc\x75\xf7\x9a\x48\x24\x25\x21\xe3\x3a\xee\x5a\x6f\x82\x35\x26\xd4\x5d\x0b\xce\x04\xea\x37\xbe\x3a\xf1\x21\xdd\x56\xa5\xfb\x74\x26\xd3\xf9\xe8\xb7\x1b\x94\xd4\x20\x6b\xe3"

///|
fn play_bitlogp(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_BITLOGP_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_bit(1, 0, 1073741824L, 518195575L, 2, 16)
  dec.expect_bit(2, 0, 805306368L, 249760119L, 3, 20)
  dec.expect_bit(3, 0, 704643072L, 149096823L, 3, 21)
  dec.expect_bit(4, 0, 660602880L, 105056631L, 3, 22)
  dec.expect_bit(5, 0, 639959040L, 84412791L, 3, 22)
  dec.expect_bit(6, 0, 629959680L, 74413431L, 3, 23)
  dec.expect_bit(7, 0, 625038120L, 69491871L, 3, 23)
  dec.expect_bit(8, 0, 622596565L, 67050316L, 3, 23)
  dec.expect_bit(1, 1, 311298282L, 67050316L, 4, 31)
  dec.expect_bit(3, 0, 272385997L, 28138031L, 4, 32)
  dec.expect_bit(5, 0, 263873935L, 19625969L, 5, 33)
  dec.expect_bit(7, 0, 261812420L, 17564454L, 5, 33)
  dec.expect_bit(2, 1, 65453105L, 17564454L, 7, 49)
  dec.expect_bit(4, 0, 61362286L, 13473635L, 7, 50)
  dec.expect_bit(6, 0, 60403501L, 12514850L, 7, 50)
  dec.expect_bit(8, 0, 60167550L, 12278899L, 7, 50)
  dec.expect_bit(3, 0, 52646607L, 4757956L, 7, 51)
  dec.expect_bit(3, 1, 1684691200L, 1218036836L, 10, 75)
  dec.expect_bit(1, 0, 842345600L, 375691236L, 11, 83)
  dec.expect_bit(8, 0, 839055188L, 372400824L, 11, 83)
}

///|
const RANGE_ICDF8_BITS : Bytes = b"\x2d\x2a\xcf\x91\xf3\xdd\x3a\xe2\x45\xf7\x07\xfd\x03\xe9\x4e\xe0\xda\xb6\x32\x50\x9d\x06\xd5\x13\xdc\x0f\x88\x90\xea\x7c\x39\x48\xcc\x22\x5b\xdc\xbb\x0c\x8a\xf8\x6c\xd2\x20\xb0\x53\xd9\x6e\xda"

///|
fn play_icdf8(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_ICDF8_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_icdf(8, 0, 469762048L, 90871863L, 4, 26)
  dec.expect_icdf(8, 3, 110100480L, 17471543L, 6, 43)
  dec.expect_icdf(8, 3, 25804800L, 268343L, 8, 60)
  dec.expect_icdf(8, 4, 1032192000L, 68695814L, 11, 81)
  dec.expect_icdf(8, 4, 161280000L, 68695814L, 13, 102)
  dec.expect_icdf(8, 2, 31500000L, 5695814L, 16, 121)
  dec.expect_icdf(8, 3, 1889986560L, 198137361L, 18, 138)
  dec.expect_icdf(8, 4, 295310400L, 198137361L, 20, 159)
  dec.expect_icdf(8, 1, 57677800L, 25103961L, 23, 178)
  dec.expect_icdf(8, 2, 11265150L, 2573661L, 25, 197)
  dec.expect_icdf(8, 3, 675901440L, 208256354L, 27, 214)
  dec.expect_icdf(8, 3, 158414400L, 102646754L, 29, 231)
  dec.expect_icdf(8, 1, 30940300L, 9825854L, 32, 249)
  dec.expect_icdf(8, 3, 1856409600L, 1277812366L, 34, 266)
  dec.expect_icdf(8, 1, 362580000L, 190072366L, 36, 285)
  dec.expect_icdf(8, 2, 70816400L, 48439566L, 38, 304)
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
  dec.expect_bit(3, 0, 1879048192L, 153231438L, 2, 10)
  dec.expect_bit(3, 1, 234881024L, 153231438L, 5, 34)
  dec.expect_icdf(8, 1, 45875200L, 15605838L, 7, 53)
  dec.expect_icdf(8, 3, 10752000L, 8437838L, 9, 70)
  dec.expect_icdf(8, 0, 602112000L, 9686672L, 11, 87)
  dec.expect_icdf(8, 4, 94080000L, 9686672L, 14, 109)
  dec.expect_icdf(8, 4, 14700000L, 9686672L, 17, 130)
  dec.expect_icdf(8, 1, 734988800L, 274821850L, 19, 149)
  dec.expect_icdf(8, 3, 172263000L, 159979850L, 21, 166)
  dec.expect_uint(32, 2, 1378103808L, 989831232L, 26, 206)
  dec.expect_bit(8, 0, 1372720590L, 984448014L, 26, 206)
  dec.expect_bin(4, 0, 1286925554L, 898652978L, 26, 206)
  dec.expect_ctx([8, 8, 8, 8], 1, 321731384L, 255190210L, 28, 222)
  dec.expect_ctx([8, 8, 8, 8], 0, 80432864L, 13891690L, 30, 238)
  dec.expect_ctx([8, 8, 8, 8], 3, 20108216L, 13891690L, 32, 254)
  dec.expect_ctx([8, 8, 8, 8], 1, 1286924288L, 982424104L, 34, 270)
}

///|
const RANGE_RANDOM300_BITS : Bytes = b"\x60\x5e\x03\x80\xb5\xd5\xd2\xf8\x03\xa7\x7f\x83\xbe\xa9\x4b\x58\x54\xbf\xfc\xb5\x9e\x45\x4c\xd9\x55\x3d\x61\x24\x36\xfd\x7d\x19\xcf\xdd\x1d\x60\x28\x38\xa8\xdc\x71\x87\x51\xb5\xc5\xe1\x91\xb5\x3d\xeb\x3e\xcc\x19\x60\x2c\x66\x50\x78\x0f\x80\xa6\x26\x39\xee\x5b\x39\xb1\x88\x52\x1b\x8e\x06\x56\x46\xfb\x84\x44\x62\x98\xab\xe0\xfa\x22\x84\x69\x7e\x6b\x62\x88\x50\xb8\xd0\xb8\x1d\xf9\xee\xe9\x77\xf1\x1d\xfc\x8c\xf4\x8f\x6d\xd1\x5c\xeb\x04\x0d\xae\x1f\x72\xeb\x75\x14\xa0\xbc\xbc\xa2\xfa\xff\xd6\x4d\xa6\xf4\xf4\x2e"

///|
fn play_random300(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_RANDOM300_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_uint(1000, 378, 8589934L, 7656869L, 11, 88)
  dec.expect_bit(6, 0, 8455717L, 7522652L, 11, 88)
  dec.expect_bin(4, 0, 2029372160L, 1790507685L, 12, 89)
  dec.expect_bit(7, 0, 2013517690L, 1774653215L, 12, 89)
  dec.expect_uint(100, 11, 20135176L, 2757727L, 18, 142)
  dec.expect_bit(1, 1, 10067588L, 2757727L, 19, 150)
  dec.expect_bin(7, 0, 9988935L, 2679074L, 19, 150)
  dec.expect_bit(2, 0, 1917875712L, 46551317L, 20, 154)
  dec.expect_bit(8, 0, 1910384010L, 39059615L, 20, 154)
  dec.expect_bin(3, 1, 238798001L, 39059615L, 23, 178)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    13,
    14924875L,
    9209865L,
    27,
    210,
  )
  dec.expect_bin(2, 0, 11193657L, 5478647L, 27, 213)
  dec.expect_bit(5, 0, 10843856L, 5128846L, 27, 214)
  dec.expect_uint(10, 5, 277602560L, 202574358L, 30, 240)
  dec.expect_bin(6, 0, 273265020L, 198236818L, 30, 240)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 2, 34158127L, 27446183L, 33, 264)
  dec.expect_uint(5, 0, 1748896512L, 30638979L, 36, 283)
  dec.expect_bin(4, 1, 109306032L, 30638979L, 40, 315)
  dec.expect_bit(1, 1, 54653016L, 30638979L, 41, 323)
  dec.expect_bit(5, 0, 52945110L, 28931073L, 41, 323)
  dec.expect_bin(6, 0, 52117843L, 28103806L, 41, 323)
  dec.expect_bit(1, 0, 26058922L, 2044885L, 42, 331)
  dec.expect_uint(65536, 60171, 26058752L, 2315774L, 58, 459)
  dec.expect_bit(4, 0, 24430080L, 687102L, 58, 460)
  dec.expect_bit(4, 1, 390881280L, 175898156L, 62, 492)
  dec.expect_bit(2, 0, 293160960L, 78177836L, 62, 495)
  dec.expect_uint(65536, 47933, 293160960L, 78580800L, 78, 623)
  dec.expect_bit(3, 0, 256515840L, 41935680L, 79, 625)
  dec.expect_bit(5, 0, 248499720L, 33919560L, 79, 625)
  dec.expect_bit(6, 0, 244616912L, 30036752L, 79, 626)
  dec.expect_bit(2, 1, 61154228L, 30036752L, 81, 642)
  dec.expect_bin(8, 0, 60915345L, 29797869L, 81, 642)
  dec.expect_uint(1000, 509, 62377216L, 18234174L, 91, 721)
  dec.expect_ctx([4, 4, 4, 4], 2, 15594304L, 2639870L, 93, 737)
  dec.expect_bit(7, 0, 15472474L, 2518040L, 93, 737)
  dec.expect_bit(2, 1, 990238208L, 644618272L, 95, 753)
  dec.expect_uint(65536, 22895, 990238208L, 642735275L, 111, 881)
  dec.expect_uint(65536, 23002, 990238208L, 160687962L, 127, 1009)
  dec.expect_bin(2, 1, 247559552L, 160687962L, 129, 1025)
  dec.expect_bit(6, 0, 243691434L, 156819844L, 129, 1026)
  dec.expect_uint(10, 3, 24369143L, 10604986L, 132, 1052)
  dec.expect_uint(100, 56, 62384896L, 32325971L, 139, 1105)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    7,
    998158336L,
    290182101L,
    143,
    1137,
  )
  dec.expect_bin(4, 0, 935773440L, 227797205L, 143, 1138)
  dec.expect_bit(3, 0, 818801760L, 110825525L, 143, 1140)
  dec.expect_bit(4, 0, 767626650L, 59650415L, 143, 1140)
  dec.expect_bit(5, 0, 743638318L, 35662083L, 143, 1141)
  dec.expect_bin(8, 0, 740733481L, 32757246L, 143, 1141)
  dec.expect_bin(5, 0, 717585560L, 9609325L, 143, 1141)
  dec.expect_bin(1, 1, 358792780L, 9609325L, 144, 1149)
  dec.expect_bit(3, 1, 44849097L, 9609325L, 147, 1173)
  dec.expect_uint(10, 7, 1148136704L, 163713952L, 150, 1200)
  dec.expect_bit(5, 0, 1112257432L, 127834680L, 150, 1200)
  dec.expect_bit(1, 1, 556128716L, 127834680L, 151, 1208)
  dec.expect_uint(65536, 50532, 556128512L, 470224385L, 167, 1336)
  dec.expect_bit(3, 0, 486612448L, 400708321L, 168, 1338)
  dec.expect_bin(3, 0, 425785892L, 339881765L, 168, 1339)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 1, 53223236L, 20542349L, 171, 1363)
  dec.expect_bin(3, 0, 46570332L, 13889445L, 171, 1365)
  dec.expect_bin(5, 0, 45115010L, 12434123L, 171, 1365)
  dec.expect_bit(7, 0, 44762549L, 12081662L, 171, 1365)
  dec.expect_uint(65536, 47869, 44762368L, 4302245L, 187, 1493)
  dec.expect_bin(1, 1, 22381184L, 4302245L, 188, 1501)
  dec.expect_bit(6, 0, 22031478L, 3952539L, 188, 1501)
  dec.expect_bin(6, 0, 21687237L, 3608298L, 188, 1502)
  dec.expect_ctx([4, 4, 4, 4], 3, 1387982848L, 923724336L, 190, 1518)
  dec.expect_ctx([1, 2, 3, 10], 2, 260246784L, 56235056L, 193, 1537)
  dec.expect_bin(8, 0, 259230195L, 55218467L, 193, 1537)
  dec.expect_bin(4, 0, 243028308L, 39016580L, 193, 1538)
  dec.expect_uint(10, 8, 24302830L, 14713750L, 196, 1564)
  dec.expect_bin(3, 0, 21264977L, 11675897L, 196, 1566)
  dec.expect_bit(2, 0, 15948733L, 6359653L, 197, 1569)
  dec.expect_bit(4, 0, 14951938L, 5362858L, 197, 1570)
  dec.expect_bin(6, 0, 14718314L, 5129234L, 197, 1570)
  dec.expect_ctx([4, 4, 4, 4], 2, 941971456L, 371112669L, 199, 1586)
  dec.expect_uint(100, 60, 9419714L, 3743823L, 205, 1639)
  dec.expect_bin(3, 0, 2110016000L, 656987993L, 206, 1641)
  dec.expect_bin(7, 0, 2093531500L, 640503493L, 206, 1641)
  dec.expect_ctx([4, 4, 4, 4], 2, 523382872L, 117120621L, 208, 1657)
  dec.expect_bit(7, 0, 519293944L, 113031693L, 208, 1657)
  dec.expect_uint(70000, 55215, 970359296L, 795693971L, 224, 1786)
  dec.expect_bin(7, 0, 962778364L, 788113039L, 224, 1786)
  dec.expect_ctx([1, 2, 3, 10], 1, 120347294L, 5855628L, 227, 1810)
  dec.expect_bit(2, 1, 30086823L, 5855628L, 229, 1826)
  dec.expect_bit(5, 0, 29146610L, 4915415L, 229, 1826)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 6, 932691456L, 325654869L, 232, 1850)
  dec.expect_uint(5, 3, 186538291L, 139116578L, 234, 1869)
  dec.expect_uint(100, 25, 477537792L, 276047457L, 241, 1922)
  dec.expect_bin(3, 0, 417845568L, 216355233L, 241, 1923)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 3, 52230696L, 7432449L, 244, 1947)
  dec.expect_bit(8, 0, 52026670L, 7228423L, 244, 1947)
  dec.expect_bin(3, 0, 45523337L, 725090L, 244, 1949)
  dec.expect_bit(3, 1, 1456746752L, 185623119L, 247, 1973)
  dec.expect_bin(1, 1, 728373376L, 185623119L, 248, 1981)
  dec.expect_bin(7, 0, 722682959L, 179932702L, 248, 1981)
  dec.expect_bit(8, 0, 719859979L, 177109722L, 248, 1981)
  dec.expect_bit(8, 0, 717048026L, 174297769L, 248, 1981)
  dec.expect_bin(4, 0, 672232525L, 129482268L, 248, 1982)
  dec.expect_bin(7, 0, 666980709L, 124230452L, 248, 1982)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    13,
    41686294L,
    40857864L,
    252,
    2014,
  )
  dec.expect_uint(100, 1, 106716672L, 1379437L, 259, 2067)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 7, 13339584L, 1379437L, 262, 2091)
  dec.expect_bin(4, 0, 12505860L, 545713L, 262, 2092)
  dec.expect_uint(5, 4, 640300032L, 139702756L, 264, 2110)
  dec.expect_uint(1000, 783, 655667200L, 357876865L, 274, 2190)
  dec.expect_bin(6, 0, 645422400L, 347632065L, 274, 2190)
  dec.expect_bin(7, 0, 640380038L, 342589703L, 274, 2190)
  dec.expect_bit(5, 0, 620368162L, 322577827L, 274, 2191)
  dec.expect_uint(5, 2, 124073632L, 74430563L, 277, 2209)
  dec.expect_bin(6, 0, 122134982L, 72491913L, 277, 2210)
  dec.expect_bit(7, 0, 121180803L, 71537734L, 277, 2210)
  dec.expect_bit(2, 0, 90885603L, 41242534L, 277, 2213)
  dec.expect_bit(4, 0, 85205253L, 35562184L, 277, 2214)
  dec.expect_uint(70000, 40773, 159215616L, 28629057L, 293, 2343)
  dec.expect_bit(2, 1, 39803904L, 28629057L, 295, 2359)
  dec.expect_bin(2, 0, 29852928L, 18678081L, 296, 2362)
  dec.expect_uint(100, 37, 76423424L, 43336563L, 302, 2415)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    6,
    1222774784L,
    89187096L,
    306,
    2447,
  )
  dec.expect_bit(8, 0, 1217998320L, 84410632L, 306, 2447)
  dec.expect_bin(7, 0, 1208482709L, 74895021L, 306, 2447)
  dec.expect_bin(1, 1, 604241354L, 74895021L, 307, 2455)
  dec.expect_bit(1, 1, 302120677L, 74895021L, 308, 2463)
  dec.expect_bit(3, 0, 264355593L, 37129937L, 309, 2465)
  dec.expect_uint(65536, 56508, 264355584L, 252818449L, 325, 2593)
  dec.expect_uint(70000, 2748, 493978112L, 10390385L, 341, 2721)
  dec.expect_uint(1000, 976, 505833472L, 130771279L, 351, 2801)
  dec.expect_bin(1, 1, 252916736L, 130771279L, 352, 2809)
  dec.expect_uint(100, 48, 647466752L, 456643307L, 358, 2862)
  dec.expect_bin(2, 0, 485600064L, 294776619L, 359, 2866)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 3, 60700008L, 51976587L, 362, 2890)
  dec.expect_bin(8, 0, 60462899L, 51739478L, 362, 2890)
  dec.expect_bit(3, 0, 52905037L, 44181616L, 362, 2891)
  dec.expect_uint(65536, 10900, 52904960L, 41737443L, 378, 3019)
  dec.expect_uint(70000, 14498, 98858752L, 8040363L, 394, 3148)
  dec.expect_ctx([4, 4, 4, 4], 3, 24714688L, 8040363L, 396, 3164)
  dec.expect_bit(2, 0, 18536016L, 1861691L, 396, 3167)
  dec.expect_bin(2, 1, 1186305024L, 476593041L, 398, 3183)
  dec.expect_bin(8, 0, 1181671020L, 471959037L, 398, 3183)
  dec.expect_bit(1, 1, 590835510L, 471959037L, 399, 3191)
  dec.expect_bit(5, 0, 572371901L, 453495428L, 399, 3192)
  dec.expect_uint(10, 2, 57237190L, 52835098L, 403, 3218)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1],
    0,
    1831591424L,
    704656071L,
    406,
    3242,
  )
  dec.expect_bin(6, 0, 1802972808L, 676037455L, 406, 3243)
  dec.expect_uint(65536, 41143, 1802972672L, 1783184700L, 422, 3371)
  dec.expect_bin(8, 0, 1795929810L, 1776141838L, 422, 3371)
  dec.expect_bin(3, 0, 1571438584L, 1551650612L, 422, 3372)
  dec.expect_bit(1, 0, 785719292L, 765931320L, 423, 3380)
  dec.expect_bin(1, 0, 392859646L, 373071674L, 424, 3388)
  dec.expect_bit(4, 0, 368305919L, 348517947L, 424, 3389)
  dec.expect_bin(6, 0, 362551140L, 342763168L, 424, 3389)
  dec.expect_bin(3, 0, 317232248L, 297444276L, 424, 3391)
  dec.expect_bit(3, 0, 277578217L, 257790245L, 424, 3392)
  dec.expect_bit(1, 0, 138789109L, 119001137L, 425, 3400)
  dec.expect_uint(100, 14, 355300096L, 263782999L, 432, 3453)
  dec.expect_ctx([1, 2, 3, 10], 2, 66618768L, 41720439L, 435, 3473)
  dec.expect_ctx([1, 2, 3, 10], 2, 12491019L, 83709L, 437, 3492)
  dec.expect_bit(4, 1, 199856128L, 21429541L, 441, 3524)
  dec.expect_bit(7, 0, 198294752L, 19868165L, 441, 3524)
  dec.expect_bit(8, 0, 197520164L, 19093577L, 441, 3524)
  dec.expect_bin(3, 1, 24690020L, 19093577L, 444, 3548)
  dec.expect_bin(7, 0, 24497130L, 18900687L, 444, 3548)
  dec.expect_ctx([4, 4, 4, 4], 0, 1567818240L, 135128861L, 446, 3564)
  dec.expect_bit(1, 1, 783909120L, 135128861L, 447, 3572)
  dec.expect_bit(4, 0, 734914800L, 86134541L, 447, 3573)
  dec.expect_bit(7, 0, 729173279L, 80393020L, 447, 3573)
  dec.expect_uint(1000, 890, 746673408L, 420431119L, 457, 3653)
  dec.expect_ctx([4, 4, 4, 4], 1, 186668352L, 47094415L, 459, 3669)
  dec.expect_bit(3, 0, 163334808L, 23760871L, 459, 3670)
  dec.expect_bin(6, 0, 160782702L, 21208765L, 459, 3670)
  dec.expect_bit(1, 1, 80391351L, 21208765L, 460, 3678)
  dec.expect_bin(4, 0, 75366892L, 16184306L, 460, 3679)
  dec.expect_ctx([1, 2, 3, 10], 3, 47104300L, 16184306L, 461, 3685)
  dec.expect_bit(3, 0, 41216263L, 10296269L, 461, 3686)
  dec.expect_bin(7, 0, 40894261L, 9974267L, 461, 3686)
  dec.expect_bin(3, 0, 35782479L, 4862485L, 461, 3688)
  dec.expect_bit(3, 0, 31309670L, 389676L, 462, 3689)
  dec.expect_bit(7, 0, 31065064L, 145070L, 462, 3689)
  dec.expect_bin(5, 1, 248520448L, 37137975L, 467, 3729)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 6, 31065056L, 6072919L, 470, 3753)
  dec.expect_bin(6, 0, 30579665L, 5587528L, 470, 3754)
  dec.expect_uint(100, 81, 78283776L, 21299237L, 476, 3807)
  dec.expect_bin(3, 0, 68498304L, 11513765L, 476, 3808)
  dec.expect_uint(10, 8, 1753556480L, 1193967457L, 480, 3835)
  dec.expect_uint(5, 1, 350711296L, 141833569L, 482, 3853)
  dec.expect_bit(4, 0, 328791840L, 119914113L, 482, 3854)
  dec.expect_uint(70000, 45003, 614384640L, 593165578L, 498, 3983)
  dec.expect_bit(7, 0, 609584760L, 588365698L, 498, 3983)
  dec.expect_bin(1, 0, 304792380L, 283573318L, 499, 3991)
  dec.expect_uint(100, 6, 780268288L, 29818720L, 506, 4044)
  dec.expect_bin(2, 1, 195067072L, 29818720L, 508, 4060)
  dec.expect_bin(8, 0, 194305092L, 29056740L, 508, 4060)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 6, 24288136L, 4768604L, 511, 4084)
  dec.expect_bit(3, 0, 21252119L, 1732587L, 511, 4086)
  dec.expect_uint(100, 91, 54405376L, 8299417L, 518, 4139)
  dec.expect_uint(1000, 846, 55710976L, 7633907L, 528, 4219)
  dec.expect_bit(7, 0, 55275734L, 7198665L, 528, 4219)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    13,
    884411648L,
    74035023L,
    532,
    4251,
  )
  dec.expect_bit(8, 0, 880956915L, 70580290L, 532, 4251)
  dec.expect_bit(1, 1, 440478457L, 70580290L, 533, 4259)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    13,
    27529903L,
    15520484L,
    537,
    4291,
  )
  dec.expect_bit(4, 0, 25809285L, 13799866L, 537, 4292)
  dec.expect_bin(2, 0, 19356964L, 7347545L, 537, 4295)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    9,
    309711360L,
    22703593L,
    541,
    4327,
  )
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 7, 38713920L, 22703593L, 544, 4351)
  dec.expect_bin(8, 0, 38562694L, 22552367L, 544, 4351)
  dec.expect_uint(1000, 415, 39488000L, 8158156L, 554, 4431)
  dec.expect_bin(3, 0, 34552000L, 3222156L, 554, 4432)
  dec.expect_uint(5, 4, 1769062400L, 824872151L, 557, 4451)
  dec.expect_uint(100, 53, 17690624L, 11103447L, 563, 4504)
  dec.expect_bit(2, 0, 13267968L, 6680791L, 564, 4507)
  dec.expect_ctx([4, 4, 4, 4], 1, 849149952L, 11982787L, 566, 4523)
  dec.expect_bin(5, 1, 26535936L, 11982787L, 571, 4563)
  dec.expect_bin(2, 0, 19901952L, 5348803L, 571, 4567)
  dec.expect_bit(1, 1, 9950976L, 5348803L, 572, 4575)
  dec.expect_bit(8, 0, 9912105L, 5309932L, 572, 4575)
  dec.expect_bit(4, 0, 9292599L, 4690426L, 572, 4575)
  dec.expect_uint(65536, 32451, 9292544L, 2011128L, 588, 4703)
  dec.expect_uint(1000, 781, 9515520L, 1010751L, 598, 4783)
  dec.expect_bit(7, 0, 9441180L, 936411L, 598, 4783)
  dec.expect_bin(2, 1, 604235520L, 239721388L, 600, 4799)
  dec.expect_bit(2, 0, 453176640L, 88662508L, 601, 4802)
  dec.expect_bin(5, 0, 439014870L, 74500738L, 601, 4803)
  dec.expect_bit(3, 0, 384138012L, 19623880L, 601, 4804)
  dec.expect_bit(4, 1, 24008625L, 19623880L, 605, 4836)
  dec.expect_bin(6, 0, 23633491L, 19248746L, 605, 4837)
  dec.expect_bit(5, 0, 22894945L, 18510200L, 605, 4837)
  dec.expect_bit(7, 0, 22716079L, 18331334L, 605, 4837)
  dec.expect_bin(7, 0, 22538610L, 18153865L, 605, 4837)
  dec.expect_ctx([4, 4, 4, 4], 0, 1442471424L, 319976940L, 607, 4853)
  dec.expect_ctx([1, 2, 3, 10], 3, 901544640L, 319976940L, 608, 4859)
  dec.expect_bit(4, 0, 845198100L, 263630400L, 608, 4859)
  dec.expect_bit(3, 0, 739548338L, 157980638L, 608, 4861)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    12,
    46221771L,
    19315325L,
    612,
    4893,
  )
  dec.expect_bin(7, 0, 45860664L, 18954218L, 612, 4893)
  dec.expect_bin(8, 0, 45681521L, 18775075L, 612, 4893)
  dec.expect_bit(2, 0, 34261141L, 7354695L, 612, 4896)
  dec.expect_bit(1, 1, 17130570L, 7354695L, 613, 4904)
  dec.expect_bin(8, 0, 17063654L, 7287779L, 613, 4904)
  dec.expect_bit(4, 0, 15997176L, 6221301L, 614, 4905)
  dec.expect_bit(3, 0, 13997529L, 4221654L, 614, 4907)
  dec.expect_uint(65536, 45677, 13997312L, 2950627L, 630, 5035)
  dec.expect_ctx([1, 2, 3, 10], 3, 8748320L, 2950627L, 630, 5040)
  dec.expect_bin(5, 0, 8474935L, 2677242L, 630, 5040)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 5, 271197696L, 142978568L, 633, 5064)
  dec.expect_bit(6, 0, 266960232L, 138741104L, 634, 5065)
  dec.expect_bit(2, 0, 200220174L, 72001046L, 634, 5068)
  dec.expect_bit(2, 0, 150165131L, 21946003L, 634, 5071)
  dec.expect_uint(1000, 852, 153768960L, 82494418L, 644, 5151)
  dec.expect_bit(7, 0, 152567640L, 81293098L, 644, 5151)
  dec.expect_bit(6, 0, 150183771L, 78909229L, 644, 5151)
  dec.expect_bin(5, 0, 145490529L, 74215987L, 644, 5152)
  dec.expect_bin(1, 0, 72745265L, 1470723L, 645, 5160)
  dec.expect_ctx([1, 2, 3, 10], 3, 45465790L, 1470723L, 646, 5165)
  dec.expect_bit(1, 1, 22732895L, 1470723L, 647, 5173)
  dec.expect_bit(3, 1, 727452416L, 376505187L, 650, 5197)
  dec.expect_ctx([4, 4, 4, 4], 1, 181863104L, 12778979L, 652, 5213)
  dec.expect_uint(100, 92, 465569536L, 12431911L, 659, 5266)
  dec.expect_bit(2, 1, 116392384L, 12431911L, 661, 5282)
  dec.expect_bin(7, 0, 115483069L, 11522596L, 661, 5282)
  dec.expect_bin(1, 1, 57741534L, 11522596L, 662, 5290)
  dec.expect_bin(1, 1, 28870767L, 11522596L, 663, 5298)
  dec.expect_bit(3, 0, 25261922L, 7913751L, 663, 5300)
  dec.expect_bit(8, 0, 25163243L, 7815072L, 663, 5300)
  dec.expect_bit(5, 0, 24376892L, 7028721L, 663, 5300)
  dec.expect_bin(4, 0, 22853337L, 5505166L, 663, 5301)
  dec.expect_bit(6, 0, 22496254L, 5148083L, 663, 5301)
  dec.expect_bin(8, 0, 22408379L, 5060208L, 663, 5301)
  dec.expect_bit(4, 0, 21007856L, 3659685L, 663, 5302)
  dec.expect_bin(4, 0, 19694865L, 2346694L, 663, 5303)
  dec.expect_bin(6, 0, 19387133L, 2038962L, 663, 5303)
  dec.expect_bit(7, 0, 19235672L, 1887501L, 663, 5303)
  dec.expect_bin(2, 1, 1231083008L, 483200315L, 665, 5319)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    9,
    76942688L,
    21544187L,
    669,
    5351,
  )
  dec.expect_bit(1, 1, 38471344L, 21544187L, 670, 5359)
  dec.expect_bit(8, 0, 38321066L, 21393909L, 670, 5359)
  dec.expect_bit(8, 0, 38171375L, 21244218L, 670, 5359)
  dec.expect_bin(6, 0, 37574948L, 20647791L, 670, 5359)
  dec.expect_bin(6, 0, 36987840L, 20060683L, 670, 5359)
  dec.expect_bit(5, 0, 35831970L, 18904813L, 670, 5360)
  dec.expect_bit(1, 0, 17915985L, 988828L, 671, 5368)
  dec.expect_uint(10, 9, 458649088L, 253140182L, 675, 5394)
  dec.expect_bin(8, 0, 456857490L, 251348584L, 675, 5394)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    7,
    28553593L,
    22919840L,
    679,
    5426,
  )
  dec.expect_bit(7, 0, 28330519L, 22696766L, 679, 5426)
  dec.expect_bin(5, 0, 27445191L, 21811438L, 679, 5427)
  dec.expect_ctx([1, 2, 3, 10], 2, 1317368832L, 1192498930L, 681, 5446)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 0, 164671104L, 39801202L, 684, 5470)
  dec.expect_bin(6, 0, 162098118L, 37228216L, 684, 5470)
  dec.expect_bit(5, 0, 157032552L, 32162650L, 684, 5471)
  dec.expect_uint(65536, 51976, 157032448L, 67951160L, 700, 5599)
  dec.expect_uint(1000, 566, 160801024L, 28986620L, 710, 5678)
  dec.expect_bin(1, 1, 80400512L, 28986620L, 711, 5686)
  dec.expect_ctx(
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    10,
    1286408192L,
    988533972L,
    715,
    5718,
  )
  dec.expect_bit(5, 0, 1246207936L, 948333716L, 715, 5719)
  dec.expect_uint(100, 23, 12462079L, 1215712L, 722, 5772)
  dec.expect_bit(3, 1, 398786304L, 311222492L, 725, 5796)
  dec.expect_uint(5, 1, 79757260L, 71950712L, 727, 5815)
  dec.expect_ctx([4, 4, 4, 4], 0, 19939324L, 12132776L, 729, 5831)
  dec.expect_uint(65536, 25717, 19939072L, 15434626L, 745, 5959)
  dec.expect_uint(5, 1, 1020880384L, 888623165L, 748, 5977)
}

///|
const RANGE_SHORT_BITS : Bytes = b"\x5a\xa5"

///|
fn play_short(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_SHORT_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_bit(2, 0, 1610612736L, 850231295L, 2, 12)
  dec.expect_ctx([1, 1, 1, 1, 1, 1, 1, 1], 3, 201326592L, 44924927L, 5, 36)
}

///|
const RANGE_LONG_BITS : Bytes = b"\x29\x7d\x86\x55\x4a\x62\xb6\x6c\x97\xd7\x59\x94\x11\xec\x79\xc5\xe7\x45\x3a\xa1\x6c\x3f\xef\xdb\x0a\x7a\xda\x31\xcf\xc6\x9a\x17\x12\xc4\x79\xc9\x3d\x85\x46\x1d\xdc\x50\xc0\x99\x85\xe9\x6c\xaa\x75\xc0\x04\x92\xca\xd9\x89\xb4\x02\xc6\x9f\xeb\x4b\x60\x42\x85\xb9\x79\x8c\xc5\x3a\xf7\x50\xe4\xfa\x84\x7c\x10\x41\x7e\x67\xf6\x82\x3c\xd9\x56\x4f\x4c\x80\x22\xca\xa6\xe8\xc5\x44\x68\x36\x25\x21\x0a\xd3\xf6\xff\x49\xb9\xa1\x53\x1b\xe3\x9c\xb2\x2e\x9c\x18\xf0\x51\xd9\xe8\x71\x2d\x1b\x98\x52\xad\x57\x7c\x34\x67\x8d\x72\xf8\x0e\x73\x2a\x6e\x2c\x77\x08\x96\x0c\x9b\xd2\xc8\x95\x8f\x40\x5d\xc6\x3f\x3f\xa2\x3f\xcc\xac\x16\xca\x76\xc5\x20\x45\x2b\x0e\xba\x79\x06\x6a\x24\x35\x27\x4e\x56\x8a\x5f\x95\x43\xd1\xe9\xcf\x43\x3d\x17\xcc\xf1\x81\x67\x00\x84\x0c\xd9\x3b\x88\x04\x94\xc8\x8c\x2e\x36\x98\x0c\x9f\x11\x49\x66\xa7\xaa\x4d\xbc\xd5\x03\xc6\x05\x23\xee\xee\x75\x82\x8e\xb3\x78\x30\xd7\xcd\x98\xb1\x1a\xa9\x0a\x7d\xbd\x65\x1d\xab\x10\x72\x52\x8b\xfa\x9e\x21\x4f\xc7\x34\xca\xbb\x9b\xf2\xe3\x57\x8d\x89\x6c\xda\x40\x91\x88\xbd\x78\x2d"

///|
fn play_long(dec : RangeDecoder) -> Unit raise {
  // 比特流见 RANGE_LONG_BITS；轨迹由 tools/gen_range_goldens.py
  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。
  dec.expect_uint(65536, 10541, 2147483648L, 1094505818L, 17, 136)
  dec.expect_bit(4, 0, 2013265920L, 960288090L, 18, 137)
  dec.expect_ctx([4, 4, 4, 4], 2, 503316480L, 456971610L, 20, 153)
  dec.expect_bit(4, 0, 471859200L, 425514330L, 20, 154)
  dec.expect_ctx([4, 4, 4, 4], 0, 117964800L, 71619930L, 22, 170)
  dec.expect_bit(4, 0, 110592000L, 64247130L, 22, 171)
  dec.expect_ctx([4, 4, 4, 4], 1, 27648000L, 8951130L, 24, 187)
  dec.expect_bit(4, 0, 25920000L, 7223130L, 24, 187)
  dec.expect_ctx([4, 4, 4, 4], 2, 1658880000L, 190241486L, 26, 203)
  dec.expect_bit(4, 0, 1555200000L, 86561486L, 26, 204)
  dec.expect_ctx([4, 4, 4, 4], 3, 388800000L, 86561486L, 28, 220)
  dec.expect_bit(4, 0, 364500000L, 62261486L, 28, 221)
  dec.expect_ctx([4, 4, 4, 4], 3, 91125000L, 62261486L, 30, 237)
  dec.expect_bit(4, 0, 85429688L, 56566174L, 30, 238)
  dec.expect_ctx([4, 4, 4, 4], 1, 21357420L, 13851334L, 32, 254)
  dec.expect_bit(4, 0, 20022582L, 12516496L, 32, 254)
  dec.expect_ctx([4, 4, 4, 4], 1, 1281444864L, 641333412L, 34, 270)
  dec.expect_bit(4, 0, 1201354560L, 561243108L, 34, 271)
  dec.expect_ctx([4, 4, 4, 4], 2, 300338640L, 260904468L, 36, 287)
  dec.expect_bit(4, 0, 281567475L, 242133303L, 36, 288)
  dec.expect_ctx([4, 4, 4, 4], 0, 70391871L, 30957699L, 38, 304)
  dec.expect_bit(4, 0, 65992380L, 26558208L, 39, 305)
  dec.expect_ctx([4, 4, 4, 4], 2, 16498092L, 10060116L, 41, 321)
  dec.expect_bit(4, 0, 15466962L, 9028986L, 41, 321)
  dec.expect_ctx([4, 4, 4, 4], 1, 989885440L, 331649737L, 43, 337)
  dec.expect_bit(4, 0, 928017600L, 269781897L, 43, 338)
  dec.expect_ctx([4, 4, 4, 4], 2, 232004400L, 37777497L, 45, 354)
  dec.expect_bit(4, 0, 217504125L, 23277222L, 45, 355)
  dec.expect_ctx([4, 4, 4, 4], 3, 54376028L, 23277222L, 47, 371)
  dec.expect_bit(4, 0, 50977527L, 19878721L, 47, 372)
  dec.expect_ctx([4, 4, 4, 4], 2, 12744380L, 7134341L, 49, 388)
  dec.expect_bit(4, 0, 11947857L, 6337818L, 49, 388)
  dec.expect_ctx([4, 4, 4, 4], 1, 764662784L, 93156020L, 51, 404)
  dec.expect_bit(4, 0, 716871360L, 45364596L, 51, 405)
  dec.expect_ctx([4, 4, 4, 4], 3, 179217840L, 45364596L, 53, 421)
  dec.expect_bit(4, 0, 168016725L, 34163481L, 53, 422)
  dec.expect_ctx([4, 4, 4, 4], 3, 42004180L, 34163481L, 55, 438)
  dec.expect_bit(4, 0, 39378919L, 31538220L, 55, 439)
  dec.expect_ctx([4, 4, 4, 4], 0, 9844735L, 2004036L, 57, 455)
  dec.expect_bit(4, 0, 9229440L, 1388741L, 57, 455)
  dec.expect_ctx([4, 4, 4, 4], 3, 590684160L, 355517716L, 59, 471)
  dec.expect_bit(4, 0, 553766400L, 318599956L, 59, 472)
  dec.expect_ctx([4, 4, 4, 4], 1, 138441600L, 41716756L, 61, 488)
  dec.expect_bit(4, 0, 129789000L, 33064156L, 62, 489)
  dec.expect_ctx([4, 4, 4, 4], 2, 32447248L, 616908L, 64, 505)
  dec.expect_bit(4, 1, 519155968L, 157928531L, 68, 537)
  dec.expect_ctx([4, 4, 4, 4], 2, 129788992L, 28139539L, 70, 553)
  dec.expect_bit(4, 0, 121677180L, 20027727L, 70, 554)
  dec.expect_ctx([4, 4, 4, 4], 3, 30419292L, 20027727L, 72, 570)
  dec.expect_bit(4, 0, 28518087L, 18126522L, 72, 570)
  dec.expect_ctx([4, 4, 4, 4], 1, 1825157120L, 990075445L, 74, 586)
  dec.expect_bit(4, 0, 1711084800L, 876003125L, 74, 587)
  dec.expect_ctx([4, 4, 4, 4], 1, 427771200L, 20460725L, 76, 603)
  dec.expect_bit(4, 1, 26735700L, 20460725L, 80, 635)
  dec.expect_ctx([4, 4, 4, 4], 0, 1711085568L, 104692215L, 82, 651)
  dec.expect_bit(4, 1, 106942848L, 104692215L, 86, 683)
  dec.expect_ctx([4, 4, 4, 4], 0, 26735712L, 24485079L, 88, 699)
  dec.expect_bit(4, 0, 25064730L, 22814097L, 88, 700)
  dec.expect_ctx([4, 4, 4, 4], 0, 1604144640L, 1027982601L, 90, 716)
  dec.expect_bit(4, 0, 1503885600L, 927723561L, 90, 717)
  dec.expect_ctx([4, 4, 4, 4], 1, 375971400L, 175780761L, 92, 733)
  dec.expect_bit(4, 0, 352473188L, 152282549L, 92, 733)
  dec.expect_ctx([4, 4, 4, 4], 2, 88118296L, 64164253L, 94, 749)
  dec.expect_bit(4, 0, 82610903L, 58656860L, 94, 750)
  dec.expect_ctx([4, 4, 4, 4], 1, 20652724L, 17351412L, 96, 766)
  dec.expect_bit(4, 0, 19361929L, 16060617L, 96, 767)
  dec.expect_ctx([4, 4, 4, 4], 0, 1239165184L, 394029507L, 98, 783)
  dec.expect_bit(4, 0, 1161717360L, 316581683L, 98, 784)
  dec.expect_ctx([4, 4, 4, 4], 2, 290429340L, 26152343L, 100, 800)
  dec.expect_bit(4, 0, 272277507L, 8000510L, 100, 800)
  dec.expect_ctx([4, 4, 4, 4], 3, 68069376L, 8000510L, 102, 816)
  dec.expect_bit(4, 0, 63815040L, 3746174L, 103, 817)
  dec.expect_ctx([4, 4, 4, 4], 3, 15953760L, 3746174L, 105, 833)
  dec.expect_bit(4, 0, 14956650L, 2749064L, 105, 834)
  dec.expect_ctx([4, 4, 4, 4], 3, 957224960L, 703760413L, 107, 850)
  dec.expect_bit(4, 0, 897398400L, 643933853L, 107, 851)
  dec.expect_ctx([4, 4, 4, 4], 1, 224349600L, 195234653L, 109, 867)
  dec.expect_bit(4, 0, 210327750L, 181212803L, 109, 867)
  dec.expect_ctx([4, 4, 4, 4], 0, 52581942L, 23466995L, 111, 883)
  dec.expect_bit(4, 0, 49295571L, 20180624L, 111, 884)
  dec.expect_ctx([4, 4, 4, 4], 2, 12323892L, 7856732L, 113, 900)
}
