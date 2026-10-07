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
    [8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    1,
    143,
    "b1",
  )
  expect_dec_state(dec, "b1", 1073741824L, 1755272855L, 18, 144)
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
    "b3",
  )
  expect_dec_state(dec, "b3", 1073741824L, 10733321L, 2, 16)
}

///|
test "金标：比特分配 · 基线 8B lm=3 trim=0" {
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
    "b4",
  )
  expect_dec_state(dec, "b4", 1073741824L, 342151114L, 2, 16)
}

///|
test "金标：比特分配 · 基线 8B lm=3 trim=5" {
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
    "b5",
  )
  expect_dec_state(dec, "b5", 1073741824L, 68785843L, 2, 16)
}

///|
test "金标：比特分配 · 基线 8B lm=3 trim=7" {
  let dec = RangeDecoder::new(ALLOC_B5_BITS)
  play_b5(dec)
}

///|
const ALLOC_B6_BITS : Bytes = b"\xb1\x1c\x75\xe3\x06\x69\xa5\x00\x6b\x9e\x4d\x24\xcf\x0f\x9d\x01\x8b\x19\x98\x04\x14\x86\x93\x2e\x2f\xc5\x04\xe6\xc1\xfa\xb5\xa6\xce\x36\xd2\x5e\xeb\x82\xda\x32\x61\x21\xc2\x67\x54\x42\xb8\x29\x03\x2b\x1f\xf7\xab\xbc\x49\x7b\x11\xc8\x28\x16\xf9\xea\xe3\x28"

///|
fn play_b6(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B6_BITS；期望值由
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
    "b6",
  )
  expect_dec_state(dec, "b6", 1073741824L, 661767438L, 2, 16)
}

///|
test "金标：比特分配 · 基线 64B lm=0 trim=0" {
  let dec = RangeDecoder::new(ALLOC_B6_BITS)
  play_b6(dec)
}

///|
const ALLOC_B7_BITS : Bytes = b"\x10\x59\x9f\x5a\x73\x1d\x64\x1b\xe4\x91\x10\x11\xdf\x60\x7b\x24\x3d\x1d\x8d\xda\x96\x94\x74\x0d\xaa\xa5\x2e\x7c\x05\x19\xe3\x3e\xe9\xc9\x91\xd8\x88\x10\xc0\x8a\xd3\x5e\x67\x09\xfd\xe8\x5e\xf6\x64\x3a\x79\x23\xba\xa3\xbf\x03\x58\x49\x80\xc6\x6f\x93\x31\x86"

///|
fn play_b7(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B7_BITS；期望值由
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
    [8, 8, 8, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [8, 8, 8, 8, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    3463,
    "b7",
  )
  expect_dec_state(dec, "b7", 1073741824L, 810731121L, 18, 144)
}

///|
test "金标：比特分配 · 基线 64B lm=0 trim=5" {
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
    7,
    celt_alloc_total(64, dec),
    0,
  )
  expect_alloc(
    got,
    [
      8, 8, 8, 8, 8, 8, 8, 8, 72, 72, 66, 63, 173, 169, 165, 257, 252, 333, 476,
      538, 531,
    ],
    [6, 5, 6, 6, 6, 6, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 4, 3, 3],
    [1, 0, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0],
    21,
    0,
    "b8",
  )
  expect_dec_state(dec, "b8", 1073741824L, 237562725L, 2, 16)
}

///|
test "金标：比特分配 · 基线 64B lm=0 trim=7" {
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
    [506, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1],
    1,
    3325,
    "b9",
  )
  expect_dec_state(dec, "b9", 268435456L, 2088987653L, 12, 96)
}

///|
test "金标：比特分配 · 基线 64B lm=3 trim=0" {
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
    [506, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    1,
    3357,
    "b10",
  )
  expect_dec_state(dec, "b10", 1073741824L, 1788252310L, 10, 80)
}

///|
test "金标：比特分配 · 基线 64B lm=3 trim=5" {
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
    [
      506, 480, 445, 416, 379, 335, 291, 234, 386, 325, 210, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0,
    ],
    [2, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1],
    11,
    0,
    "b11",
  )
  expect_dec_state(dec, "b11", 1073741824L, 574584853L, 2, 16)
}

///|
test "金标：比特分配 · 基线 64B lm=3 trim=7" {
  let dec = RangeDecoder::new(ALLOC_B11_BITS)
  play_b11(dec)
}

///|
const ALLOC_B12_BITS : Bytes = b"\xad\x51\x4a\xce\x6a\x0f\xb0\x83\xdd\x65\x4e\xe1\xd4\x03\xcc\xe8\x35\xf4\x72\xc7\xf7\xb8\x55\x6a\xc7\x40\xf6\x92\x73\x37\x5a\x00\x8a\x25\x19\x73\x59\xbb\x66\x70\x1f\x5f\x79\xab\xcf\x30\xb6\x4e\xb9\x1a\x5d\x0e\x63\x7f\x4a\x74\x18\x3d\x11\x85\x89\xad\x04\xcd\x25\x33\xc5\x93\xa1\xc9\xad\x40\x90\xfb\x51\x9a\x60\x58\x94\xe2\x72\xcf\x1b\xe6\x51\x56\xb5\xb9\x44\xa8\x4d\xf2\x5f\x56\xdc\xf5\xe4\x9c\xa7\xb6\xd5\x69\xa7\x05\x07\x5f\x33\x35\x9b\xaa\x2b\x2a\x4a\x81\x88\xdb\xfc\x7f\x9c\xbb\x85\xff\x5c\x1b\x84\x06\x81\x42\xfe\x1b\x11\x4c\x51\x66\x13\x85\xe1\x2f\x82\x00\x0c\x06\xfe\x6f\xd7\xa3\x56\x0a\xc1\x37\x5d\x06\xbe\xc2\xb6\x69\x1b\x9b\x72\xf7\x7c\x87\x7c\xda\xc4\x1b\xe3\x5e\x80\x7d\x71\x1d\xef\xcb\x0a\x4c\x7d\x92\x59\x6d\x93\x10\xa3\x53\x79\xd9\xcf\xec\x1e\xba\xcd\x30"

///|
fn play_b12(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B12_BITS；期望值由
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
    "b12",
  )
  expect_dec_state(dec, "b12", 1073741824L, 693590680L, 2, 16)
}

///|
test "金标：比特分配 · 基线 192B lm=0 trim=0" {
  let dec = RangeDecoder::new(ALLOC_B12_BITS)
  play_b12(dec)
}

///|
const ALLOC_B13_BITS : Bytes = b"\xfb\x82\x5e\x0d\xc4\x1c\xc4\x7d\x84\x00\xa9\x26\xe4\xa9\x23\x6b\x81\x97\x52\xc8\xb5\xa6\x67\x3e\x4b\xc8\x35\xd3\x3d\xc1\xf6\x5c\x24\x96\xa3\x93\x66\x0c\x90\xb8\xfd\xe4\x21\xa5\x83\x8d\xd2\xff\xf2\xde\x24\x94\x9a\x54\xa5\x84\x40\xb9\x0f\x78\xd8\x41\xdd\x24\x5b\xaa\x9e\x24\x95\x6d\x7c\xbd\x99\x3a\x8a\x17\x69\x70\xde\xee\x53\xa3\xd5\x10\x38\x8d\x6a\x33\x86\xcf\x94\x63\x26\x11\x73\xce\xe8\x18\x72\x51\x13\x14\xc7\xbf\x02\x8a\x17\xf0\xe5\xf6\x45\x80\x92\xad\x94\x79\x1c\x2c\x35\xab\x52\xe7\xd7\x28\xf4\x87\x1b\xe9\x5b\x0c\xf9\x4a\x2c\xed\xbe\xb1\x4f\x02\x86\xcf\x5b\xd4\x48\x5e\x9a\x26\x72\xcf\x96\x46\xbf\x0e\xba\xd4\x9e\x9b\xc9\xa1\xd8\x14\xf6\x32\xb4\x0c\xf7\xe8\x89\xf9\x42\x6f\x86\x1e\xfe\x04\x9e\xb6\x7a\x7d\x5d\x12\x24\x63\x47\xd0\xf9\x72\xd3\xd9\xd0\x6c\xc4\x32"

///|
fn play_b13(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B13_BITS；期望值由
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
    "b13",
  )
  expect_dec_state(dec, "b13", 1073741824L, 37671161L, 2, 16)
}

///|
test "金标：比特分配 · 基线 192B lm=0 trim=5" {
  let dec = RangeDecoder::new(ALLOC_B13_BITS)
  play_b13(dec)
}

///|
const ALLOC_B14_BITS : Bytes = b"\x02\x7a\x82\x11\xd8\xdb\x58\xee\xfa\x80\xd5\xf0\x34\x02\x6e\x4b\x7f\x48\xbd\xa9\x7d\x5f\x7d\x1c\x8e\xec\xfa\xb6\xd8\x2c\x11\xaa\x5a\x74\xea\x38\x69\x70\x20\x23\xf4\xc8\x3e\xfa\x6d\x19\xe3\x6e\x0b\x93\x25\xca\x4c\xb7\x1e\x43\x30\xe2\x10\x88\x04\xae\x08\x58\xb5\x1f\x55\xd6\x68\xb1\x7a\x3f\x08\x3e\x15\x96\x3f\xf7\xd7\xf7\x45\x1e\x42\xd3\x40\x94\x7c\xd9\xc1\x31\x61\xf5\x63\x7b\xc5\x67\xdc\x7c\x95\x5a\xa7\x6d\x87\x08\xc2\xcc\x1a\xf5\x3f\xfb\x75\x9b\xfe\x4d\x07\x4e\xa7\x7c\x02\xc7\xcd\x06\x27\xf9\x0d\x84\xa0\x58\x4e\x20\xd3\x67\xdb\x5e\x5b\x92\x87\x14\x94\x38\x6b\xc9\x4d\x38\xac\x78\x13\xa3\xd4\xfa\x74\x52\x8d\xbc\xdd\x8c\xb8\x16\xdd\xf8\xdd\x18\x78\x33\xd7\xb6\x98\x25\xe5\xc1\x36\xd3\xe2\xc1\x70\xec\x24\x34\x45\x99\xab\x8a\x21\xb0\xef\x3f\xb3\xd5\x1e\x06\x36\xd3"

///|
fn play_b14(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_B14_BITS；期望值由
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
    [8, 8, 8, 8, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [8, 8, 8, 8, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    5,
    11655,
    "b14",
  )
  expect_dec_state(dec, "b14", 1073741824L, 1056379794L, 18, 144)
}

///|
test "金标：比特分配 · 基线 192B lm=0 trim=7" {
  let dec = RangeDecoder::new(ALLOC_B14_BITS)
  play_b14(dec)
}

///|
const ALLOC_B15_BITS : Bytes = b"\x35\x9a\xf9\xcd\x8f\xdf\x9c\xf4\x04\x38\xd3\xfd\xd2\xa9\x76\x76\x9b\x17\x75\xc2\x3b\x22\x82\xd9\x90\xe2\x83\xae\x68\xd5\x42\x36\x00\x5c\x02\xc8\xcd\x04\x28\x71\x72\x7e\x10\xf0\x43\x20\xf0\x68\xc3\xf2\xc5\xaf\x41\xd8\x10\xde\x75\x1b\x0e\xa8\x49\xdb\xda\x14\x57\x43\x5b\x5b\x8a\x81\x05\xaa\x68\x60\x17\x54\xa7\xe0\xfb\x08\x8e\x41\x0d\x9f\x95\xf9\x0c\x4c\x24\xfd\xb3\x89\xf4\x81\x3e\x0c\xf9\x2b\x2d\x45\x5e\xbc\xd3\xa7\x23\x88\x21\x7a\xc6\x6b\x6a\x39\x76\x95\xbf\xa4\x96\x97\xde\x5c\x1a\x0f\x54\x83\x18\x1e\x69\xbb\xe9\x7b\xe1\xfd\xa8\x58\xf8\x4e\xf1\xb6\x9c\x7a\x12\x2f\xb8\xe6\x7b\x3c\xa0\xa6\x58\x5b\xec\x4b\x6b\x66\x54\x97\x89\xe7\x72\x71\x17\xf1\x05\xb4\x9c\x17\xe0\xb6\x12\xde\x30\xb4\x1f\x1d\xa3\x81\x2b\x7b\x26\x96\xee\xeb\x0d\xa3\x25\xdb\x53\x0b\x03\xe6\xec\x07"

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
    0,
    celt_alloc_total(192, dec),
    3,
  )
  expect_alloc(
    got,
    [
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0,
    ],
    [8, 8, 8, 8, 8, 8, 8, 8, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    9,
    6467,
    "b15",
  )
  expect_dec_state(dec, "b15", 1073741824L, 847452472L, 10, 80)
}

///|
test "金标：比特分配 · 基线 192B lm=3 trim=0" {
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
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 1020, 1020, 999, 1658, 1217,
      801, 0, 0, 0, 0, 0, 0,
    ],
    [4, 4, 4, 4, 4, 4, 4, 4, 7, 5, 5, 1, 2, 2, 2, 1, 1, 1, 1, 1, 0],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1],
    15,
    0,
    "b16",
  )
  expect_dec_state(dec, "b16", 1073741824L, 580658900L, 2, 16)
}

///|
test "金标：比特分配 · 基线 192B lm=3 trim=5" {
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
      506, 506, 506, 506, 506, 506, 506, 506, 1020, 1020, 1020, 1020, 1773, 1337,
      857, 0, 0, 0, 0, 0, 0,
    ],
    [2, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 1, 1, 0, 0, 0, 0],
    [1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1],
    15,
    0,
    "b17",
  )
  expect_dec_state(dec, "b17", 1073741824L, 76730215L, 2, 16)
}

///|
test "金标：比特分配 · 基线 192B lm=3 trim=7" {
  let dec = RangeDecoder::new(ALLOC_B17_BITS)
  play_b17(dec)
}

///|
const ALLOC_D18_BITS : Bytes = b"\x41\x0e\xce\x98\x3d\xde\x78\x78\x11\x15\x20\xde\x11\xea\x0b\x28\x54\x73\x67\xdc\xac\x63\xf2\xa6\xe7\x96\x94\x10\xcc\x51\x73\xba\xa3\xe8\xae\x86\x22\x85\x61\x3c\x33\x49\x79\x06\xb4\x52\x07\x14\x70\xab\xc0\xb6\x20\xd0\xa8\xe8\x69\x7f\x80\x0e\x15\x2d\x70\x95"

///|
fn play_d18(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D18_BITS；期望值由
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
    [506, 506, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [8, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    2,
    2803,
    "d18",
  )
  expect_dec_state(dec, "d18", 2147483648L, 2023273441L, 9, 72)
}

///|
test "金标：比特分配 · dynalloc/head 64B" {
  let dec = RangeDecoder::new(ALLOC_D18_BITS)
  play_d18(dec)
}

///|
const ALLOC_D19_BITS : Bytes = b"\x4f\x7c\xfe\x52\x7d\x7f\xa2\x95\xd3\x7a\xd6\xea\x24\xa4\x10\xbe\xbf\xad\x8a\x68\xf7\x36\x37\x50\x94\xe2\xd0\x1a\x5f\x3c\x16\x19\x20\xc9\xa5\xee\xdf\x96\xcd\x5d\x91\x6c\x91\x34\x9c\x60\xad\x0b\x7c\x97\x6a\xad\x01\x55\xa0\x25\x46\x2b\xdd\xc8\x59\xec\xb9\x5c\xc2\x7b\xdb\xa1\x9c\xea\xe0\x82\x83\xfb\x91\x97\x12\xd3\xb9\xb7\x74\x5f\x40\xde\xba\x7a\x96\xa3\x97\x9b\x17\x1b\xdb\x24\xae\x42\x69\x7e\xb0\xbd\x77\x27\x4d\x3e\xcc\xe3\x5f\x2b\x83\xdc\xe1\x13\x34\x85\x98\xed\x28\x8b\xf0\x1d\xb4\xaa\x74\xa9\x68\x62\x63\xf6\x2b\xdb\x07\x58\x21\x3f\xa8\xc3\x83\x2a\x2d\x78\x9d\x7b\xb9\xd8\x76\x05\x81\x23\x70\xe7\x7b\xab\x80\x6a\x04\x1c\x6b\xe3\x33\xd3\xa4\xd6\x78\x97\x94\xe4\x3d\xb8\x20\x0d\x92\x32\x5b\x21\x45\x16\xdd\x34\xf5\xf8\xd7\x90\x12\xac\xdf\xb9\x9b\x33\x91\xba\xad\xed"

///|
fn play_d19(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D19_BITS；期望值由
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
    [506, 506, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    [8, 8, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    2,
    10891,
    "d19",
  )
  expect_dec_state(dec, "d19", 67108864L, 1098962625L, 14, 112)
}

///|
test "金标：比特分配 · dynalloc/head 192B" {
  let dec = RangeDecoder::new(ALLOC_D19_BITS)
  play_d19(dec)
}

///|
const ALLOC_D20_BITS : Bytes = b"\x59\xec\xe2\xf2\xbc\xd6\x51\x2e\xea\x7a\x6b\xd1\x69\x4c\xf1\xe7\x35\x52\xfb\xf3\x14\xe2\x19\xb0\x6f\x3e\x2f\x86\x4f\x0d\x99\xed\x79\x9d\xeb\x7d\x14\x7b\x7d\x96\x97\x41\xd8\xc5\x94\x52\xe6\xb2\x32\x2d\x78\x7a\x17\x32\x47\x1d\xb4\x7c\xea\x35\xd9\x74\xfb\xad"

///|
fn play_d20(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D20_BITS；期望值由
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
    "d20",
  )
  expect_dec_state(dec, "d20", 2147483648L, 1393135238L, 1, 8)
}

///|
test "金标：比特分配 · dynalloc/scattered 64B" {
  let dec = RangeDecoder::new(ALLOC_D20_BITS)
  play_d20(dec)
}

///|
const ALLOC_D21_BITS : Bytes = b"\xce\x8d\x7e\x11\xe3\xf2\x20\xa0\x8a\x97\xf3\x27\x52\x54\x1b\x35\x96\x1a\xef\x3a\x66\xe1\x8f\xac\xbe\xca\x39\x70\x7c\xed\xe2\xf0\x3b\x71\xed\xf2\x90\x45\x8f\x02\x0a\x75\x63\x57\x7e\xcd\xda\xbc\x85\x1b\x8c\x27\x2b\x59\xe6\x70\x46\xdb\xcb\x89\xdf\x5a\xda\x45\xf3\x91\x37\xb1\x05\xe7\x96\xb4\x39\x26\x2f\xdd\xa7\x31\x33\x52\xca\x51\xba\x69\x46\x28\x3b\x0f\xaf\xad\x17\x8c\x0d\xd4\x5b\x38\x13\x03\xd5\xad\x12\xcc\xf5\xb6\x7a\x81\x8a\xaa\x5c\xdd\xb3\xc0\x56\xa4\x21\x55\x75\x0e\xfb\x4c\xeb\x72\xac\x53\x19\xae\x5f\x90\x5e\xb6\x69\x07\xbd\x8d\x1f\x66\xd1\x28\x9b\x55\xd2\xf6\x1e\x72\xa2\x3a\xeb\x4e\x88\xa9\x3a\xd0\x88\x73\x15\x98\xef\xfd\x90\xe6\xcd\xec\x95\xdc\xc7\x07\x44\xcf\x82\x98\xbb\x80\x8a\x74\x1e\x8a\x80\xc0\x36\x33\x0b\x7a\xce\x8e\x51\xe7\x76\x2b\x40\x8e\x8a\xf3"

///|
fn play_d21(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D21_BITS；期望值由
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
    "d21",
  )
  expect_dec_state(dec, "d21", 2147483648L, 414793975L, 1, 8)
}

///|
test "金标：比特分配 · dynalloc/scattered 192B" {
  let dec = RangeDecoder::new(ALLOC_D21_BITS)
  play_d21(dec)
}

///|
const ALLOC_D22_BITS : Bytes = b"\x93\xe2\x9e\x1f\xd3\xa0\x06\xdc\x9e\xe9\x13\x87\x14\xbc\x93\xcf\x22\xd5\x87\xe2\x55\x07\x1a\x75\xf7\xd7\x23\x3a\x36\xc7\xe7\x8d\x10\xa5\xdf\x83\x01\xdd\x44\x0e\x0d\xd7\xa4\xd8\x90\x2f\x36\x5d\x33\xd3\xcc\xe5\x41\x8a\xde\x51\x35\x63\x43\x24\xee\x41\xcc\x32"

///|
fn play_d22(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D22_BITS；期望值由
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
    "d22",
  )
  expect_dec_state(dec, "d22", 2147483648L, 906932464L, 1, 8)
}

///|
test "金标：比特分配 · dynalloc/tail 64B" {
  let dec = RangeDecoder::new(ALLOC_D22_BITS)
  play_d22(dec)
}

///|
const ALLOC_D23_BITS : Bytes = b"\xc4\xe4\xc7\xa3\xac\x33\x3f\x9b\x9a\x5b\x77\x5a\x08\x6b\xb9\x23\x40\x13\x66\x4f\xf5\xe4\xae\x21\x26\xec\xff\x0f\x3e\x79\x36\x25\x23\x47\xc6\xf5\x68\x5d\x6c\x94\x8a\x3c\x1c\xbf\xf3\x4e\x96\x2c\xcf\xa0\x8d\xa3\x91\x45\x51\xe0\x27\xb6\x74\x4a\xb1\x3c\x0a\x8c\x5b\x00\x90\x49\x66\x56\x80\xde\x30\xd9\xfa\xdb\x2d\xa0\xa9\x3b\x22\xf8\xf4\xfa\x26\xc6\x7e\x0e\xdb\x66\xb3\x11\x63\x32\x23\x89\x5b\x8d\x6a\x15\x96\x18\xc2\xbd\xcd\x0e\xaa\x80\x3e\xb0\x3e\x8e\x90\x14\x70\x6b\xb8\x92\x4e\x50\x2c\x29\x77\x46\x72\x3f\x99\x75\x18\x47\xa0\xf2\xda\x8b\xf4\x37\x6a\x14\xca\x56\x29\x17\xf5\x44\xdb\xa5\xbd\x7e\x61\x3c\x11\xc3\x2b\xcc\xe6\x5a\x7a\x6f\x30\xe9\x15\x0d\xa4\xb7\xfc\xda\x1d\x6c\xcc\xcb\xfc\xc6\x97\x86\x49\x3e\x9f\x46\x78\xe1\x87\xe3\xa6\x20\xdb\x83\x05\x3c\x93\x03\x2b\x75"

///|
fn play_d23(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_D23_BITS；期望值由
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
    "d23",
  )
  expect_dec_state(dec, "d23", 2147483648L, 495819822L, 1, 8)
}

///|
test "金标：比特分配 · dynalloc/tail 192B" {
  let dec = RangeDecoder::new(ALLOC_D23_BITS)
  play_d23(dec)
}

///|
const ALLOC_W24_BITS : Bytes = b"\x95\xe3"

///|
fn play_w24(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_W24_BITS；期望值由
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
    "w24",
  )
  expect_dec_state(dec, "w24", 2147483648L, 890142719L, 1, 8)
}

///|
test "金标：比特分配 · 极小预算 2B" {
  let dec = RangeDecoder::new(ALLOC_W24_BITS)
  play_w24(dec)
}

///|
const ALLOC_W25_BITS : Bytes = b"\x64"

///|
fn play_w25(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_W25_BITS；期望值由
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
    "w25",
  )
  expect_dec_state(dec, "w25", 2147483648L, 1308622847L, 1, 8)
}

///|
test "金标：比特分配 · 单字节载荷" {
  let dec = RangeDecoder::new(ALLOC_W25_BITS)
  play_w25(dec)
}

///|
const ALLOC_W26_BITS : Bytes = b"\xee\x7f\x88\x1e\x1b\xb2\xb5\x1c\x1b\x7e\x4a\x04\x33\x44\x1e\x17\x01\xb7\xef\x05\xc6\x17\x3e\x6d\xf7\x97\x46\x43\x6e\xe1\x78\x0c\xa1\x99\x41\x1b\x3c\x3f\x1d\xe2\xe6\xac\x3c\x49\x41\xa7\x19\xa4\x0d\xb1\xf8\x06\xf6\xfb\x43\x2f\xc0\xf0\x21\x47\x11\x49\x79\xbc\xe1\x19\xc3\x9c\x24\x85\x62\xa0\x64\x87\x7d\x3c\x62\xfb\x7d\xbd\x28\xe3\x39\xc8\xee\x4c\xe2\x54\x2f\xf3\x11\x88\xe8\xe3\xa6\xd6\xc7\x3d\xc9\x8c\x0d\x12\xd5\xad\x72\x66\x4d\x0d\xf3\x09\x30\x21\x38\x81\x9d\xaf\x63\xaf\xfb\x41\x45\x9d\x05\xac\x0b\xb2\x06\x82\x38\x3f\x63\x75\xf7\x26\x95\xf8\x35\x70\x84\x8a\xe2\x43\xbe\x1e\x07\x63\xed\xc8\x4f\x6e\xcf\xd4\xbe\x05\x67\x52\x9b\x7d\xcf\x1e\xea\x63\xfc\x7d\xae\x54\xd4\x25\x3a\x8b\x94\x9f\xbc\xc6\xec\xf6\xc1\x3d\xf4\x8a\xcf\x58\xb9\xf1\x60\xb2\xd9\xf2\x5d\xfe\x5d\x9f"

///|
fn play_w26(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_W26_BITS；期望值由
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
    "w26",
  )
  expect_dec_state(dec, "w26", 1073741824L, 146815984L, 2, 16)
}

///|
test "金标：比特分配 · 带窗 5..17 lm=2" {
  let dec = RangeDecoder::new(ALLOC_W26_BITS)
  play_w26(dec)
}

///|
const ALLOC_W27_BITS : Bytes = b"\xfd\xf7\x69\x29\x0f\x26\x13\xb6\x14\x42\xcd\xfd\x3e\xae\x07\xb2\x13\x8a\xbb\xad\x31\x8f\x5a\xbe\xaf\x48\x12\xf3\x01\x26\x92\xee\x31\x35\xc5\xb2\x60\xbe\x5a\xe3\x93\x88\x29\x1c\x2f\xd8\x9a\xf5\xcd\x25\xe7\x90\x1d\x29\x12\x86\x72\x9c\xf3\x94\xd4\x32\xea\xbd"

///|
fn play_w27(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_W27_BITS；期望值由
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
    "w27",
  )
  expect_dec_state(dec, "w27", 1073741824L, 17058667L, 2, 16)
}

///|
test "金标：比特分配 · 带窗 5..17 加成" {
  let dec = RangeDecoder::new(ALLOC_W27_BITS)
  play_w27(dec)
}

///|
const ALLOC_X28_BITS : Bytes = b"\xd4\x46\xda\x63\xfb\xff\xf0\x7c\xa8\xe4\xcf\xb9\x45\x3a\x3d\xfa\x2d\x28\xb3\x4a\x54\x10\x6d\x9f\x01\xb2\xb1\x08\x23\xc3\x0b\xb9\x6c\xf4\x77\x56\xea\x2f\xe5\x07\x42\xa3\x63\x1e\x68\xbd\x12\x0d\x32\x02\x17\x18\x4c\xdf\x5d\x76\x74\x52\x70\x2e\xe6\x6b\xc8\xb8"

///|
fn play_x28(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_X28_BITS；期望值由
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
    "x28",
  )
  expect_dec_state(dec, "x28", 1073741824L, 366777038L, 2, 16)
}

///|
test "金标：比特分配 · 极端预算 300000" {
  let dec = RangeDecoder::new(ALLOC_X28_BITS)
  play_x28(dec)
}

///|
const ALLOC_X29_BITS : Bytes = b"\xd8\xef\x2c\x0d\x78\x17\x20\x91\xf6\x16\x95\x4c\x96\x10\xf2\xc8\x37\x80\x0a\x2c\xe2\x7f\xf2\x68\x07\x5d\xcd\x27\x5e\x6c\x08\xf1\xc6\x83\xd7\x07\x8c\xdd\xdb\xdc\xc6\x0f\x68\x10\xba\x65\x9c\x5d\x0d\xa2\x95\xcc\x82\x6c\xed\xf6\x07\x6a\x49\xf9\xac\x63\x6a\xd1"

///|
fn play_x29(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_X29_BITS；期望值由
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
    "x29",
  )
  expect_dec_state(dec, "x29", 2147483648L, 327707129L, 1, 8)
}

///|
test "金标：比特分配 · 极端预算 900000" {
  let dec = RangeDecoder::new(ALLOC_X29_BITS)
  play_x29(dec)
}

///|
const ALLOC_X30_BITS : Bytes = b"\x7b\x76\x46\x1f\x33\x8d\xc6\x2d\x5f\xb6\x24\x94\x28\xea\x7d\x40\x93\xaf\x14\x83\x1c\x39\xda\xdf\x20\x92\xd1\xa7\xed\x3d\xe8\x94\x64\xf7\x82\xd9\x0b\x1c\x63\x3d\xdf\xa4\x62\xcc\xba\xcc\xdb\x68\x9c\xe8\xb4\xc2\x3d\x50\x9e\xd8\x80\xe8\x0d\x22\x58\x51\xea\x8c"

///|
fn play_x30(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ALLOC_X30_BITS；期望值由
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
    "x30",
  )
  expect_dec_state(dec, "x30", 2147483648L, 1111809264L, 1, 8)
}

///|
test "金标：比特分配 · 中等预算 50000" {
  let dec = RangeDecoder::new(ALLOC_X30_BITS)
  play_x30(dec)
}
