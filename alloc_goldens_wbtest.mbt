// 由 tools/gen_alloc_goldens.py 生成，请勿手改。
//
// 比特分配（RFC 6716 §4.3.3）金标：载荷与期望值由本脚本内的独立
// 参考端算出（不同语言、不同实现路径），MoonBit 的 celt_alloc.mbt
// 重放同一参数后逐项比对 PVQ 位数、细能量位、收尾优先级、
// codedBands 与 balance。
//
// total 多数由 celt_alloc_total(载荷字节数, dec) 算出，与参考实现
// 「len*8<<BITRES - ec_tell_frac - 1」一致；少数为命中极端分支
// 直接给定，并在用例注释中说明。

///|

///|
const ALLOC_B0_BITS : Bytes = b"\xdb\x32\xc9\xb4\x20\xef\x54\xdf"

///|
fn play_b0(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B0_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    0,
    celt_alloc_total(8, dec),
    0,
  )
  expect_alloc(
    got,
    [8, 8, 8, 8, 8, 8, 8, 8, 28, 25, 23, 21, 40, 35, 32, 42, 37, 43, 43, 38, 0],
    [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0],
    [0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1],
    20,
    0,
    "b0",
  )
  expect_dec_state(dec, "b0", 1073741824L, 308714277L, 2, 16)
}

///|
test "金标：比特分配 · 基线 8B lm=0 trim=0" {
  let dec = RangeDecoder::new(ALLOC_B0_BITS)
  play_b0(dec)
}

///|
const ALLOC_B1_BITS : Bytes = b"\x1e\x65\x2e\xc1\x52\xd0\xbf\xcd"

///|
fn play_b1(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B1_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(8, dec),
    0,
  )
  expect_alloc(
    got,
    [8, 8, 8, 8, 8, 8, 8, 8, 38, 29, 26, 31, 48, 46, 37, 0, 0, 0, 0, 0, 0],
    [2, 2, 1, 2, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0],
    [0, 1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
    15,
    0,
    "b1",
  )
  expect_dec_state(dec, "b1", 134217728L, 13461663L, 5, 40)
}

///|
test "金标：比特分配 · 基线 8B lm=0 trim=5" {
  let dec = RangeDecoder::new(ALLOC_B1_BITS)
  play_b1(dec)
}

///|
const ALLOC_B2_BITS : Bytes = b"\xd7\x71\x49\x42\x8e\xf7\x41\x2f"

///|
fn play_b2(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B2_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    7,
    celt_alloc_total(8, dec),
    0,
  )
  expect_alloc(
    got,
    [8, 8, 8, 8, 8, 8, 8, 8, 35, 28, 33, 29, 51, 42, 34, 37, 22, 16, 0, 0, 0],
    [2, 2, 2, 1, 2, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 1, 1],
    18,
    0,
    "b2",
  )
  expect_dec_state(dec, "b2", 1073741824L, 340220766L, 2, 16)
}

///|
test "金标：比特分配 · 基线 8B lm=0 trim=7" {
  let dec = RangeDecoder::new(ALLOC_B2_BITS)
  play_b2(dec)
}

///|
const ALLOC_B3_BITS : Bytes = b"\xfe\xb8\x71\xed\xe4\xe8\xce\x0d"

///|
fn play_b3(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B3_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    10,
    celt_alloc_total(8, dec),
    0,
  )
  expect_alloc(
    got,
    [8, 8, 8, 8, 8, 8, 8, 8, 34, 30, 26, 30, 45, 43, 33, 22, 0, 0, 0, 0, 0],
    [3, 2, 3, 2, 2, 1, 2, 0, 2, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0],
    [0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1],
    16,
    0,
    "b3",
  )
  expect_dec_state(dec, "b3", 1073741824L, 10733321L, 2, 16)
}

///|
test "金标：比特分配 · 基线 8B lm=0 trim=10" {
  let dec = RangeDecoder::new(ALLOC_B3_BITS)
  play_b3(dec)
}

///|
const ALLOC_B4_BITS : Bytes = b"\xd7\x36\x60\x6b\xae\x1f\x4d\xbd"

///|
fn play_b4(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B4_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    0,
    celt_alloc_total(8, dec),
    3,
  )
  expect_alloc(
    got,
    [267, 164, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    2,
    0,
    "b4",
  )
  expect_dec_state(dec, "b4", 1073741824L, 342151114L, 2, 16)
}

///|
test "金标：比特分配 · 基线 8B lm=3 trim=0" {
  let dec = RangeDecoder::new(ALLOC_B4_BITS)
  play_b4(dec)
}

///|
const ALLOC_B5_BITS : Bytes = b"\xf7\xcc\xd2\x99\xb7\x5b\xfa\x3e"

///|
fn play_b5(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B5_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(8, dec),
    3,
  )
  expect_alloc(
    got,
    [160, 135, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    3,
    0,
    "b5",
  )
  expect_dec_state(dec, "b5", 1073741824L, 68785843L, 2, 16)
}

///|
test "金标：比特分配 · 基线 8B lm=3 trim=5" {
  let dec = RangeDecoder::new(ALLOC_B5_BITS)
  play_b5(dec)
}

///|
const ALLOC_B6_BITS : Bytes = b"\xb1\x1c\x75\xe3\x06\x69\xa5\x00"

///|
fn play_b6(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B6_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    7,
    celt_alloc_total(8, dec),
    3,
  )
  expect_alloc(
    got,
    [152, 137, 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
    3,
    0,
    "b6",
  )
  expect_dec_state(dec, "b6", 1073741824L, 661767438L, 2, 16)
}

///|
test "金标：比特分配 · 基线 8B lm=3 trim=7" {
  let dec = RangeDecoder::new(ALLOC_B6_BITS)
  play_b6(dec)
}

///|
const ALLOC_B7_BITS : Bytes = b"\x10\x59\x9f\x5a\x73\x1d\x64\x1b"

///|
fn play_b7(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B7_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    10,
    celt_alloc_total(8, dec),
    3,
  )
  expect_alloc(
    got,
    [391, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1],
    1,
    0,
    "b7",
  )
  expect_dec_state(dec, "b7", 1073741824L, 936587346L, 2, 16)
}

///|
test "金标：比特分配 · 基线 8B lm=3 trim=10" {
  let dec = RangeDecoder::new(ALLOC_B7_BITS)
  play_b7(dec)
}

///|
const ALLOC_B8_BITS : Bytes = b"\xe3\xae\x29\x34\x19\x48\x39\xb0\x05\xa7\x84\x71\xf8\x4b\x14\x6f\x49\x34\x75\xc0\xb3\x37\x31\x4b\x72\xbe\x7f\x75\x34\xe0\xe6\x99\xae\x41\xe1\xb8\xea\xa5\xd2\xbb\xb0\xd4\xb7\x18\x7b\xff\x49\x99\x1e\x70\xff\x8e\xa3\xe7\xf8\xfb\xec\x71\x15\x39\x34\xf5\x87\x14"

///|
fn play_b8(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B8_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    0,
    celt_alloc_total(64, dec),
    0,
  )
  expect_alloc(
    got,
    [
      8, 8, 8, 8, 8, 8, 8, 8, 61, 61, 62, 62, 170, 170, 172, 272, 274, 367, 499,
      538, 531,
    ],
    [4, 5, 5, 5, 5, 5, 5, 6, 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 3, 3],
    [0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0],
    21,
    0,
    "b8",
  )
  expect_dec_state(dec, "b8", 1073741824L, 237562725L, 2, 16)
}

///|
test "金标：比特分配 · 基线 64B lm=0 trim=0" {
  let dec = RangeDecoder::new(ALLOC_B8_BITS)
  play_b8(dec)
}

///|
const ALLOC_B9_BITS : Bytes = b"\x5c\x06\xf9\x27\xf4\x55\x79\x6d\x8c\x2d\x10\x68\x64\x27\xfc\x52\x32\xac\xed\x07\x44\xb5\x46\x47\xea\x6e\xdb\x08\x57\xe8\xea\x99\x9b\x89\x6e\xd3\xbe\xad\xad\x11\xe3\x88\xa1\x61\x47\x42\xae\xa0\x21\x05\x7d\xe6\xd9\x98\x64\x60\x8c\x34\xbc\x8b\x48\xcb\x0c\xd7"

///|
fn play_b9(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B9_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(64, dec),
    0,
  )
  expect_alloc(
    got,
    [
      8, 8, 8, 8, 8, 8, 8, 8, 72, 72, 72, 72, 198, 189, 187, 295, 292, 390, 554,
      538, 0,
    ],
    [6, 7, 6, 6, 7, 6, 7, 6, 6, 5, 6, 5, 6, 6, 6, 6, 6, 6, 5, 8, 1],
    [0, 1, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0],
    20,
    92,
    "b9",
  )
  expect_dec_state(dec, "b9", 536870912L, 301761388L, 3, 24)
}

///|
test "金标：比特分配 · 基线 64B lm=0 trim=5" {
  let dec = RangeDecoder::new(ALLOC_B9_BITS)
  play_b9(dec)
}

///|
const ALLOC_B10_BITS : Bytes = b"\x7e\x2a\xd2\xde\xd3\x54\x48\xdf\x68\x36\xb6\x89\x4a\xc8\xf4\xbc\x27\x07\x92\x4b\x49\x58\x0d\x61\xdd\x36\x08\x0e\x20\x1a\x1a\x90\x64\x74\x20\x74\x92\x98\x79\x68\xae\x47\xa4\x2d\xf6\xf3\xc2\x14\xbe\x5b\x26\x70\xe2\x8d\x0c\x37\x17\xc4\x3a\xab\x6a\x7f\x19\x33"

///|
fn play_b10(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B10_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    7,
    celt_alloc_total(64, dec),
    0,
  )
  expect_alloc(
    got,
    [
      8, 8, 8, 8, 8, 8, 8, 8, 72, 72, 72, 72, 195, 189, 185, 291, 286, 381, 552,
      538, 0,
    ],
    [6, 7, 7, 6, 7, 7, 6, 7, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 5, 8, 1],
    [0, 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    20,
    86,
    "b10",
  )
  expect_dec_state(dec, "b10", 536870912L, 15373968L, 3, 24)
}

///|
test "金标：比特分配 · 基线 64B lm=0 trim=7" {
  let dec = RangeDecoder::new(ALLOC_B10_BITS)
  play_b10(dec)
}

///|
const ALLOC_B11_BITS : Bytes = b"\xbb\x81\x0f\xd4\x5a\xe2\xcc\xe2\x84\x5b\x3c\xee\x97\xc2\x39\xb3\x6c\x29\xdc\xb3\xf4\x09\xf3\x50\x03\x88\x54\x31\x86\xe4\x77\x82\xf2\x42\xfe\x2e\x4c\xd2\x66\x82\x9f\x5f\x32\xf0\xdb\x1c\x5a\x54\xbb\x44\x40\x4a\xba\x4d\x16\x61\x8d\x84\x61\x87\x13\x84\xe6\x22"

///|
fn play_b11(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B11_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    10,
    celt_alloc_total(64, dec),
    0,
  )
  expect_alloc(
    got,
    [
      8, 8, 8, 8, 8, 8, 8, 8, 72, 72, 70, 67, 175, 169, 163, 251, 243, 320, 464,
      538, 531,
    ],
    [6, 6, 7, 6, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 3, 3],
    [0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0],
    21,
    0,
    "b11",
  )
  expect_dec_state(dec, "b11", 1073741824L, 574584853L, 2, 16)
}

///|
test "金标：比特分配 · 基线 64B lm=0 trim=10" {
  let dec = RangeDecoder::new(ALLOC_B11_BITS)
  play_b11(dec)
}

///|
const ALLOC_B12_BITS : Bytes = b"\xad\x51\x4a\xce\x6a\x0f\xb0\x83\xdd\x65\x4e\xe1\xd4\x03\xcc\xe8\x35\xf4\x72\xc7\xf7\xb8\x55\x6a\xc7\x40\xf6\x92\x73\x37\x5a\x00\x8a\x25\x19\x73\x59\xbb\x66\x70\x1f\x5f\x79\xab\xcf\x30\xb6\x4e\xb9\x1a\x5d\x0e\x63\x7f\x4a\x74\x18\x3d\x11\x85\x89\xad\x04\xcd"

///|
fn play_b12(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B12_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    0,
    celt_alloc_total(64, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 489, 425, 350, 308, 270, 249, 222, 382, 318, 265, 223, 0, 0, 0, 0, 0,
      0, 0, 0, 0,
    ],
    [2, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1],
    12,
    0,
    "b12",
  )
  expect_dec_state(dec, "b12", 1073741824L, 693590680L, 2, 16)
}

///|
test "金标：比特分配 · 基线 64B lm=3 trim=0" {
  let dec = RangeDecoder::new(ALLOC_B12_BITS)
  play_b12(dec)
}

///|
const ALLOC_B13_BITS : Bytes = b"\xfb\x82\x5e\x0d\xc4\x1c\xc4\x7d\x84\x00\xa9\x26\xe4\xa9\x23\x6b\x81\x97\x52\xc8\xb5\xa6\x67\x3e\x4b\xc8\x35\xd3\x3d\xc1\xf6\x5c\x24\x96\xa3\x93\x66\x0c\x90\xb8\xfd\xe4\x21\xa5\x83\x8d\xd2\xff\xf2\xde\x24\x94\x9a\x54\xa5\x84\x40\xb9\x0f\x78\xd8\x41\xdd\x24"

///|
fn play_b13(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B13_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(64, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 489, 438, 376, 315, 230, 352, 273, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0,
    ],
    [2, 2, 2, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    10,
    0,
    "b13",
  )
  expect_dec_state(dec, "b13", 1073741824L, 37671161L, 2, 16)
}

///|
test "金标：比特分配 · 基线 64B lm=3 trim=5" {
  let dec = RangeDecoder::new(ALLOC_B13_BITS)
  play_b13(dec)
}

///|
const ALLOC_B14_BITS : Bytes = b"\x02\x7a\x82\x11\xd8\xdb\x58\xee\xfa\x80\xd5\xf0\x34\x02\x6e\x4b\x7f\x48\xbd\xa9\x7d\x5f\x7d\x1c\x8e\xec\xfa\xb6\xd8\x2c\x11\xaa\x5a\x74\xea\x38\x69\x70\x20\x23\xf4\xc8\x3e\xfa\x6d\x19\xe3\x6e\x0b\x93\x25\xca\x4c\xb7\x1e\x43\x30\xe2\x10\x88\x04\xae\x08\x58"

///|
fn play_b14(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B14_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    7,
    celt_alloc_total(64, dec),
    3,
  )
  expect_alloc(
    got,
    [506, 506, 506, 506, 506, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [8, 8, 8, 8, 8, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
    5,
    1117,
    "b14",
  )
  expect_dec_state(dec, "b14", 16777216L, 12762871L, 8, 64)
}

///|
test "金标：比特分配 · 基线 64B lm=3 trim=7" {
  let dec = RangeDecoder::new(ALLOC_B14_BITS)
  play_b14(dec)
}

///|
const ALLOC_B15_BITS : Bytes = b"\x35\x9a\xf9\xcd\x8f\xdf\x9c\xf4\x04\x38\xd3\xfd\xd2\xa9\x76\x76\x9b\x17\x75\xc2\x3b\x22\x82\xd9\x90\xe2\x83\xae\x68\xd5\x42\x36\x00\x5c\x02\xc8\xcd\x04\x28\x71\x72\x7e\x10\xf0\x43\x20\xf0\x68\xc3\xf2\xc5\xaf\x41\xd8\x10\xde\x75\x1b\x0e\xa8\x49\xdb\xda\x14"

///|
fn play_b15(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B15_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    10,
    celt_alloc_total(64, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 461, 443, 413, 383, 349, 312, 265, 463, 412, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0,
    ],
    [1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
    10,
    0,
    "b15",
  )
  expect_dec_state(dec, "b15", 268435456L, 87196441L, 4, 32)
}

///|
test "金标：比特分配 · 基线 64B lm=3 trim=10" {
  let dec = RangeDecoder::new(ALLOC_B15_BITS)
  play_b15(dec)
}

///|
const ALLOC_B16_BITS : Bytes = b"\xba\xc7\xb2\x57\x20\xb2\xfc\x11\xef\xf4\xca\x57\xff\x5c\x34\x89\xa6\xad\xb9\xbb\xaa\xb3\x95\x7b\xb0\x8f\x0f\xe9\x5d\x68\x77\x85\xaf\xb0\xbe\x46\x9d\xab\xb4\xc0\x2e\x61\xe0\x7c\x5d\x65\x9e\x98\x2e\x25\x98\xc7\xba\xe2\xdf\x71\x53\x57\xf0\x56\xca\x0e\xcb\x70\x70\xf5\x06\x2b\xef\xcb\xf2\xaa\x17\xd5\x9b\xfb\xdf\x5a\x14\x7e\xf3\x6c\xa1\x75\x8b\x17\xfa\xee\x5a\x44\xfc\x7a\x1c\x29\x33\xd9\xdf\x5f\x1f\x66\xf7\xb6\x94\xff\x41\x9d\xea\x8c\xa5\xb1\x65\x50\x2d\x7c\x1c\xce\x30\xc3\xcb\x6a\x38\xad\x27\x45\x23\xb1\xf2\x52\xe5\x00\x74\x1b\x25\xb9\x17\xfb\xb9\xe1\xca\xb0\x7a\x06\x00\x04\x8b\x4f\x08\xc3\x6d\x18\x60\x74\x09\xe7\xe1\x8f\x18\x32\x10\x95\xf4\xfb\xc7\xce\x07\x24\xf5\x11\x32\xbb\xf5\x62\xf2\x22\x67\x0b\x9c\x4e\x0d\xe3\xe8\x65\x4c\x96\xc6\x76\x32\x5f\x2e\x6a\xfa\x13"

///|
fn play_b16(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B16_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    0,
    celt_alloc_total(192, dec),
    0,
  )
  expect_alloc(
    got,
    [
      8, 8, 8, 8, 8, 8, 8, 8, 72, 72, 72, 72, 201, 201, 201, 315, 315, 416, 554,
      538, 531,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    21,
    7303,
    "b16",
  )
  expect_dec_state(dec, "b16", 1073741824L, 580658900L, 2, 16)
}

///|
test "金标：比特分配 · 基线 192B lm=0 trim=0" {
  let dec = RangeDecoder::new(ALLOC_B16_BITS)
  play_b16(dec)
}

///|
const ALLOC_B17_BITS : Bytes = b"\xf6\xda\x61\x30\xb4\x9f\x34\x95\x8b\x04\x91\xf4\xdd\xf5\xae\x85\xee\x26\xf9\x25\xef\x81\xe6\x44\x3c\x4f\xe1\x67\x8f\x49\x4b\x4a\xcc\xc4\xc9\x94\x36\x21\xf9\x9e\x0d\x16\x66\x3c\xc8\xa5\x88\xcf\xcb\x18\x34\x3b\x40\xf2\x91\xfd\x50\xf3\x10\x15\x4f\xb3\xa2\x93\x70\xaa\x05\xd6\x9d\xb1\x3c\x4e\x6f\x10\xe0\x4c\xde\xb9\xa4\xbf\x98\x41\xea\x6f\xf2\x1f\x30\xfe\x1a\x21\xcb\x26\x80\x45\xbf\x54\xe9\x33\x36\x1f\x4b\x74\x86\x70\x1b\xe8\x5f\x5c\xba\x16\xc6\x30\xa8\xc4\x3e\x3d\x13\x95\x6f\x68\x29\x2d\x4c\xc3\xe2\xc0\xcc\xfe\x12\xe9\x3d\x6c\xcb\xfb\x10\xf4\x3c\x91\x5b\x3e\x28\x97\xad\xb6\x81\xc0\x68\x0e\xa2\xc0\x62\xed\x90\xae\x19\xdd\x29\xff\x34\xde\x28\x2d\x94\xf9\xc7\xe0\x4a\x0c\x7b\x07\x4b\xa4\x28\xaf\x58\x12\x42\x6f\x3b\x7e\x4b\x6c\x7c\x3e\xbc\x26\xcc\xd1\x69\x30\x2c\x37"

///|
fn play_b17(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B17_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(192, dec),
    0,
  )
  expect_alloc(
    got,
    [
      8, 8, 8, 8, 8, 8, 8, 8, 72, 72, 72, 72, 201, 201, 201, 315, 315, 416, 554,
      538, 531,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    21,
    7303,
    "b17",
  )
  expect_dec_state(dec, "b17", 1073741824L, 76730215L, 2, 16)
}

///|
test "金标：比特分配 · 基线 192B lm=0 trim=5" {
  let dec = RangeDecoder::new(ALLOC_B17_BITS)
  play_b17(dec)
}

///|
const ALLOC_B18_BITS : Bytes = b"\xc9\xca\x33\x70\xa2\x70\x5f\xd2\x6e\x39\xc6\x5a\x4a\xc5\x1a\xdb\x4f\xc6\xba\x36\x66\x1a\xa2\xa7\xf8\xf9\x83\x07\xb9\x4c\x14\xae\x3e\x4c\x5c\xdb\x60\x03\x22\x69\x54\xcd\x52\x0d\x42\x99\x7b\x55\xf9\x67\x12\x6b\xf6\x94\xf5\x47\x09\xe6\x3a\x1d\xf8\x6c\x26\xa6\x8f\xd3\xba\x76\x65\xb1\x32\x41\x22\x81\x79\x94\xfc\x23\x31\x26\x93\x02\xc2\x83\x10\xe3\x8c\x6e\x7d\x80\xdc\xc2\x86\x3c\x84\x6b\xf1\xbe\xdd\xd1\x2b\x0e\xf3\x0c\x4d\xe7\x2e\x7c\x02\xc2\x31\xb1\x00\x40\x90\x5c\x6f\x54\x4c\x86\x3b\xcf\xb2\x6d\x85\xb6\xee\xb4\x3d\x2d\x7d\x42\x69\xb2\x20\x46\xdd\xc1\x08\xf1\xd4\xe2\x33\xcc\x2f\x18\x4b\x23\x6c\xfd\x84\x1e\x19\xf6\xa8\xdd\x57\x88\x86\xa4\x41\x4a\xff\xad\x1e\x1d\xf5\x94\x64\x41\x1e\x21\x68\xec\x71\x8a\x57\x44\x09\x3b\xa8\x7a\xdd\x97\x73\x0a\xbe\xec\xeb\xd9\x9d\x8d"

///|
fn play_b18(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B18_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    7,
    celt_alloc_total(192, dec),
    0,
  )
  expect_alloc(
    got,
    [
      8, 8, 8, 8, 8, 8, 8, 8, 72, 72, 72, 72, 201, 201, 201, 315, 315, 416, 554,
      538, 531,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    21,
    7303,
    "b18",
  )
  expect_dec_state(dec, "b18", 1073741824L, 454747719L, 2, 16)
}

///|
test "金标：比特分配 · 基线 192B lm=0 trim=7" {
  let dec = RangeDecoder::new(ALLOC_B18_BITS)
  play_b18(dec)
}

///|
const ALLOC_B19_BITS : Bytes = b"\x11\xaa\x6d\x33\x7b\xe4\x74\x96\xc0\xc6\x92\x84\x73\x85\x35\xb3\xd1\x18\x5e\xe3\x93\xf1\xf2\x16\x3d\xfd\x50\x61\xcc\xd1\xfe\x56\xdf\x1b\x34\x95\x34\xe5\xc3\x36\x97\x5a\xd6\x6a\x93\xee\x6b\xe1\x65\x63\x73\x3f\xb0\x0a\x4c\x3c\xf4\x1b\x2a\xde\x11\x15\xc7\xd4\x85\xb2\x96\xe2\x43\xf4\x0c\xe4\xdb\xef\x7c\x80\xa8\xfb\x0b\x03\x84\x74\xf3\xd0\xaf\x8f\x63\xc6\x19\xfc\x74\x3b\x2d\x8d\x5f\x92\x1d\xbf\x4f\x4f\xb7\x9b\xd2\x95\x7b\xa7\x2e\x06\xe4\x9a\x21\xd7\x4f\x95\xbf\x8d\x6f\xff\xc3\xa7\x56\xee\x30\x45\xe0\xdc\x01\x86\x78\xd2\x8d\x54\x8e\xab\xbb\xe9\x16\x97\x41\xaf\x45\x88\xd0\x52\x0f\xb8\xc6\x83\x4c\xcc\x3d\x05\x52\x2c\x0f\x4a\x0a\xed\x06\x71\x4c\xff\x57\x01\xca\x18\x8e\x2b\xcc\x46\xd7\x74\x35\xeb\xf3\x66\x77\x5d\x03\xda\x40\x40\x58\x2f\x9b\xba\x68\xc6\x17\x2d\xb5\x21"

///|
fn play_b19(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B19_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    10,
    celt_alloc_total(192, dec),
    0,
  )
  expect_alloc(
    got,
    [
      8, 8, 8, 8, 8, 8, 8, 8, 72, 72, 72, 72, 201, 201, 201, 315, 315, 416, 0, 0,
      0,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    18,
    9070,
    "b19",
  )
  expect_dec_state(dec, "b19", 134217728L, 120244582L, 5, 40)
}

///|
test "金标：比特分配 · 基线 192B lm=0 trim=10" {
  let dec = RangeDecoder::new(ALLOC_B19_BITS)
  play_b19(dec)
}

///|
const ALLOC_B20_BITS : Bytes = b"\x39\x0c\xec\xcf\x5b\x97\x5b\x89\xba\xd4\x8d\x9d\xd1\x18\xe5\x41\x17\xfd\x5e\xd7\x3f\x2f\x4e\xc7\xce\x2e\xf8\x00\xc7\xcb\x73\x59\x93\x38\x40\x5e\xab\x76\x83\xbe\x19\xa2\x63\x2d\xaf\x46\xc9\x5b\x2d\x66\x88\xd3\x02\x50\x97\x99\x39\xb5\xa8\x67\x38\x39\x53\xa8\x87\x8d\x57\xb3\x5b\x44\xeb\x0b\xfe\x81\x45\x68\xba\xe1\x0a\x4b\xf8\x2d\xcf\x2e\xdf\x72\x5d\x57\x1c\x80\x38\xd0\x89\xf9\xb2\x17\x6e\x07\x87\xdd\x68\xd6\xf9\x82\x07\x1a\xd3\x7d\xd7\x92\xfd\x1c\xd9\xce\x30\x0e\xc3\x10\xb4\x11\xa8\xe4\x26\x71\x9a\x4d\xf8\x3a\x78\x44\xb6\x8b\x66\x34\xc6\x1b\x08\xac\xfa\x3e\x05\x60\xc3\xc6\x4b\xae\x38\x73\xb4\x7e\x1f\xc0\x85\x0b\xde\xee\x0f\xc0\xa7\xdc\x91\xb1\x3c\xb7\x18\xdd\xe5\x72\xd5\xab\x5d\xd5\x8c\x60\x5d\xc8\x73\x9b\x11\x77\x60\x32\x63\xb4\xb7\xf2\x1a\x59\xe2\x5d\xf3\x36"

///|
fn play_b20(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B20_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    0,
    celt_alloc_total(192, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 991, 878, 814, 1470, 1248, 1090,
      0, 0, 0, 0, 0, 0,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 1, 1, 1, 2, 2, 2, 1, 1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0],
    15,
    0,
    "b20",
  )
  expect_dec_state(dec, "b20", 268435456L, 58296728L, 4, 32)
}

///|
test "金标：比特分配 · 基线 192B lm=3 trim=0" {
  let dec = RangeDecoder::new(ALLOC_B20_BITS)
  play_b20(dec)
}

///|
const ALLOC_B21_BITS : Bytes = b"\x5b\x7d\x81\xd1\xdc\xd1\xab\x37\x35\xe9\x83\x5c\xd8\x0a\xa4\x02\x75\xf1\xb1\xfb\x31\x79\xb5\xbe\xc7\xe9\xe4\xc9\x0f\x09\x4f\xe0\x37\x18\x93\x8c\xa7\x6e\x52\xff\xfe\x09\xec\xdd\x2e\xcb\xa7\x28\x2f\x22\xa0\xcc\x67\x26\xd3\x8f\x0b\x64\x3d\xae\xce\x3a\xc6\x52\xb2\x42\x32\x0d\xfa\x68\xa2\xbc\x71\x4d\x35\x1d\x32\xec\x33\xd0\xfd\x2b\x7c\xb5\xc2\x11\x55\x2d\x08\x60\x18\x4a\xb4\x07\x6f\x90\xba\x5d\x18\x86\x15\x73\x75\x3e\x35\x72\xd6\xd1\xbc\xf6\x11\xd1\x99\xb5\xfe\xcb\xab\x89\xee\xf9\x04\xe1\x5a\xfc\x8f\x9c\xf0\x73\x3f\xe8\x43\x0b\x8a\xc8\x1f\x72\xcf\x18\x3f\x27\x1b\xde\x7b\xab\xee\x14\x61\xb8\xaf\x15\x42\x56\x4d\x12\x7a\x3e\xb0\x03\x00\xb5\x84\x37\x1c\x19\x4b\x80\xc0\x0e\x4a\xeb\x7c\x15\x05\xb2\x0a\xec\xac\x19\x6b\xa7\x86\xfc\xd7\xcb\x30\x01\xc3\x67\x9e\xe9\x44\x8e"

///|
fn play_b21(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B21_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(192, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 1020, 1020, 1020, 1942, 1345,
      0, 0, 0, 0, 0, 0, 0,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 2, 2, 1, 1, 1, 1, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1],
    14,
    0,
    "b21",
  )
  expect_dec_state(dec, "b21", 536870912L, 306265879L, 3, 24)
}

///|
test "金标：比特分配 · 基线 192B lm=3 trim=5" {
  let dec = RangeDecoder::new(ALLOC_B21_BITS)
  play_b21(dec)
}

///|
const ALLOC_B22_BITS : Bytes = b"\x43\xd3\xb8\x2c\xc8\x22\xb4\x79\xdd\x1c\x8c\xf7\x8e\xc0\xa3\x3f\x4d\xca\xe8\x1e\x4e\x55\x10\xa1\xa0\x41\xf0\xf1\xb3\xf6\xe7\x39\x2b\x32\x7c\x44\x68\xde\x3a\x2c\xb3\xde\xa9\xbf\xaa\x6c\x58\x95\x4a\x2b\xac\x6c\x31\x6c\x4e\xfb\x1e\x2e\xf1\x08\x12\x05\xe9\x87\x92\x6a\x06\xd0\x44\xf3\x04\x72\x8b\x97\x8b\x88\x62\xff\x5c\xa7\x11\xc9\x0b\xc0\x44\xeb\xf6\x16\x73\x30\x55\x95\x37\xc3\x93\x5c\xf4\x3d\xb7\xfc\x8b\x36\x7e\x0e\x11\x9b\xd7\x52\x76\x45\xe5\x06\x10\x5b\x83\x1a\xa5\x59\xa0\x3d\x6d\x91\x2c\x45\x5e\x02\x6c\x51\x01\x35\x17\x7f\x66\xdb\x05\xff\xaf\x84\x18\x07\xfd\xeb\x50\xd2\xac\x32\xe4\x3d\x04\xcb\x42\x6c\xd7\xf8\xcb\x5b\xb0\x85\x60\x2a\xe1\xa8\x8a\x37\x78\x94\x34\x8a\xcd\x13\x17\x3d\x33\x4d\xff\x88\xd3\x8a\x74\xca\x35\xd2\xfe\x2c\x26\xb6\x01\x35\x6b\xae\x1e\xb0"

///|
fn play_b22(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B22_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    7,
    celt_alloc_total(192, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 1020, 1020, 1020, 1974, 1465,
      0, 0, 0, 0, 0, 0, 0,
    ],
    [6, 6, 6, 6, 6, 6, 6, 6, 8, 8, 8, 8, 2, 2, 1, 1, 1, 0, 0, 0, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1],
    14,
    0,
    "b22",
  )
  expect_dec_state(dec, "b22", 536870912L, 504767465L, 3, 24)
}

///|
test "金标：比特分配 · 基线 192B lm=3 trim=7" {
  let dec = RangeDecoder::new(ALLOC_B22_BITS)
  play_b22(dec)
}

///|
const ALLOC_B23_BITS : Bytes = b"\xfa\xe7\xf4\x40\xd8\x9f\x01\xd6\xb0\xb8\xbc\xc9\xd4\x8d\x21\x88\xed\x35\x56\x63\x68\x34\xaf\x86\xa2\xec\xc3\xab\xf0\x6a\xe2\x3b\xee\x98\xfb\xb0\xeb\xd2\x61\xaa\x74\x1e\x70\x09\xc1\xf1\x71\x4c\xca\x49\xd8\xbd\xa7\x88\xe1\x57\x43\x3a\xdd\xa9\xb7\xbb\x64\x1f\x73\x9e\xe8\xe0\x97\xb2\xb0\xc6\xd8\x14\xd2\x48\x17\x94\x25\x39\xb9\x2a\x12\x0b\xd4\x17\x69\x75\xce\x43\x51\xbf\x03\x7a\x13\x52\xe4\xea\x09\x3c\x81\x18\x89\x92\xae\x0c\xa8\xfb\x34\xe0\xea\xa7\xe1\x50\xe8\xd3\xe8\x4e\xb9\xf1\x80\x8a\x52\xe3\x62\xfb\xcd\xad\xa0\x22\x29\x3a\xe8\x74\xdf\x5d\xd9\xda\xe4\x85\x9a\xb1\x4e\x50\x88\x3e\x34\xc5\xfc\xb9\x5e\x89\x3e\x7d\x64\xa0\xda\xa8\x4b\x2a\xfb\x15\x59\xdd\x69\x3c\x82\xc5\x31\xbb\x88\x96\x69\xd4\x17\xaa\xf4\xe5\x98\xcd\x5f\x5b\x61\xb4\x40\x31\x60\xc7\x89\x1e\x43\xc2"

///|
fn play_b23(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B23_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    10,
    celt_alloc_total(192, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 1020, 1020, 1020, 1892, 1253,
      830, 0, 0, 0, 0, 0, 0,
    ],
    [2, 2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1],
    15,
    0,
    "b23",
  )
  expect_dec_state(dec, "b23", 1073741824L, 42730975L, 2, 16)
}

///|
test "金标：比特分配 · 基线 192B lm=3 trim=10" {
  let dec = RangeDecoder::new(ALLOC_B23_BITS)
  play_b23(dec)
}

///|
const ALLOC_D24_BITS : Bytes = b"\xf0\x5d\x9b\x66\xd1\x87\x7d\xff\xb5\xd4\x6f\x9e\xa9\x26\x69\xef\x4b\x6c\xd2\x1d\xb2\xd5\xee\x3f\x47\xa7\xc7\xa9\xb0\x66\xa6\xda\xd4\xa2\x6d\xd0\x75\x68\x14\x73\x09\x84\xa3\xd7\x39\xa9\x76\x78\xed\xbb\x45\x67\xbc\xfc\x48\x86\xc6\xac\xab\xee\x56\x43\xa9\x69"

///|
fn play_d24(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D24_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    64, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(64, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 489, 438, 376, 315, 230, 352, 273, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0,
    ],
    [2, 2, 2, 1, 0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    10,
    0,
    "d24",
  )
  expect_dec_state(dec, "d24", 1073741824L, 131150412L, 2, 16)
}

///|
test "金标：比特分配 · dynalloc/head 64B" {
  let dec = RangeDecoder::new(ALLOC_D24_BITS)
  play_d24(dec)
}

///|
const ALLOC_D25_BITS : Bytes = b"\x2a\xf4\x58\x00\xbe\xc0\x76\x21\xc3\xcd\x32\x16\x3c\x6c\xc0\x32\xd2\x19\x0e\x22\x63\x60\x0d\x74\xcb\xeb\xb5\x0f\x38\x65\x6a\x3e\x7c\x10\x3b\x45\xbc\x2c\xeb\x8e\xe2\x5a\xa5\xe4\xe9\xcc\x25\xdc\x0e\xa9\x7d\xb0\x74\x9f\x52\x8f\xa9\x96\xb8\x26\x4b\x8d\x8c\x4b\x00\xb3\x4e\xc4\xaf\x7e\x9d\x0c\xd0\x10\x69\x69\x68\x6d\x49\xe3\x4d\x84\x05\x30\xde\x64\x48\x58\x7a\xa1\x84\x45\xa3\xba\x4d\xca\x75\xe6\x5e\x27\x4e\x7b\xd6\xa1\x74\x05\xb4\xb6\xbd\xf3\xa6\x85\x22\x4c\x9d\xe8\xda\xd5\xa9\xa9\x3c\x7f\x4f\x83\x3a\xab\x76\x4b\xfd\x5d\x25\x34\x5d\x86\xb3\x1e\x03\x3e\xac\x98\x73\x86\x89\x62\x1b\xcc\xdd\x91\x88\xa2\x65\x8d\xea\x1b\xb7\x0b\xee\x4c\x32\xc8\xcc\xb3\xd5\x19\x2d\x93\x2d\x33\xda\xfb\xbd\x2e\x81\x3a\xac\xbb\x0e\x42\xeb\x9d\x39\xb0\x83\x84\x3f\xfa\x00\xa2\x98\x82\x17\x05"

///|
fn play_d25(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D25_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    64, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(192, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 1020, 1020, 1020, 2048, 0, 0,
      0, 0, 0, 0, 0, 0,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 1, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
    13,
    1191,
    "d25",
  )
  expect_dec_state(dec, "d25", 268435456L, 176542719L, 4, 32)
}

///|
test "金标：比特分配 · dynalloc/head 192B" {
  let dec = RangeDecoder::new(ALLOC_D25_BITS)
  play_d25(dec)
}

///|
const ALLOC_D26_BITS : Bytes = b"\x3c\xa3\x34\x72\xd7\xfb\xe1\x7a\x01\x29\x38\x93\x32\xe6\x05\xfb\xa0\x6b\xcb\x80\xb2\xb6\xc0\x27\xae\x2d\x95\x93\xea\x48\x9e\x0c\xbc\xba\xec\xd8\x2e\xcc\xff\x3b\xd9\xfb\xcb\x84\xd7\xf5\x0c\x72\x42\x19\x34\xdb\xf0\x48\xf6\x75\x3e\xe9\xf0\x80\xcd\x9d\xf5\xcd"

///|
fn play_d26(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D26_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    40, 0, 0, 40, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 40,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(64, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 505, 429, 368, 308, 225, 344, 294, 8, 8, 0, 0, 0, 0, 0, 0, 0,
      0, 0,
    ],
    [2, 2, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    21,
    0,
    "d26",
  )
  expect_dec_state(dec, "d26", 2147483648L, 1638819270L, 1, 8)
}

///|
test "金标：比特分配 · dynalloc/scattered 64B" {
  let dec = RangeDecoder::new(ALLOC_D26_BITS)
  play_d26(dec)
}

///|
const ALLOC_D27_BITS : Bytes = b"\x37\xed\x28\x06\xa5\xcf\x5d\xcc\x5c\xb2\x5b\x8d\x93\x27\xae\x9a\x22\x82\x82\xd9\x74\x50\xac\xb1\x70\xcb\xe8\xc3\x53\xef\xbf\xa1\x3f\x62\x1f\xa6\xf3\x84\x32\x8c\xd4\xc5\x2d\x5a\x8b\x25\x28\xd6\x22\xfb\x75\x6f\x12\x3b\x9b\x2e\x0e\x3d\x42\xac\xe7\x07\x42\x0e\x02\xab\xbe\x92\xc4\xf6\xec\x69\xc2\xec\x5f\xf4\x89\x7b\x0c\xf6\x85\x4e\x6d\xb9\x76\x31\x2e\x9f\xfe\xdb\x47\x82\xe3\x45\x80\xdb\x8a\xb6\x7b\xd2\x0d\x65\xed\x47\x94\x57\x4d\xc9\x9b\x69\x83\xb7\x63\xc7\x82\x95\x8a\x62\x34\x34\x73\x81\xd2\x2c\x07\xee\x14\x47\x06\xce\x6c\x9e\x8a\xcc\x3f\x2a\xd5\x80\x22\x65\xc5\xa0\x63\x4a\x2b\x57\xaa\xd5\xc2\x44\x18\x5d\x06\xe1\xa9\x66\x58\x92\x30\x6b\xee\x61\x7a\x25\xab\x62\x33\x5e\xf2\x4a\x41\xfe\x27\xc6\x7c\x1e\xe8\x48\x57\xea\xf7\x60\x2f\x6c\x97\x22\x73\x6a\xec\x08\x56\xc5"

///|
fn play_d27(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D27_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    40, 0, 0, 40, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 40,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(192, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 1020, 1020, 982, 1626, 1185,
      809, 40, 32, 48, 80, 17, 0,
    ],
    [2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 2, 2, 2, 3, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0],
    21,
    0,
    "d27",
  )
  expect_dec_state(dec, "d27", 2147483648L, 1678339068L, 1, 8)
}

///|
test "金标：比特分配 · dynalloc/scattered 192B" {
  let dec = RangeDecoder::new(ALLOC_D27_BITS)
  play_d27(dec)
}

///|
const ALLOC_D28_BITS : Bytes = b"\xb5\x5b\x0e\xbe\xb9\x86\x53\x05\x60\x9e\xb6\x00\x1d\x67\x07\x00\x9a\xf3\x42\x96\x75\xd4\xef\x2e\xf1\x53\xd2\xc1\xad\x75\xb2\x60\x59\xbe\x79\x8d\x08\xf7\xf4\x95\x70\xb4\xfa\x5e\xec\x70\x30\x1e\xfa\x6a\x84\xc6\xe2\xbd\x49\x8d\x65\xd0\xd8\x3f\xca\x18\x21\x75"

///|
fn play_d28(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D28_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 80, 80,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(64, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 481, 438, 376, 315, 230, 352, 273, 8, 8, 0, 0, 0, 0, 0, 0, 0,
      0, 0,
    ],
    [2, 2, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1],
    [1, 1, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    21,
    0,
    "d28",
  )
  expect_dec_state(dec, "d28", 2147483648L, 626161824L, 1, 8)
}

///|
test "金标：比特分配 · dynalloc/tail 64B" {
  let dec = RangeDecoder::new(ALLOC_D28_BITS)
  play_d28(dec)
}

///|
const ALLOC_D29_BITS : Bytes = b"\xfc\xf7\x5a\x58\xd1\x46\x93\xa3\xcc\xef\xcb\xff\x73\x82\x0f\x33\xfe\x5e\x63\x10\x7a\x0a\x34\xc9\x91\x81\x95\x25\x25\x35\x76\x70\x9b\xd9\xfc\xbf\xc2\xa2\xf3\x66\x2e\xf1\x10\xea\x27\xef\x2c\x50\xbd\xb0\xf4\xed\x0d\x07\x69\x06\x9c\x6e\x4e\xa8\x60\x9a\xc4\x93\xf7\x5f\x32\x30\x7b\x7e\xa5\xc3\xf6\x29\x56\x8c\xe3\x29\x94\x9d\xf5\x4e\x31\x50\x2b\xb8\xbd\x29\x93\x3f\x67\x7c\x80\xc1\x31\xe1\xa5\x8f\x13\xc1\xbd\x03\x2b\x62\xf0\xbf\x4d\xbb\xa2\x72\x55\xdc\x95\x5a\x69\x9d\xbb\x7a\x26\xcc\xdb\x8f\xa1\xda\x52\x4b\xa8\xc2\xf8\x2f\xf7\xa5\xf3\x00\x4e\x3b\x3d\xbf\xa9\xa9\xc4\x93\xe0\x11\xfe\xf2\x2b\x87\x02\x2e\x34\x04\x79\xce\xb4\xc2\x91\x34\xe2\x10\x14\xec\x05\xd1\xe5\x78\x69\x18\xe2\xd8\x48\xdc\x58\x9c\x02\xd1\x12\xc5\x5d\x8c\x8f\x0b\xc9\xad\x35\x5a\x83\xf2\x80\x30\x65\x76"

///|
fn play_d29(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D29_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 80, 80,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(192, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 1020, 1020, 982, 1626, 1185,
      769, 40, 32, 48, 88, 49, 0,
    ],
    [2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 3, 1, 2, 2, 2, 2, 2, 2, 2, 3, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0],
    21,
    0,
    "d29",
  )
  expect_dec_state(dec, "d29", 2147483648L, 25449171L, 1, 8)
}

///|
test "金标：比特分配 · dynalloc/tail 192B" {
  let dec = RangeDecoder::new(ALLOC_D29_BITS)
  play_d29(dec)
}

///|
const ALLOC_W30_BITS : Bytes = b"\x95\xe3"

///|
fn play_w30(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_W30_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(2, dec),
    3,
  )
  expect_alloc(
    got,
    [31, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    1,
    0,
    "w30",
  )
  expect_dec_state(dec, "w30", 2147483648L, 890142719L, 1, 8)
}

///|
test "金标：比特分配 · 极小预算 2B" {
  let dec = RangeDecoder::new(ALLOC_W30_BITS)
  play_w30(dec)
}

///|
const ALLOC_W31_BITS : Bytes = b"\x64"

///|
fn play_w31(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_W31_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(
    dec,
    0,
    21,
    offsets,
    cap,
    5,
    celt_alloc_total(1, dec),
    3,
  )
  expect_alloc(
    got,
    [23, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    1,
    0,
    "w31",
  )
  expect_dec_state(dec, "w31", 2147483648L, 1308622847L, 1, 8)
}

///|
test "金标：比特分配 · 单字节载荷" {
  let dec = RangeDecoder::new(ALLOC_W31_BITS)
  play_w31(dec)
}

///|
const ALLOC_W32_BITS : Bytes = b"\xee\x7f\x88\x1e\x1b\xb2\xb5\x1c\x1b\x7e\x4a\x04\x33\x44\x1e\x17\x01\xb7\xef\x05\xc6\x17\x3e\x6d\xf7\x97\x46\x43\x6e\xe1\x78\x0c\xa1\x99\x41\x1b\x3c\x3f\x1d\xe2\xe6\xac\x3c\x49\x41\xa7\x19\xa4\x0d\xb1\xf8\x06\xf6\xfb\x43\x2f\xc0\xf0\x21\x47\x11\x49\x79\xbc\xe1\x19\xc3\x9c\x24\x85\x62\xa0\x64\x87\x7d\x3c\x62\xfb\x7d\xbd\x28\xe3\x39\xc8\xee\x4c\xe2\x54\x2f\xf3\x11\x88\xe8\xe3\xa6\xd6\xc7\x3d\xc9\x8c\x0d\x12\xd5\xad\x72\x66\x4d\x0d\xf3\x09\x30\x21\x38\x81\x9d\xaf\x63\xaf\xfb\x41\x45\x9d\x05\xac\x0b\xb2\x06\x82\x38\x3f\x63\x75\xf7\x26\x95\xf8\x35\x70\x84\x8a\xe2\x43\xbe\x1e\x07\x63\xed\xc8\x4f\x6e\xcf\xd4\xbe\x05\x67\x52\x9b\x7d\xcf\x1e\xea\x63\xfc\x7d\xae\x54\xd4\x25\x3a\x8b\x94\x9f\xbc\xc6\xec\xf6\xc1\x3d\xf4\x8a\xcf\x58\xb9\xf1\x60\xb2\xd9\xf2\x5d\xfe\x5d\x9f"

///|
fn play_w32(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_W32_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    249, 249, 249, 249, 249, 249, 249, 249, 514, 514, 514, 514, 1028, 1028, 1028,
    1482, 1482, 1888, 2424, 2322, 2266,
  ]
  let got = celt_compute_allocation(
    dec,
    5,
    17,
    offsets,
    cap,
    3,
    celt_alloc_total(192, dec),
    2,
  )
  expect_alloc(
    got,
    [
      0, 0, 0, 0, 0, 241, 241, 241, 498, 498, 498, 498, 1012, 1012, 1012, 1458, 1458,
      0, 0, 0, 0,
    ],
    [0, 0, 0, 0, 0, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    17,
    2836,
    "w32",
  )
  expect_dec_state(dec, "w32", 1073741824L, 146815984L, 2, 16)
}

///|
test "金标：比特分配 · 带窗 5..17 lm=2" {
  let dec = RangeDecoder::new(ALLOC_W32_BITS)
  play_w32(dec)
}

///|
const ALLOC_W33_BITS : Bytes = b"\xfd\xf7\x69\x29\x0f\x26\x13\xb6\x14\x42\xcd\xfd\x3e\xae\x07\xb2\x13\x8a\xbb\xad\x31\x8f\x5a\xbe\xaf\x48\x12\xf3\x01\x26\x92\xee\x31\x35\xc5\xb2\x60\xbe\x5a\xe3\x93\x88\x29\x1c\x2f\xd8\x9a\xf5\xcd\x25\xe7\x90\x1d\x29\x12\x86\x72\x9c\xf3\x94\xd4\x32\xea\xbd"

///|
fn play_w33(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_W33_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    40, 0, 0, 40, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 40,
  ]
  let cap : Array[Int] = [
    112, 112, 112, 112, 112, 112, 112, 112, 249, 249, 249, 249, 514, 514, 514, 741,
    741, 944, 1212, 1152, 1122,
  ]
  let got = celt_compute_allocation(
    dec,
    5,
    17,
    offsets,
    cap,
    0,
    celt_alloc_total(64, dec),
    1,
  )
  expect_alloc(
    got,
    [
      0, 0, 0, 0, 0, 96, 96, 96, 225, 225, 225, 225, 451, 438, 468, 639, 623, 0,
      0, 0, 0,
    ],
    [0, 0, 0, 0, 0, 2, 2, 2, 4, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
    17,
    0,
    "w33",
  )
  expect_dec_state(dec, "w33", 1073741824L, 17058667L, 2, 16)
}

///|
test "金标：比特分配 · 带窗 5..17 加成" {
  let dec = RangeDecoder::new(ALLOC_W33_BITS)
  play_w33(dec)
}

///|
const ALLOC_X34_BITS : Bytes = b"\xd4\x46\xda\x63\xfb\xff\xf0\x7c\xa8\xe4\xcf\xb9\x45\x3a\x3d\xfa\x2d\x28\xb3\x4a\x54\x10\x6d\x9f\x01\xb2\xb1\x08\x23\xc3\x0b\xb9\x6c\xf4\x77\x56\xea\x2f\xe5\x07\x42\xa3\x63\x1e\x68\xbd\x12\x0d\x32\x02\x17\x18\x4c\xdf\x5d\x76\x74\x52\x70\x2e\xe6\x6b\xc8\xb8"

///|
fn play_x34(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_X34_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    64, 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(dec, 0, 21, offsets, cap, 7, 300000, 3)
  expect_alloc(
    got,
    [
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 1020, 1020, 1020, 2048, 2048,
      2048, 2952, 2952, 3768, 4848, 4620, 4508,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    21,
    260728,
    "x34",
  )
  expect_dec_state(dec, "x34", 1073741824L, 366777038L, 2, 16)
}

///|
test "金标：比特分配 · 极端预算 300000" {
  let dec = RangeDecoder::new(ALLOC_X34_BITS)
  play_x34(dec)
}

///|
const ALLOC_X35_BITS : Bytes = b"\xd8\xef\x2c\x0d\x78\x17\x20\x91\xf6\x16\x95\x4c\x96\x10\xf2\xc8\x37\x80\x0a\x2c\xe2\x7f\xf2\x68\x07\x5d\xcd\x27\x5e\x6c\x08\xf1\xc6\x83\xd7\x07\x8c\xdd\xdb\xdc\xc6\x0f\x68\x10\xba\x65\x9c\x5d\x0d\xa2\x95\xcc\x82\x6c\xed\xf6\x07\x6a\x49\xf9\xac\x63\x6a\xd1"

///|
fn play_x35(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_X35_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    40, 0, 0, 40, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 40,
  ]
  let cap : Array[Int] = [
    72, 72, 72, 72, 72, 72, 72, 72, 112, 112, 112, 112, 249, 249, 249, 363, 363,
    464, 594, 562, 555,
  ]
  let got = celt_compute_allocation(dec, 0, 21, offsets, cap, 7, 900000, 0)
  expect_alloc(
    got,
    [
      8, 8, 8, 8, 8, 8, 8, 8, 72, 72, 72, 72, 201, 201, 201, 315, 315, 416, 554,
      538, 531,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    21,
    895032,
    "x35",
  )
  expect_dec_state(dec, "x35", 2147483648L, 327707129L, 1, 8)
}

///|
test "金标：比特分配 · 极端预算 900000" {
  let dec = RangeDecoder::new(ALLOC_X35_BITS)
  play_x35(dec)
}

///|
const ALLOC_X36_BITS : Bytes = b"\x7b\x76\x46\x1f\x33\x8d\xc6\x2d\x5f\xb6\x24\x94\x28\xea\x7d\x40\x93\xaf\x14\x83\x1c\x39\xda\xdf\x20\x92\xd1\xa7\xed\x3d\xe8\x94\x64\xf7\x82\xd9\x0b\x1c\x63\x3d\xdf\xa4\x62\xcc\xba\xcc\xdb\x68\x9c\xe8\xb4\xc2\x3d\x50\x9e\xd8\x80\xe8\x0d\x22\x58\x51\xea\x8c"

///|
fn play_x36(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_X36_BITS；期望值由
  // tools/gen_alloc_goldens.py 的独立参考端算出。
  let offsets : Array[Int] = [
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 80, 80, 80,
  ]
  let cap : Array[Int] = [
    514, 514, 514, 514, 514, 514, 514, 514, 1028, 1028, 1028, 1028, 2064, 2064, 2064,
    2976, 2976, 3792, 4872, 4644, 4532,
  ]
  let got = celt_compute_allocation(dec, 0, 21, offsets, cap, 5, 50000, 3)
  expect_alloc(
    got,
    [
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 1020, 1020, 1020, 2048, 2048,
      2048, 2952, 2952, 3768, 4848, 4620, 4508,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    21,
    10736,
    "x36",
  )
  expect_dec_state(dec, "x36", 2147483648L, 1111809264L, 1, 8)
}

///|
test "金标：比特分配 · 中等预算 50000" {
  let dec = RangeDecoder::new(ALLOC_X36_BITS)
  play_x36(dec)
}
