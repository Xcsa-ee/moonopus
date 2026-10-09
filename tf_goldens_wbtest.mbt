// 由 tools/gen_tf_goldens.py 生成，请勿手改。
//
// TF 调整（§4.3.1）与频谱扩展决策（Table 56）金标：载荷与期望值
// 由本脚本内的独立参考端算出，MoonBit 端重放同一参数后逐项比对。
//
// tf 与 spread 在符号流里紧邻，故在一个用例里连着调，让解码器
// 状态连续推进。

///|

///|
const TF_TF0_BITS : Bytes = b"\x13\xc5\x97\x09\x94\x4e\xf3\x19\xb6\x35\x40\xbb\x14\x60\x5d\xa3\x6c\x43\x9f\x72\x6c\xa5\xfd\x61\x87\x3c\xa3\x91\xd6\xf1\x26\x7d\xd4\x17\x9a\xf3\xfe\x37\x0c\x5e\x42\x70\x7d\x2e\x65\x16\x35\x2b\x84\x61\x4a\xfe\x0d\x99\x7d\x78\xbe\xef\x09\xf0\x4b\xdb\x84\x66"

///|
fn play_tf0(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF0_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, false, 0, 4)
  let got_spread = celt_decode_spread(dec, 4)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    0,
    "tf0",
  )
  expect_dec_state(dec, "tf0", 233390689L, 67532508L, 5, 34)
}

///|
test "金标：TF 与 spread · 基线 4B lm=0 长块" {
  let dec = RangeDecoder::new(TF_TF0_BITS)
  play_tf0(dec)
}

///|
const TF_TF1_BITS : Bytes = b"\x76\x7b\xf5\x39\xbe\x91\x41\x07\x5e\x99\xdd\x06\x35\xd9\x78\xf5\x66\x90\x0a\x32\xaf\x4c\x73\x49\xad\xe3\x0b\xcd\x46\x75\x8f\xd4\xe7\x80\x46\x22\x11\x57\x03\x55\xa2\x46\xfe\xc0\x35\x3f\xa9\xd2\xaa\x05\xe7\x26\x52\xfe\x58\x06\x9d\x80\xb6\xaa\xf0\x84\x5c\x53"

///|
fn play_tf1(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF1_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 0, 4)
  let got_spread = celt_decode_spread(dec, 4)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0],
    2,
    "tf1",
  )
  expect_dec_state(dec, "tf1", 330783075L, 131952594L, 12, 94)
}

///|
test "金标：TF 与 spread · 基线 4B lm=0 短块" {
  let dec = RangeDecoder::new(TF_TF1_BITS)
  play_tf1(dec)
}

///|
const TF_TF2_BITS : Bytes = b"\xad\xed\x90\x84\x97\xbe\xe8\xb3\xaf\x88\x21\x60\x8c\x97\xeb\x8c\x14\x54\xb1\xf5\xed\x00\x4f\xe5\x53\x59\x1e\xe9\x41\xc5\xc6\x73\x85\x5c\x9c\x17\x8c\x11\x82\xc4\xab\x9a\xe8\x7e\xa0\x8b\x23\x6a\x09\xc3\xea\xa9\x78\xbc\xf5\x46\xbf\x47\x3e\x49\xea\xf9\x08\xbb"

///|
fn play_tf2(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF2_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, false, 1, 4)
  let got_spread = celt_decode_spread(dec, 4)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0],
    1,
    "tf2",
  )
  expect_dec_state(dec, "tf2", 8881814L, 7482992L, 17, 136)
}

///|
test "金标：TF 与 spread · 基线 4B lm=1 长块" {
  let dec = RangeDecoder::new(TF_TF2_BITS)
  play_tf2(dec)
}

///|
const TF_TF3_BITS : Bytes = b"\x3c\xb2\x73\x67\xff\x3a\x2c\x0c\xdb\x5d\xd5\x89\x6b\x04\x75\xce\x9e\x7f\xe5\xd9\xb3\x95\x8f\x17\x74\x79\x24\xd6\xe2\x6e\xa4\x65\x17\x53\x34\xc4\xde\x42\x63\xfe\x1d\x4d\xbc\x59\xbd\x2f\xb6\xa9\x6f\x09\xef\xb1\xee\x79\x3c\xc5\xfc\xf1\xf7\xa6\x77\x0e\xbb\x7a"

///|
fn play_tf3(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF3_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 1, 4)
  let got_spread = celt_decode_spread(dec, 4)
  expect_tf(
    got_tf,
    got_spread,
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    2,
    "tf3",
  )
  expect_dec_state(dec, "tf3", 9690912L, 8730774L, 9, 71)
}

///|
test "金标：TF 与 spread · 基线 4B lm=1 短块" {
  let dec = RangeDecoder::new(TF_TF3_BITS)
  play_tf3(dec)
}

///|
const TF_TF4_BITS : Bytes = b"\x15\x76\xf8\x18\x54\xe0\xc5\x2f\x9f\x1d\x7e\x68\x5f\x45\x29\x97\xba\xfa\xc9\x78\x27\x3d\x87\xd0\x0e\x21\xbb\xed\x4a\x1c\xb8\x85\xc9\x96\xba\x62\xa0\x86\xbc\x7e\x77\x84\x79\xe2\x22\x4a\xc7\xe9\xd6\xdd\x37\x50\xd6\x11\x47\xc4\xc0\xfd\xd4\x3e\xf5\x9a\x0a\x57"

///|
fn play_tf4(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF4_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, false, 3, 4)
  let got_spread = celt_decode_spread(dec, 4)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    0,
    "tf4",
  )
  expect_dec_state(dec, "tf4", 233390689L, 53331540L, 5, 34)
}

///|
test "金标：TF 与 spread · 基线 4B lm=3 长块" {
  let dec = RangeDecoder::new(TF_TF4_BITS)
  play_tf4(dec)
}

///|
const TF_TF5_BITS : Bytes = b"\x61\xc7\x1e\xf0\x17\xec\x95\xbc\x90\xd1\x13\xab\x44\x8d\x3f\x5c\xc4\x86\x2f\xa9\xb6\xb0\xbb\x11\xf4\x9b\x90\xe7\xc2\xe0\xde\xec\x38\x1f\xdf\x20\x49\x84\x9e\x03\x9e\x04\xce\xab\x91\x14\xcf\x87\x4d\x3f\xe2\xfb\x27\x76\x46\x8c\xa9\x9a\xc8\x70\x01\xe8\x3b\xcf"

///|
fn play_tf5(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF5_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 3, 4)
  let got_spread = celt_decode_spread(dec, 4)
  expect_tf(
    got_tf,
    got_spread,
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1],
    2,
    "tf5",
  )
  expect_dec_state(dec, "tf5", 9690912L, 300305L, 9, 71)
}

///|
test "金标：TF 与 spread · 基线 4B lm=3 短块" {
  let dec = RangeDecoder::new(TF_TF5_BITS)
  play_tf5(dec)
}

///|
const TF_TF6_BITS : Bytes = b"\x80\xa1\x28\x6e\x71\x6d\x24\xb8\xd1\x40\xb0\xf0\x9e\x82\x72\xed\x99\x4b\xbd\xc3\x4f\xfb\xf3\x0d\x9c\x90\xda\xfe\xa3\x61\x27\x11\x85\x4d\x0d\x93\xa3\x85\x15\xf7\x9e\x97\xec\xa9\xa1\xfd\x8a\xf0\xe5\x12\xd8\x1f\xb5\x1f\xc3\x84\xa3\xca\xfc\xf1\x6a\xd4\x4e\x3c"

///|
fn play_tf6(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF6_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, false, 0, 8)
  let got_spread = celt_decode_spread(dec, 8)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1],
    2,
    "tf6",
  )
  expect_dec_state(dec, "tf6", 22586193L, 20172184L, 8, 61)
}

///|
test "金标：TF 与 spread · 基线 8B lm=0 长块" {
  let dec = RangeDecoder::new(TF_TF6_BITS)
  play_tf6(dec)
}

///|
const TF_TF7_BITS : Bytes = b"\xa2\x4f\xcc\x37\x5f\x90\xcd\x66\x1c\x05\xfe\x2e\x87\x3a\xcc\xa6\x3c\xa3\xed\xa8\x9a\xcf\x36\xae\xc0\x90\x39\x6c\xc8\xb5\x60\xe3\x10\x56\x05\xc3\x7c\xf9\x2f\x4d\xec\x98\xfd\x03\xe7\xa4\x03\x8a\x65\xbb\x52\x86\xca\x5d\x8e\x4b\xb0\x53\x3a\xa7\xf0\xab\x94\x42"

///|
fn play_tf7(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF7_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 0, 8)
  let got_spread = celt_decode_spread(dec, 8)
  expect_tf(
    got_tf,
    got_spread,
    [
      0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0,
      0,
    ],
    2,
    "tf7",
  )
  expect_dec_state(dec, "tf7", 330783075L, 251892482L, 12, 94)
}

///|
test "金标：TF 与 spread · 基线 8B lm=0 短块" {
  let dec = RangeDecoder::new(TF_TF7_BITS)
  play_tf7(dec)
}

///|
const TF_TF8_BITS : Bytes = b"\xd6\x36\x34\x62\x03\xef\xae\x39\xdf\x84\xd3\x1b\xe9\xe4\xdc\xde\x06\xd4\xe2\xcb\x06\x8b\x6c\xba\xe2\x90\x59\xd8\x33\x15\x98\x86\x08\x8c\x9e\x1f\xde\xdf\x01\x77\xb7\xc9\x8f\x5b\x74\xd1\xb3\x8e\xf6\xb7\x6a\x61\xc9\x9c\x71\x49\xa0\x47\xa4\x8e\xcc\x90\x30\xdf"

///|
fn play_tf8(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF8_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, false, 1, 8)
  let got_spread = celt_decode_spread(dec, 8)
  expect_tf(
    got_tf,
    got_spread,
    [
      0, 0, 0, 0, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
      -2,
    ],
    2,
    "tf8",
  )
  expect_dec_state(dec, "tf8", 11293086L, 9563563L, 9, 69)
}

///|
test "金标：TF 与 spread · 基线 8B lm=1 长块" {
  let dec = RangeDecoder::new(TF_TF8_BITS)
  play_tf8(dec)
}

///|
const TF_TF9_BITS : Bytes = b"\x3c\x7d\xbd\x98\x42\x7e\x77\x8b\x8e\x8d\x8e\x33\x12\xe1\x99\x33\x88\xcf\xbe\xf2\x45\xae\xf8\x3f\xb3\xf4\x8d\x08\x90\x2e\xb3\x12\x86\x46\x88\x75\xb1\x16\x24\x99\x8f\x2e\xd1\x09\x80\xfc\x47\x96\x1f\x1f\x17\xc6\xa4\x4e\x6c\x30\x8c\xb6\x03\x10\xdf\x10\xf0\x8d"

///|
fn play_tf9(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF9_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 1, 8)
  let got_spread = celt_decode_spread(dec, 8)
  expect_tf(
    got_tf,
    got_spread,
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0],
    1,
    "tf9",
  )
  expect_dec_state(dec, "tf9", 236273664L, 196369886L, 13, 98)
}

///|
test "金标：TF 与 spread · 基线 8B lm=1 短块" {
  let dec = RangeDecoder::new(TF_TF9_BITS)
  play_tf9(dec)
}

///|
const TF_TF10_BITS : Bytes = b"\xd7\x97\x41\xd5\x86\x42\xec\x48\x31\x43\xdb\x50\x7b\xe0\x44\xe4\x78\xf2\xd6\x83\xbb\x68\x87\xa4\x1b\x77\xab\x73\x33\x62\x53\x79\xd2\x63\x9b\xee\xcc\xce\x51\xe7\x88\xdd\x49\x21\x18\x85\xa3\x43\x5a\x6a\x59\x46\x79\xf9\x4c\x49\xa9\xe6\x44\x4d\x47\xd5\x95\xd2"

///|
fn play_tf10(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF10_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, false, 3, 8)
  let got_spread = celt_decode_spread(dec, 8)
  expect_tf(
    got_tf,
    got_spread,
    [
      0, 0, 0, 0, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3, -3,
      0,
    ],
    2,
    "tf10",
  )
  expect_dec_state(dec, "tf10", 93259068L, 37325476L, 14, 109)
}

///|
test "金标：TF 与 spread · 基线 8B lm=3 长块" {
  let dec = RangeDecoder::new(TF_TF10_BITS)
  play_tf10(dec)
}

///|
const TF_TF11_BITS : Bytes = b"\x99\x50\x27\x5d\xb8\xb9\xd0\xc7\xe6\x7b\xf3\x6b\x2c\x27\x63\x9b\x09\x0d\x33\x76\x17\xc2\x3d\x8a\x4f\xb4\xe6\xaf\x7a\xc0\x3d\x29\xdd\xce\x0f\x92\x9a\x25\xd6\xd1\x8c\x4a\x30\x1d\x5d\xc1\x9e\xf2\xc0\x91\x9d\x9d\xb3\xf0\xff\xa5\x55\x77\x35\xc2\x15\xd6\x43\x2a"

///|
fn play_tf11(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF11_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 3, 8)
  let got_spread = celt_decode_spread(dec, 8)
  expect_tf(
    got_tf,
    got_spread,
    [1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 1, 1, 1, 1, 1],
    0,
    "tf11",
  )
  expect_dec_state(dec, "tf11", 55130547L, 14943887L, 15, 115)
}

///|
test "金标：TF 与 spread · 基线 8B lm=3 短块" {
  let dec = RangeDecoder::new(TF_TF11_BITS)
  play_tf11(dec)
}

///|
const TF_TF12_BITS : Bytes = b"\x72\x36\x0f\x15\x74\xe1\xdf\x50\xcb\xf3\xb8\x41\xc8\xf9\xb3\xb6\x53\x50\x30\x73\xb8\xaf\x67\xe3\x93\x82\x43\xd2\x4d\x79\x86\x66\x0c\x0a\x6a\x39\xac\x11\x2e\xf0\x83\x8f\xcc\xf8\x9b\xa7\x94\x7d\xca\x8e\x46\x65\x8f\xa3\x15\x36\x05\x10\xab\x3f\xf5\xb6\xe5\x43"

///|
fn play_tf12(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF12_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, false, 0, 64)
  let got_spread = celt_decode_spread(dec, 64)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    2,
    "tf12",
  )
  expect_dec_state(dec, "tf12", 700172046L, 42173072L, 3, 21)
}

///|
test "金标：TF 与 spread · 基线 64B lm=0 长块" {
  let dec = RangeDecoder::new(TF_TF12_BITS)
  play_tf12(dec)
}

///|
const TF_TF13_BITS : Bytes = b"\x50\xef\x2d\xe7\x0d\x90\xf3\xa4\xea\xbd\xfe\x36\x1b\xc2\x8f\x2f\xd3\x2b\x86\xba\xb0\x10\xb0\x49\x2b\x46\xe3\xfa\xa3\xea\xaf\xc5\x4d\xc0\x6c\x80\x12\x97\x2a\x58\x21\x4c\x27\x30\x02\x24\x13\x3e\x99\xd8\xd0\xde\x2d\x73\x20\x55\x51\x36\x00\xe1\x86\x13\x1e\x3f"

///|
fn play_tf13(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF13_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 0, 64)
  let got_spread = celt_decode_spread(dec, 64)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1],
    2,
    "tf13",
  )
  expect_dec_state(dec, "tf13", 19381824L, 1275006L, 8, 63)
}

///|
test "金标：TF 与 spread · 基线 64B lm=0 短块" {
  let dec = RangeDecoder::new(TF_TF13_BITS)
  play_tf13(dec)
}

///|
const TF_TF14_BITS : Bytes = b"\x66\x9c\x55\xdd\x71\xf2\xfe\x1e\xfe\x47\xd9\xad\xe5\x41\xde\xbe\xbe\x96\x70\xad\x0c\x8f\xa4\x23\x0c\x22\x86\xc2\x61\x5b\x20\xde\x2f\xcc\x28\x28\xae\x54\x18\x2e\xbf\xa5\x6b\xe9\xe9\x08\xdc\x14\xf2\x42\x64\x1d\xd5\x9e\x3d\x92\x69\x59\x3f\x01\x7f\x3e\xa6\xa7"

///|
fn play_tf14(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF14_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, false, 1, 64)
  let got_spread = celt_decode_spread(dec, 64)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    2,
    "tf14",
  )
  expect_dec_state(dec, "tf14", 700172046L, 139484972L, 3, 21)
}

///|
test "金标：TF 与 spread · 基线 64B lm=1 长块" {
  let dec = RangeDecoder::new(TF_TF14_BITS)
  play_tf14(dec)
}

///|
const TF_TF15_BITS : Bytes = b"\xae\xe3\xe7\xea\x08\x62\x30\x07\x47\x71\x1c\xa4\x35\x4f\x41\x32\xbb\xca\x9e\x74\x94\x5a\x4f\x93\x0b\xc7\xd8\x37\x41\x65\xda\x4f\xb8\xe4\xd4\xa2\x47\x1f\xa0\x30\x89\x3a\x6f\x46\xfe\xf9\x23\x4b\xcb\x2a\xc2\x3e\xe5\x22\x5f\x21\x00\x3b\xa1\x06\x87\xed\xc2\xcf"

///|
fn play_tf15(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF15_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 1, 64)
  let got_spread = celt_decode_spread(dec, 64)
  expect_tf(
    got_tf,
    got_spread,
    [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0],
    2,
    "tf15",
  )
  expect_dec_state(dec, "tf15", 11026092L, 4240926L, 17, 133)
}

///|
test "金标：TF 与 spread · 基线 64B lm=1 短块" {
  let dec = RangeDecoder::new(TF_TF15_BITS)
  play_tf15(dec)
}

///|
const TF_TF16_BITS : Bytes = b"\x50\xf5\x7f\x97\x4b\x80\xdc\x4f\x70\xbe\x1b\x11\x9c\x48\xfd\x5f\x73\xf0\xa2\x89\xa6\x1f\x34\x8d\x44\x5e\x70\x01\xe9\x9b\x6b\x75\xa2\x9a\xea\x62\x49\x68\xac\x5e\x1d\xc0\xf4\x39\xad\x55\x92\x8c\x93\x79\xc4\x3e\x4e\x3a\x52\x54\x6a\xa8\x89\xd8\x2c\x4a\xa3\x30"

///|
fn play_tf16(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF16_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, false, 3, 64)
  let got_spread = celt_decode_spread(dec, 64)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    2,
    "tf16",
  )
  expect_dec_state(dec, "tf16", 700172046L, 321112655L, 3, 21)
}

///|
test "金标：TF 与 spread · 基线 64B lm=3 长块" {
  let dec = RangeDecoder::new(TF_TF16_BITS)
  play_tf16(dec)
}

///|
const TF_TF17_BITS : Bytes = b"\xc0\x9f\xc9\xea\xf5\xef\x39\x73\x07\xc2\xf9\xd8\x9a\xd1\xb3\x9b\x97\x23\xba\x68\xf3\xf4\x04\xf4\x98\x60\xc7\xdf\x62\xd9\x10\xde\x62\x57\x7d\xfa\xca\xaf\x71\xfc\xb2\xff\x53\x76\x04\x8d\x5b\xfc\xc3\x11\x33\x76\x77\x9c\x82\x6c\x26\x7d\xd2\xee\xbe\x38\xfb\x4f"

///|
fn play_tf17(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF17_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 3, 64)
  let got_spread = celt_decode_spread(dec, 64)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    0,
    "tf17",
  )
  expect_dec_state(dec, "tf17", 16151535L, 10915577L, 9, 65)
}

///|
test "金标：TF 与 spread · 基线 64B lm=3 短块" {
  let dec = RangeDecoder::new(TF_TF17_BITS)
  play_tf17(dec)
}

///|
const TF_TF18_BITS : Bytes = b"\x5e\x13\x5d\x62\x5d\x6c\x97\x6f\xac\x9d\x2a\xbf\x07\x8b\xc9\x65\x2c\xbc\xbe\xcb\xe3\x39\xc7\x1d\x4a\x1b\x5d\x25\x6b\x26\x97\x6d\xd4\x46\x9b\x5a\xb6\xfd\xbc\x91\x10\xbe\x40\x86\x61\x45\x2f\x42\x35\x4e\xaa\xad\xf4\x05\x11\xdd\x38\x5a\xae\x51\xdc\x37\x68\x23"

///|
fn play_tf18(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF18_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 5, 17, false, 3, 64)
  let got_spread = celt_decode_spread(dec, 64)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    2,
    "tf18",
  )
  expect_dec_state(dec, "tf18", 931749840L, 541907512L, 3, 18)
}

///|
test "金标：TF 与 spread · 带窗 5..17" {
  let dec = RangeDecoder::new(TF_TF18_BITS)
  play_tf18(dec)
}

///|
const TF_TF19_BITS : Bytes = b"\xc5\x6b\xfb\x1e\x2d\x87\x17\x87\xd5\x20\xf3\x2c\xc1\x71\x29\xde\xa8\x14\xba\x3d\xb9\xf1\xf8\x34\x6a\x55\xed\x5d\xea\xc1\x11\x73\x0f\xf8\xf6\x35\x18\xb5\x1a\xf9\x9a\xe7\x79\x15\xac\x02\x48\x48\xb9\x4d\x07\xfb\x01\x0d\xcb\x41\x33\x32\xa5\x4a\xc8\x20\xf3\x73"

///|
fn play_tf19(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF19_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 5, 17, true, 2, 16)
  let got_spread = celt_decode_spread(dec, 16)
  expect_tf(
    got_tf,
    got_spread,
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    2,
    "tf19",
  )
  expect_dec_state(dec, "tf19", 86615025L, 78254391L, 6, 46)
}

///|
test "金标：TF 与 spread · 带窗 5..17 短块" {
  let dec = RangeDecoder::new(TF_TF19_BITS)
  play_tf19(dec)
}

///|
const TF_TF20_BITS : Bytes = b"\xf1\xf2\x61\xf3\xe7\x8f\x4e\x30\x9a\xc3\x48\xf5\x4a\x3f\x22\x71\x5f\xfc\xa0\xdd\xc5\x1e\xb8\x06\x24\x3c\xea\xc7\x77\x35\x3a\x8e\x00\x53\xc7\xfc\xe8\x44\x32\xcc\x2b\x2e\x5a\xa7\x03\x26\x7b\x02\x87\xb0\x5e\x4a\x02\x09\xc1\x36\x3d\xd4\x0f\x04\xa4\x56\xb8\xee"

///|
fn play_tf20(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF20_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, false, 3, 2)
  let got_spread = celt_decode_spread(dec, 2)
  expect_tf(
    got_tf,
    got_spread,
    [
      -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2,
      -2, -2,
    ],
    2,
    "tf20",
  )
  expect_dec_state(dec, "tf20", 23339064L, 17010528L, 8, 61)
}

///|
test "金标：TF 与 spread · 极小帧 2B" {
  let dec = RangeDecoder::new(TF_TF20_BITS)
  play_tf20(dec)
}

///|
const TF_TF21_BITS : Bytes = b"\x9a\x60\x59\x4d\xf7\x68\x8f\x0d\x67\x08\x07\x6b\x01\x67\xbc\xd3\x12\xf7\x34\x8b\x6b\x6b\xc8\x83\x94\xaf\x91\x3b\xc9\x0e\xda\x30\x03\x88\x64\xbe\x84\xa3\x61\x1b\xa3\x3e\x4a\x9a\xd7\x68\xde\x06\x46\x66\xc0\xfa\xcc\x84\xe2\xf4\x34\xe3\xbe\x55\x7b\x3e\x0f\xd6"

///|
fn play_tf21(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TF21_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 3, 3)
  let got_spread = celt_decode_spread(dec, 3)
  expect_tf(
    got_tf,
    got_spread,
    [1, 1, 1, 1, -1, -1, -1, -1, -1, -1, -1, -1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    2,
    "tf21",
  )
  expect_dec_state(dec, "tf21", 165391590L, 143085805L, 13, 102)
}

///|
test "金标：TF 与 spread · 极小帧 2B 短块" {
  let dec = RangeDecoder::new(TF_TF21_BITS)
  play_tf21(dec)
}

///|
const TF_TU12047_BITS : Bytes = b"\x9d\xe5\xcd\xdd\xcc\xb5\xac\x4a\x15\x93\x76\xca\x89\x7f\x2b\xcc\x9a\xa6\x62\x8b\x07\x0d\x93\xd4\xc5\xb0\xab\x68\x60\x6a\xe1\xae\x4c\x2f\x6f\x3f\xba\xeb\xd6\x53\xa5\x04\x3b\x48\x7b\xac\xbe\xb4\x39\x6c\xf8\x0c\xb6\x66\x19\x2a\x6d\xea\xe9\xb2\xaa\x1f\x4a\xcd"

///|
fn play_tu12047(dec : RangeDecoder) -> Unit raise {
  // 载荷见 TF_TU12047_BITS；期望值由
  // tools/gen_tf_goldens.py 的独立参考端算出。
  let got_tf = celt_decode_tf(dec, 0, 21, true, 3, 2)
  let got_spread = celt_decode_spread(dec, 2)
  expect_tf(
    got_tf,
    got_spread,
    [3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0],
    2,
    "tu12047",
  )
  expect_dec_state(dec, "tu12047", 21750425L, 3113373L, 16, 126)
}

///|
test "金标：TF 与 spread · 覆盖搜索 12047" {
  let dec = RangeDecoder::new(TF_TU12047_BITS)
  play_tu12047(dec)
}
