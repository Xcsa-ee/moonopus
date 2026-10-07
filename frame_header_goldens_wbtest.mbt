// 由 tools/gen_frame_header_goldens.py 生成，请勿手改。
//
// 帧首四符号（RFC 6716 Table 56 前四项）金标：载荷与期望值由本
// 脚本内的独立参考端算出，MoonBit 端重放同一参数后逐项比对。
//
// frame_bytes 独立于载荷长度给定——门控条件只看它，用它触发
// 「预算不足」与「空帧」两类分支。

///|

///|
const FRAME_HEADER_H0_BITS : Bytes = b"\xb4\x19\xa2\x26\xb2\xda\x38\x71\x57\x1e\x35\x25\x68\xa2\xed\x18\x04\x7a\xac\xbc\xfc\x4e\xf3\x03\x74\xdc\x00\xf1\x02\x51\xa6\x33\xdb\x0a\x16\x30\x25\xea\x23\xe0\x8d\x49\xb5\x6b\x6e\xfb\x92\xe7\xd5\x90\xae\x9c\xc7\x1e\x76\x54\xa5\x6f\x3e\x78\xac\x12\xd2\xa4"

///|
fn play_h0(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H0_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 2, 0, 0)
  expect_frame_header(got, false, false, 0, 0.0, 0, false, false, "h0")
  expect_dec_state(dec, "h0", 1878990848L, 636694252L, 2, 10)
}

///|
test "金标：帧首符号 · 基线 2B lm=0" {
  let dec = RangeDecoder::new(FRAME_HEADER_H0_BITS)
  play_h0(dec)
}

///|
const FRAME_HEADER_H1_BITS : Bytes = b"\x99\x67\xd9\xe5\x6f\x95\x02\x1d\x46\x17\x33\xde\x90\x4f\x02\x4f\xe0\x88\x0f\x49\x7a\xc8\x36\x94\xbd\x93\x34\x50\x62\x9a\x92\xac\x6f\x81\x62\xd4\xb5\xce\xec\xd8\x8d\x11\x52\x1b\xa0\x2b\xe2\xc4\x95\x87\xe4\xc9\x82\x7e\x37\x5b\x5c\xe3\xe8\x7d\x08\x70\x83\x44"

///|
fn play_h1(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H1_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 2, 0, 3)
  expect_frame_header(got, false, false, 0, 0.0, 0, false, false, "h1")
  expect_dec_state(dec, "h1", 1644116992L, 860623629L, 2, 12)
}

///|
test "金标：帧首符号 · 基线 2B lm=3" {
  let dec = RangeDecoder::new(FRAME_HEADER_H1_BITS)
  play_h1(dec)
}

///|
const FRAME_HEADER_H2_BITS : Bytes = b"\x71\xcb\xfd\x42\x75\xb3\xb9\xe6\x43\x60\x9e\x8a\x15\x1a\x1d\x60\x32\x68\xba\xfc\xaf\xfc\x48\xad\x6c\xc1\x71\x3c\x45\x54\x3e\xc3\xdb\x39\xb3\xc4\x6a\xf3\xb0\xce\xb7\x30\xdc\x03\x9f\x5a\x67\x97\xed\xe7\xce\x92\x45\x81\x0e\x0e\x1b\x3a\x01\xdf\x71\x89\x47\xe0"

///|
fn play_h2(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H2_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 4, 0, 0)
  expect_frame_header(got, false, false, 0, 0.0, 0, false, false, "h2")
  expect_dec_state(dec, "h2", 939495424L, 1192886622L, 3, 18)
}

///|
test "金标：帧首符号 · 基线 4B lm=0" {
  let dec = RangeDecoder::new(FRAME_HEADER_H2_BITS)
  play_h2(dec)
}

///|
const FRAME_HEADER_H3_BITS : Bytes = b"\x79\xf8\xcf\x85\x41\x88\xb5\x35\x11\x95\x36\xbe\xef\x3b\xe6\x96\x79\xa4\x88\xb5\xd3\x83\x61\x0b\x4d\x9e\x68\x26\x2f\x6e\x3a\x43\x8d\x2f\x91\x8f\x99\x91\x20\xad\xad\xb8\x87\x22\xe6\x5d\x7f\x58\xd2\x92\x79\xc0\x5f\x54\xa7\x9a\x59\x97\xdb\xc0\x29\x05\x27\xf3"

///|
fn play_h3(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H3_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 4, 0, 3)
  expect_frame_header(got, false, false, 0, 0.0, 0, false, false, "h3")
  expect_dec_state(dec, "h3", 822058496L, 1124309053L, 3, 20)
}

///|
test "金标：帧首符号 · 基线 4B lm=3" {
  let dec = RangeDecoder::new(FRAME_HEADER_H3_BITS)
  play_h3(dec)
}

///|
const FRAME_HEADER_H4_BITS : Bytes = b"\xf0\x5d\x62\x22\x98\x75\x95\x76\x5e\x1a\xf6\xd8\x5a\xaf\x24\x1e\xac\x54\x25\xa3\x9f\xff\x53\x40\xdf\xae\x83\xe5\xd9\x2a\xd9\x15\x6b\x60\xa0\xe4\x8d\xd2\xf3\xbf\xf4\xee\x90\x2f\x13\x2a\x19\xd9\x04\x00\xd2\xb8\xf7\x5c\xe5\x60\x73\xa0\x14\x12\x0e\xcf\x29\x4e"

///|
fn play_h4(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H4_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 8, 0, 0)
  expect_frame_header(got, false, true, 845, 0.46875, 0, false, false, "h4")
  expect_dec_state(dec, "h4", 78291286L, 131157742L, 18, 143)
}

///|
test "金标：帧首符号 · 基线 8B lm=0" {
  let dec = RangeDecoder::new(FRAME_HEADER_H4_BITS)
  play_h4(dec)
}

///|
const FRAME_HEADER_H5_BITS : Bytes = b"\x46\xbf\xc3\x57\xc3\xfb\x17\x49\x05\xc1\x68\xa3\x3d\xe2\x6a\xb0\x89\x82\xbf\xcc\xe0\x93\x63\xa2\x9d\x49\x5c\x35\x85\xbc\x74\xfb\x9d\xad\x66\x0e\xae\x96\xf0\x15\xd1\x20\xe3\xe6\xee\x37\x30\x44\x78\x19\x09\xa4\x0e\xc3\xa0\x07\xc9\x46\x76\x03\xda\xdb\xd3\x84"

///|
fn play_h5(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H5_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 8, 0, 3)
  expect_frame_header(got, false, false, 0, 0.0, 0, false, false, "h5")
  expect_dec_state(dec, "h5", 822058496L, 1553997396L, 3, 20)
}

///|
test "金标：帧首符号 · 基线 8B lm=3" {
  let dec = RangeDecoder::new(FRAME_HEADER_H5_BITS)
  play_h5(dec)
}

///|
const FRAME_HEADER_H6_BITS : Bytes = b"\x1a\xf5\xd5\xf3\xca\xb0\x85\xc9\xe8\x6a\x9b\x86\x63\x04\x4a\x49\x67\x5a\x71\xb0\x46\x3f\xb3\xd9\x0a\x4a\xc2\x2f\xb8\x73\xb4\x1f\xdf\xca\xc1\x6d\x24\x4b\x50\xa7\x8c\x04\x5d\x67\xef\x6b\xcd\x38\x42\x8a\x46\x6a\x1b\x37\xea\xdd\x68\x28\xde\x43\x99\x46\x36\x2d"

///|
fn play_h6(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H6_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 32, 0, 0)
  expect_frame_header(got, false, false, 0, 0.0, 0, false, false, "h6")
  expect_dec_state(dec, "h6", 939495424L, 1921324294L, 3, 18)
}

///|
test "金标：帧首符号 · 基线 32B lm=0" {
  let dec = RangeDecoder::new(FRAME_HEADER_H6_BITS)
  play_h6(dec)
}

///|
const FRAME_HEADER_H7_BITS : Bytes = b"\xe1\x2b\x4d\xd3\x62\xcd\x39\x0d\x1d\x00\x1f\xdb\x1a\xe7\x5b\x8f\xfe\xe3\xae\xaa\xf4\xcd\x82\x01\x75\xdd\xa5\x5b\xb0\x8b\xec\x0a\xcd\x05\x49\x95\x3f\x0f\xab\xb1\x67\xf5\x14\x7f\x14\xc3\x9f\x3f\x93\x05\xfd\xc3\x3e\x19\xe9\xb8\xb4\x0d\x5f\x7d\x6b\xf0\xf1\xb6"

///|
fn play_h7(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H7_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 32, 0, 3)
  expect_frame_header(got, false, true, 437, 0.1875, 1, false, false, "h7")
  expect_dec_state(dec, "h7", 34252438L, 34938476L, 18, 144)
}

///|
test "金标：帧首符号 · 基线 32B lm=3" {
  let dec = RangeDecoder::new(FRAME_HEADER_H7_BITS)
  play_h7(dec)
}

///|
const FRAME_HEADER_H8_BITS : Bytes = b"\x4a\x40\x42\xe1\xd0\xb3\xbe\xa6\xcf\x66\x87\x34\xcc\x13\x34\x2e\x45\x1e\xd8\x21\x98\xa5\xb6\xeb\xfd\xae\x18\x29\x5d\x8c\x65\xc8\xc2\x85\xe4\x4e\x9f\x0b\x29\x52\x2b\x97\xcf\x49\xf1\xf8\x13\xd4\xb5\xa9\xa8\x20\x6a\xc6\xc0\xaf\x0b\xf9\x95\x34\xdb\x6b\x79\x41"

///|
fn play_h8(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H8_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 128, 0, 0)
  expect_frame_header(got, false, false, 0, 0.0, 0, false, false, "h8")
  expect_dec_state(dec, "h8", 939495424L, 1524620943L, 3, 18)
}

///|
test "金标：帧首符号 · 基线 128B lm=0" {
  let dec = RangeDecoder::new(FRAME_HEADER_H8_BITS)
  play_h8(dec)
}

///|
const FRAME_HEADER_H9_BITS : Bytes = b"\x77\x0a\x1a\xa4\x02\xa6\x0a\x9c\x02\xdf\x98\x3e\x85\xce\x31\xf1\x07\xa7\x24\x8c\x80\x7a\x78\xd1\x61\xa6\x5e\x2f\xd7\xa5\xab\x80\x47\x8c\x5f\x3a\x73\x3a\xc1\xc4\x10\x47\xc9\xcd\x67\xb9\xdf\xd6\x3b\x9a\x70\xa3\xc9\x3e\x77\xb6\x9b\x41\xc3\xce\xb6\x5d\x9f\x99"

///|
fn play_h9(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H9_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 128, 0, 3)
  expect_frame_header(got, false, false, 0, 0.0, 0, false, false, "h9")
  expect_dec_state(dec, "h9", 822058496L, 1148908205L, 3, 20)
}

///|
test "金标：帧首符号 · 基线 128B lm=3" {
  let dec = RangeDecoder::new(FRAME_HEADER_H9_BITS)
  play_h9(dec)
}

///|
const FRAME_HEADER_H10_BITS : Bytes = b"\xe0\xdb\xa3\xd1\x22\xf3\x08\x8a\x0d\x46\xf3\x27\x24\x5b\x84\xaa\x77\xa6\x59\x4d\x27\xe3\x0c\xb7\x7c\xa3\x12\xf0\xa1\xab\xd6\x02\xd5\xf6\xaa\x4d\x98\x6d\x4f\xb0\x05\x92\x5e\x3c\x8c\x44\x04\xf7\x62\xbc\x23\x1c\x11\xeb\x21\x87\xd3\x09\x29\x72\x89\xca\x17\xf8"

///|
fn play_h10(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H10_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 64, 5, 3)
  expect_frame_header(got, false, false, 0, 0.0, 0, true, false, "h10")
  expect_dec_state(dec, "h10", 234873856L, 261238295L, 5, 34)
}

///|
test "金标：帧首符号 · start=5（无后滤波）" {
  let dec = RangeDecoder::new(FRAME_HEADER_H10_BITS)
  play_h10(dec)
}

///|
const FRAME_HEADER_H11_BITS : Bytes = b"\xad\x4b\x53\xf8\xe4\x17\x4f\x9f\x6f\x02\x54\x01\xa3\xf4\x46\xcc\xc8\xd9\x23\xea\xb6\x34\x1c\xe5\x23\x2b\xe5\xba\xa9\x42\x9f\xd0\x18\xed\x80\xef\xec\x92\xd4\x98\x1d\x6a\x3c\x6b\xe7\x64\xf3\xc1\x01\xd3\x2b\x89\xc7\x65\x71\xdd\x0f\x39\x1e\xdd\xba\xab\x47\x44"

///|
fn play_h11(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H11_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 4, 5, 1)
  expect_frame_header(got, false, false, 0, 0.0, 0, false, false, "h11")
  expect_dec_state(dec, "h11", 1644116992L, 693786115L, 2, 12)
}

///|
test "金标：帧首符号 · start=5 小帧" {
  let dec = RangeDecoder::new(FRAME_HEADER_H11_BITS)
  play_h11(dec)
}

///|
const FRAME_HEADER_H12_BITS : Bytes = b"\x48\x25\x5f\xae\xfb\x6c\x5e\x6d\xc2\x52\x0a\x52\xe4\xd1\x7d\x9e\xa8\x17\xdc\xe3\x81\x5e\xc1\x34\xd8\x1c\xbf\x13\xd9\xee\xb9\x9b\xd8\xc2\x65\xbe\xc7\xae\x2a\xe1\x2b\x41\x9d\xe5\x71\xce\x09\xe6\x5b\x62\xb9\x6a\xda\xe2\xe6\xcb\xd4\x6c\x6c\x02\xdc\x07\x3d\x80"

///|
fn play_h12(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H12_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 0, 0, 3)
  expect_frame_header(got, true, false, 0, 0.0, 0, false, false, "h12")
  expect_dec_state(dec, "h12", 2147483648L, 1542279208L, 1, 8)
}

///|
test "金标：帧首符号 · 空帧 frame_bytes=0" {
  let dec = RangeDecoder::new(FRAME_HEADER_H12_BITS)
  play_h12(dec)
}

///|
const FRAME_HEADER_H13_BITS : Bytes = b"\xf8\xf6\xf9\x8e\x7b\x6d\x1e\xe8\xb4\xc7\xf0\x4b\x7b\x63\x7a\xe4\xb6\xa3\x7e\x11\x8d\x30\xcb\x98\xab\xcc\xd4\x30\xcb\x44\x1f\xb4\xb8\x19\xb6\xef\xd9\x49\xb9\xc3\x44\xb3\xa4\xc2\x3f\x19\x53\x49\x9a\x2d\x56\xdb\xe0\xca\x73\xd0\xf9\xcc\x51\x7c\x6c\xe1\x5b\x6a"

///|
fn play_h13(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_H13_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 2, 0, 0)
  expect_frame_header(got, false, false, 0, 0.0, 0, false, true, "h13")
  expect_dec_state(dec, "h13", 268427264L, 59015992L, 5, 33)
}

///|
test "金标：帧首符号 · 极小帧 2B" {
  let dec = RangeDecoder::new(FRAME_HEADER_H13_BITS)
  play_h13(dec)
}

///|
const FRAME_HEADER_Z0_BITS : Bytes = b"\xff\xfe\x87\x59\x80\x3f\x54\xeb\x12\xb1\xb9\x67\xf9\xa0\x11\x6e\xb5\x85\x7d\xad\x08\xae\x77\xfb\x91\xb6\x59\xbe\xd9\xcb\x9d\x68\x40\xe0\x94\x82\x8b\xe5\xdd\xac\x38\xb1\xb2\x09\x2c\x1a\xef\x93\xb1\xab\x24\x6f\x28\xad\x83\x13\x9f\x6a\x65\xa4\x2a\x2e\x5e\xcf"

///|
fn play_z0(dec : RangeDecoder) -> Unit raise {
  // 载荷见 FRAME_HEADER_Z0_BITS；期望值由
  // tools/gen_frame_header_goldens.py 的独立参考端算出。
  let got = celt_decode_frame_header(dec, 64, 0, 3)
  expect_frame_header(got, true, false, 0, 0.0, 0, false, false, "z0")
  expect_dec_state(dec, "z0", 16777216L, 12342079L, 487, 3896)
}

///|
test "金标：帧首符号 · 定向搜到的静音帧" {
  let dec = RangeDecoder::new(FRAME_HEADER_Z0_BITS)
  play_z0(dec)
}
