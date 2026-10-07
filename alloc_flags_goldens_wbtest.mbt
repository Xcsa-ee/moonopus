// 由 tools/gen_alloc_flags_goldens.py 生成，请勿手改。
//
// band boost 与 allocation trim（RFC 6716 §4.3.3）金标：载荷与
// 期望值由本脚本内的独立参考端算出，MoonBit 端重放同一参数后
// 逐项比对每带加成与 trim 值。
//
// frame_bytes 恒取载荷长度：trim 的门控条件由它决定，改写它就
// 等于改写被测条件。

///|

///|
const ALLOC_FLAGS_AF0_BITS : Bytes = b"\x59"

///|
fn play_af0(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF0_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 1, 0)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    3,
    "af0",
  )
  expect_dec_state(dec, "af0", 120529110L, 87130236L, 6, 42)
}

///|
test "金标：boost 与 trim · 基线 1B lm=0" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF0_BITS)
  play_af0(dec)
}

///|
const ALLOC_FLAGS_AF1_BITS : Bytes = b"\xa9"

///|
fn play_af1(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF1_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 1, 3)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    "af1",
  )
  expect_dec_state(dec, "af1", 554433906L, 235639544L, 3, 24)
}

///|
test "金标：boost 与 trim · 基线 1B lm=3" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF1_BITS)
  play_af1(dec)
}

///|
const ALLOC_FLAGS_AF2_BITS : Bytes = b"\x59\x3f"

///|
fn play_af2(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF2_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 2, 0)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    3,
    "af2",
  )
  expect_dec_state(dec, "af2", 120529110L, 85065852L, 6, 42)
}

///|
test "金标：boost 与 trim · 基线 2B lm=0" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF2_BITS)
  play_af2(dec)
}

///|
const ALLOC_FLAGS_AF3_BITS : Bytes = b"\x93\x93"

///|
fn play_af3(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF3_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 2, 3)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    "af3",
  )
  expect_dec_state(dec, "af3", 554433906L, 415372024L, 3, 24)
}

///|
test "金标：boost 与 trim · 基线 2B lm=3" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF3_BITS)
  play_af3(dec)
}

///|
const ALLOC_FLAGS_AF4_BITS : Bytes = b"\x87\xf0\xfb\xa9"

///|
fn play_af4(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF4_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 4, 0)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    "af4",
  )
  expect_dec_state(dec, "af4", 554433906L, 512955684L, 3, 24)
}

///|
test "金标：boost 与 trim · 基线 4B lm=0" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF4_BITS)
  play_af4(dec)
}

///|
const ALLOC_FLAGS_AF5_BITS : Bytes = b"\x66\x9a\xdb\xf8"

///|
fn play_af5(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF5_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 4, 3)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    4,
    "af5",
  )
  expect_dec_state(dec, "af5", 265164042L, 238167946L, 5, 33)
}

///|
test "金标：boost 与 trim · 基线 4B lm=3" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF5_BITS)
  play_af5(dec)
}

///|
const ALLOC_FLAGS_AF6_BITS : Bytes = b"\x17\x03\xc3\x4d\x10\x09\x8f\xe3\x03\xd8\xa0\x09\x4b\x44\xa1\x52"

///|
fn play_af6(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF6_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 16, 0)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    0,
    "af6",
  )
  expect_dec_state(dec, "af6", 24105941L, 1954422361L, 8, 60)
}

///|
test "金标：boost 与 trim · 基线 16B lm=0" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF6_BITS)
  play_af6(dec)
}

///|
const ALLOC_FLAGS_AF7_BITS : Bytes = b"\xba\x90\xaa\xd3\xcc\xd5\xb5\x3c\x83\x67\xa0\x87\x48\x6b\x96\x60"

///|
fn play_af7(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF7_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 16, 3)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    "af7",
  )
  expect_dec_state(dec, "af7", 554433906L, 88292751L, 3, 24)
}

///|
test "金标：boost 与 trim · 基线 16B lm=3" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF7_BITS)
  play_af7(dec)
}

///|
const ALLOC_FLAGS_AF8_BITS : Bytes = b"\x73\xf8\xb0\x8e\x5e\x81\x70\x2f\xd9\x77\xe1\xc3\xd9\x9f\xea\x8b\x11\x5d\xee\xc2\x47\x7f\x9d\x6d\xe1\xfe\xf1\x5b\x9c\x9c\x63\xae\xf7\x7f\xd3\x5d\x77\xda\x06\x9d\xae\x1c\xfa\x6b\x32\x27\x87\xc4\x58\x6a\xb8\xb0\xd6\xcd\x2b\x95\x32\xc6\xd8\xee\x52\x35\x69\xfe"

///|
fn play_af8(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF8_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 64, 0)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    4,
    "af8",
  )
  expect_dec_state(dec, "af8", 265164042L, 126041407L, 5, 33)
}

///|
test "金标：boost 与 trim · 基线 64B lm=0" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF8_BITS)
  play_af8(dec)
}

///|
const ALLOC_FLAGS_AF9_BITS : Bytes = b"\x66\x9b\x53\x4b\xd5\x83\x6e\x3d\xd8\x0f\x9c\xb0\x06\xb9\xff\x6d\x85\x23\xc7\xad\xde\x5c\xa0\x56\xfa\x9a\x5a\xd5\x4c\x47\x16\x49\x64\xcc\xeb\x4b\x88\x8b\x56\x30\x08\x94\x76\xd5\xbb\x56\xc3\x61\x9b\x30\xe3\x11\xb4\x17\x7d\x44\xe2\x44\xff\xc7\x5f\x62\x7b\xa0"

///|
fn play_af9(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF9_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 64, 3)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    4,
    "af9",
  )
  expect_dec_state(dec, "af9", 265164042L, 238152673L, 5, 33)
}

///|
test "金标：boost 与 trim · 基线 64B lm=3" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF9_BITS)
  play_af9(dec)
}

///|
const ALLOC_FLAGS_AF10_BITS : Bytes = b"\xaa\x68\x60\x2c\x62\x43\xd6\x6e\x54\x6e\xe9\x98\xc5\xb1\xae\x91\xa6\x7c\xc7\x77\xd0\x3c\x23\xba\x5b\xd5\xb8\x53\xfd\x52\xbf\x9d\x14\x26\xc6\x48\x22\x30\xee\xe9\x08\xb1\x0d\xb8\xdb\xd1\x33\xcd\xf6\xdf\x14\x9e\x16\xc3\x5b\x63\x01\xd1\xc4\x25\x8d\x45\x7a\x20\x0b\x6e\x9b\x64\x83\xe5\xf7\x3b\xdc\x06\x04\xad\x4e\x56\xfb\x74\x08\x6e\x29\x12\x87\xa5\x1c\x1c\xfb\x4d\xd8\x26\xac\x93\x26\xb2\x99\x6c\xa1\x82\x25\xd5\x0b\xdd\x3b\x74\x5f\x13\xa0\x98\x9d\x8d\x67\xd7\x9f\x1f\x7f\x4d\x58\x53\x42\x0e\x53\xdf\x9f\xe3\x22\x79\x4f\x70\x3b\xa8\x88\xb1\x64\x31\xc9\x7b\x9c\xa6\x53\xee\x34\xf4\x90\xb0\x24\x7e\x96\x24\xc1\xe1\x85\x12\x6a\xf0\x12\xf2\xb6\x71\x08\x78\x69\xdd\xb5\x3c\xd4\x03\xc4\xdb\xfd\xe3\xd3\x69\xc7\x50\x28\x33\xe4\x2c\x1f\x98\x79\x26\xdc\x5e\x4c\xb8\xb6\x3e\xa7\x52\xf4\xd7\xe0\xeb\x94\x80\x51\x17\x9b\x4f\x61\xc5\x16\x7c\xae\x66\xf2\xf3\x0d\xa2\x03\xc7\xa3\x4e\x17\x07\x25\x06\x9c\x3f\xaf\x23\x35\x57\x68\x23\x39\x0d\x64\x53\xfc\x1f\xbb\xc7\x54\xed\x5d\x03\x10\x83\x98\x19\x57\xe4\x34\x7c\xc1\x99\xc3\x3f\xb4\xbf\x88\x2b"

///|
fn play_af10(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF10_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 256, 0)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    "af10",
  )
  expect_dec_state(dec, "af10", 554433906L, 223830754L, 3, 24)
}

///|
test "金标：boost 与 trim · 基线 256B lm=0" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF10_BITS)
  play_af10(dec)
}

///|
const ALLOC_FLAGS_AF11_BITS : Bytes = b"\x8b\x70\xc7\xdc\xae\x45\x10\xcd\x78\x5f\x36\xfb\x1a\x95\x06\x54\xcc\x8a\x65\x7e\xb8\x77\xa7\x38\xe8\x4d\xb5\x3a\x12\xb6\x47\xa5\xf3\xef\x96\x26\x64\xc4\x64\x61\x75\xb8\xfd\xfc\xe2\x2f\xc1\x67\x75\x93\x78\x44\xa1\x52\xd0\x44\x93\xf8\xa3\x8c\xac\x87\xe2\xcf\x84\x92\x6a\x9b\x8f\x5a\x5f\x8b\xf2\x61\xdd\xc2\x94\xb6\xdf\x35\x2e\x32\x17\x5b\x34\x07\xd4\x3c\x1d\x47\x63\x33\xd6\xeb\xdb\x6f\xd9\xd9\xbc\x06\x97\x52\x29\xcc\x90\x1f\x7d\x8e\x85\xf5\xec\x25\x25\x7b\x83\x6f\x8b\xf4\x5d\x73\x8b\x11\xfb\xa0\x86\x3f\x0f\x6d\x53\x70\xac\x97\x07\x82\xc8\x1c\x28\x08\xa5\xe4\x64\x2a\xd2\x25\xd4\xaf\xc4\xba\x25\x50\x15\xf2\x0f\xcf\xd0\xb5\x23\xe0\xa4\x5d\x5b\xc9\xf9\x3c\xda\x0d\x78\xbd\x72\xf7\x82\x04\xd7\x59\x40\x20\x56\x39\x2c\xc5\x77\xc2\xab\x2a\x02\x47\x2b\x75\x5f\x64\x41\x14\x4c\x20\x14\x12\xe9\xdb\x6b\xa1\xe3\xda\xda\xf5\x38\xb4\x44\x81\x60\x68\xd5\xaf\x7c\xcc\xef\x2c\x5a\x9f\xfc\xb1\x68\x92\x61\x25\xb4\xda\x58\xb2\x3d\x41\x02\x5d\x29\x7e\xac\xc3\x3a\x48\xfa\x16\x10\x2c\x2d\xa0\xe6\xc7\x3f\x8b\x67\xb1\xbb\x5a\xdc\x70\x26\x88"

///|
fn play_af11(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF11_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 256, 3)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    "af11",
  )
  expect_dec_state(dec, "af11", 554433906L, 483602186L, 3, 24)
}

///|
test "金标：boost 与 trim · 基线 256B lm=3" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF11_BITS)
  play_af11(dec)
}

///|
const ALLOC_FLAGS_AF12_BITS : Bytes = b"\xb9\x98\xfe\x64\x3f\x43\x70\xe8\xb6\xdd\xad\xd3\x33\xf8\x0b\x90\x16\x22\xa8\x97\xf3\x86\x31\xd2\x0c\x35\x95\x89\x6b\x5d\x6f\xea\x93\x47\xad\x10\x9c\x0e\xe5\x58\xc3\xa9\xc3\x7e\x92\xef\x9f\x29\x29\xf2\x83\x6b\x09\x68\x8e\x9f\x3a\x86\x3e\x15\xab\x98\xe0\x31"

///|
fn play_af12(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF12_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    249, 249, 249, 249, 249, 249, 249, 249, 514, 514, 514, 514, 1028, 1028, 1028,
    1482, 1482, 1888, 2424, 2322, 2266,
  ]
  let got = celt_decode_alloc_flags(dec, 5, 17, cap, 64, 2)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    "af12",
  )
  expect_dec_state(dec, "af12", 638858396L, 21160603L, 3, 22)
}

///|
test "金标：boost 与 trim · 带窗 5..17" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF12_BITS)
  play_af12(dec)
}

///|
const ALLOC_FLAGS_AF13_BITS : Bytes = b"\x70\xa2\x33\x6e\x93\xb1\xe4\xd3\x04\xa4\x4f\xb8\x04\xd2\x5a\xa0\x62\x53\x1c\x16\xb8\xd0\x33\xd1\xe6\x82\xa3\x9f\x41\x43\x5d\x77\x62\x2f\x16\x8d\xe3\x4f\x8e\xae\x65\x2c\x46\xaa\x68\x59\x1e\xcb\x42\x43\x1f\xeb\x1a\xaa\xbb\x48\x52\x36\xbd\x67\x07\xba\x14\xd8\x58\xed\xf8\x3c\xc0\xc7\x0b\xcc\xbb\x7d\x82\x1e\xf3\x6c\x17\x78\x9e\x65\x00\x90\x21\x91\xd0\xb4\x2e\x21\xb4\x83\xdb\xae\x34\x4a\x96\x19\x74\x43\x83\x15\x09\xff\x8f\x38\xdc\x37\x9e\xb3\x21\xfe\xf3\xca\xed\xae\x49\x72\x66\xf2\x01\xad\xd4\xa7\x84\xfa\xd9\x75\xa7\x68\xcc\xe8\x7b\xc8\x4a\xe1\x8b\x93\x9b\x4d\x35\x6e\x26\xe6\x5c\x38\x9b\xbc\xf9\xd8\x9f\xd7\xd7\xd7\xe1\x70\xd4\xb0\x87\xc2\xa4\x37\x8a\x1a\x6d\xd4\xf3\xba\x1e\x26\x4f\x28\x89\x85\xe2\x5f\x7b\x31\x06\x63\xb8\xfb\x31\xdb\xff\xdc\x23\x62\x93\x8b\x1a\x64\x04\x75\x34\x34\x26\xa0\xcc\x6c\xa6\x46\xa6\xdc\x3d\x7e\x9f\xc0\xb8\x27\x2a\x81\xee\x97\xad\xeb\x8f\x66\xbf\xdb\xe6\x2a\x4c\x84\xf5\x52\xe3\xf5\x1f\x66\xfc\xe8\x7f\x29\x16\x5e\x1a\x46\xee\xef\x7d\x54\x9a\x8b\xa8\x4b\x5f\x48\x89\x80\x76\x10\xa5\x59\xcd\x65"

///|
fn play_af13(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AF13_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    112, 112, 112, 112, 112, 112, 112, 112, 249, 249, 249, 249, 514, 514, 514, 741,
    741, 944, 1212, 1152, 1122,
  ]
  let got = celt_decode_alloc_flags(dec, 5, 17, cap, 256, 1)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    "af13",
  )
  expect_dec_state(dec, "af13", 638858396L, 633227286L, 3, 22)
}

///|
test "金标：boost 与 trim · 带窗 5..17 大帧" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AF13_BITS)
  play_af13(dec)
}

///|
const ALLOC_FLAGS_AG7111_BITS : Bytes = b"\xfc\x96\x7e\x46\x63\x5d\x52\xc3\xe4\x3c\x7a\x51\x76\xec\x8b\xc8\xaa\x84\xa5\x33\x85\x69\x7b\x32\xc0\x9d\x6b\xb1\x81\x8a\x60\x68\x05\xee\xa7\x0d\x1f\x13\x9b\x57\xb4\x48\x2b\x68\x36\x24\x02\x4a\x72\x80\x97\x54\x03\xc6\x0c\xaa\x0d\xd7\xb7\x88\xeb\x5b\x13\xbd\x95\xaa\x4a\x09\xfd\x54\x5a\x8f\x00\xea\xd3\xc8\x82\x6d\x16\xaf\xc1\xe5\xbe\xdc\xd1\xce\x2c\xd4\x0a\xe7\xc8\x91\xf4\x48\xc3\x7a\xf2\x5f\x2c\x17\x1c\xb5\x44\xe8\x0d\x87\x1e\xc8\x80\xe6\x2b\x58\xb0\xc5\x01\x27\xa1\xa9\xe2\x60\x72\x8c\xf0\xe8\xaa\x6a\x0f\x55\xf9\xd5\xd9\xf1\xe6\xea\x0f\xe1\xde\x55\xd6\xc6\x1d\x46\xe6\xf2\x11\x03\x07\xf7\x4f\xae\xa2\x2c\x5c\x56\xb8\xff\x9b\xd0\xfd\x7c\x2e\xc9\x1d\x64\xbf\x90\x12\x97\xdd\xc1\xc1\xab\xc6\xd1\xba\xb3\x76\x3d\x5d\x75\x13\x7c\x41\x7b\xfe\x5e\x6b\xd1\xc1\x8b\xdf\x8d\x12\xa2\x13\xca\x78\x0e\x27\x3b\x18\x8e\xdb\x64\x76\x0f\x6e\x1e\xfb\xe1\x77\xeb\x6b\x24\x31\xdc\xa4\x7c\xdc\xaa\x5c\xce\x83\xe4\x2a\x67\x55\xbf\x4d\xcb\x1f\xf9\xb0\xc9\x37\xef\x78\x8b\x25\xd4\x40\x04\xa9\xd1\x1a\xfa\xc4\xf4\x21\x53\x12\x34\xf5\x39\xe8\x5a\x1c\x6c\xe1\x9c\xe2\xdf\x2e\xca\x8a\x5b\x66\xdb\x74\xdd\x7d\x0c\x07\x24\xf6\x32\x39\xfa\x22\xa4\xdf\x9b\xe8\x94\x3c\xb8\xe0\x0d\xac\xdb\xe2\xd5\x3e\xa7\x28\x9c\x52\x8d\x93\xfe\xad\x87\x79\xc9\x0f\xae\x60\xb6\xb6\x2b\xa7\x46\x30\x1e\x71\xff\x33\x1b\xd3\xb9\x9b\x02\xe4\xe0\xda\xa0\x16\x6a\xec\x54\x03\x1b\xf1\xf2\x0c\x64\xbd\x93\x13\x02\xa2\x84\xf5\x09\x31\xb4\xe9\x12\x24\xee\xef\xb5\xf5\x1a\xa1\xe8\xa7\xd5\xa6\x3b\x55\xac\x96\x78\x1d\x29\x2a\x88\x80\x1e\xaa\x29\x6e\x09\xaf\xa0\x0c\xac\x3d\x20\xa9\x86\x6c\x3c\x12\x71\xaa\xf5\x37\xbe\x96\x21\x9b\x23\x6e\x4a\x08\x20\x33\x8d\x44\xf8\x42\xf7\xba\x41\xb1\x6d\xb3\x54\xa2\x78\x30\x25\x85\xf5\xa0\xda\x70\x67\x35\xff\xaa\x19\x19\xde\x0a\xe3\xda\x7b\xbe\xd2\x83\x7f\x38\xea\x57\xc8\x4c\x85\x54\xe3\x80\xd7\xae\xcb\xbb\x85\xab\x2b\x88\x24\x92\x52\x5b\xf2\x69\x8f\xdd\x67\x2d\x12\xbf\xa5\xe8\x16\x77\x0a\x99\xde\xdb\x35\x57\x81\x4b\xe8\x2a\x60\x04\x10\x99\xe6\x46\xeb\x60\xc3\x2c\x7b\xbd\xe7\x62\xe4\x78\xc5\x7a\x67\xab\x3f\xe0\x84\xf8\x45\x50\x93\xc6\xc0\xde\x97\xaa\xab\x6c\x28"

///|
fn play_ag7111(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AG7111_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 512, 3)
  expect_alloc_flags(
    got,
    [48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    0,
    "ag7111",
  )
  expect_dec_state(dec, "ag7111", 35582208L, 885054670L, 15, 120)
}

///|
test "金标：boost 与 trim · 覆盖搜索 7111" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AG7111_BITS)
  play_ag7111(dec)
}

///|
const ALLOC_FLAGS_AG7122_BITS : Bytes = b"\xff\x77\x6f\x45"

///|
fn play_ag7122(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AG7122_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    249, 249, 249, 249, 249, 249, 249, 249, 514, 514, 514, 514, 1028, 1028, 1028,
    1482, 1482, 1888, 2424, 2322, 2266,
  ]
  let got = celt_decode_alloc_flags(dec, 5, 17, cap, 4, 2)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    0,
    "ag7122",
  )
  expect_dec_state(dec, "ag7122", 11831750L, 1145593215L, 17, 133)
}

///|
test "金标：boost 与 trim · 覆盖搜索 7122" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AG7122_BITS)
  play_ag7122(dec)
}

///|
const ALLOC_FLAGS_AG7145_BITS : Bytes = b"\xff\x97"

///|
fn play_ag7145(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AG7145_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    112, 112, 112, 112, 112, 112, 112, 112, 249, 249, 249, 249, 514, 514, 514, 741,
    741, 944, 1212, 1152, 1122,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 2, 1)
  expect_alloc_flags(
    got,
    [48, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    "ag7145",
  )
  expect_dec_state(dec, "ag7145", 2147483648L, 880803839L, 9, 72)
}

///|
test "金标：boost 与 trim · 覆盖搜索 7145" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AG7145_BITS)
  play_ag7145(dec)
}

///|
const ALLOC_FLAGS_AG30462_BITS : Bytes = b"\xff\xfb\xb7\x7f\x9e\x26\xcb\x36\x8f\x09\x3d\x22\xc4\x0f\x03\x60\x83\x1a\x32\xf9\xb6\x93\x66\xd8\x6f\x78\x41\x15\x0c\xd3\x5f\x88\x4c\xda\x57\x8a\xa0\x45\xc7\xf8\x0b\x2a\x90\xb8\x2a\xfa\xd7\x23\xe8\x76\x36\xe7\xea\x29\x5c\xe2\x3a\xf5\xf8\xc0\x5c\x97\x2c\xe9\x00\xd7\xe0\xc6\x7a\x9b\x26\xb7\x0f\xd0\x73\x3c\xca\x53\x5d\x01\xa8\xe5\xd7\x78\x5c\x10\x5e\x45\x1c\x1a\x67\x80\x2d\x7d\x1a\xea\xb4\x1e\x36\xef\xa0\xbb\x5c\xb1\xe7\x72\x08\x69\x5d\xa0\x70\x53\x84\xab\x58\x53\x47\x5c\xe5\x27\xe6\xe5\xbd\x99\xa2\x6f\x7d\x6e\x41\x34\x38\xc4\x54\xbb\x02\x10\x94\x10\x08\xd4\x23\xb6\x07\x9e\x77\x32\x10\x88\xa5\x81\x14\x41\x3f\x1f\x88\x43\x63\x7a\x80\x03\x44\x07\xbc\x37\xfc\x88\x3d\x69\x12\xab\x8a\x67\xb7\x4d\x64\x4c\xf8\x5d\x81\x17\xae\xb6\x50\xc2\x88\x51\x6e\x34\x88\x40\x63\xc7\xaf\xba\x58\x4f\x62\xe5\x67\x65\xab\x79\x88\x8d\x6f\x15\xea\x59\xbf\x29\x0b\x27\xa1\xa1\xbe\x2b\x64\xe9\x9f\xe6\xbb\x18\x4c\x4b\xb0\xf6\x94\x4c\x00\xb7\x9d\x50\x50\x94\xbf\x29\xaa\x58\x46\xe3\x78\xf0\x48\xeb\xd9\x06\x16\x74\xf7\x99\x90\x23\x16\x90\x54\x32"

///|
fn play_ag30462(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AG30462_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    249, 249, 249, 249, 249, 249, 249, 249, 514, 514, 514, 514, 1028, 1028, 1028,
    1482, 1482, 1888, 2424, 2322, 2266,
  ]
  let got = celt_decode_alloc_flags(dec, 5, 17, cap, 256, 2)
  expect_alloc_flags(
    got,
    [0, 0, 0, 0, 0, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    4,
    "ag30462",
  )
  expect_dec_state(dec, "ag30462", 2082386944L, 963227372L, 18, 137)
}

///|
test "金标：boost 与 trim · 覆盖搜索 30462" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AG30462_BITS)
  play_ag30462(dec)
}

///|
const ALLOC_FLAGS_AH18_BITS : Bytes = b"\xfe\xfe\xf8\xf9\x3f\x28\x72\xe5\xac\xa1\x69\x77\xf9\x41\xc3\x9d\x08\xd3\xde\xb0\x64\x50\xdf\xf6\x26\x5e\x18\x46\x71\x9b\x75\x9f\xc4\x7b\xd9\x80\xf7\x13\xaa\xd7\xae\x1d\x43\xae\xa3\xc0\xb5\x30\x66\x33\x6c\x63\xb4\xdb\x9d\xea\xed\xe8\x29\x95\x21\x5c\x73\x34"

///|
fn play_ah18(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_FLAGS_AH18_BITS；期望值由
  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_decode_alloc_flags(dec, 0, 21, cap, 64, 0)
  expect_alloc_flags(
    got,
    [16, 24, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0],
    0,
    "ah18",
  )
  expect_dec_state(dec, "ah18", 21995172L, 1617675917L, 40, 317)
}

///|
test "金标：boost 与 trim · 贪心连击 boost 64B lm=0" {
  let dec = RangeDecoder::new(ALLOC_FLAGS_AH18_BITS)
  play_ah18(dec)
}
