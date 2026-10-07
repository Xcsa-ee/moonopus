// 由 tools/gen_pvq_goldens.py 生成，请勿手改。
//
// PVQ 脉冲解码（RFC 6716 §4.3.4.2）金标：载荷与期望向量由本脚本
// 内的独立参考端算出（V 用带缓存的递归，与实现端的动态规划不同
// 法），MoonBit 端重放后逐项比对。
//
// 用例按码字总数 V(N,K) 的区间挑选，覆盖 Int32 之内、之外以及
// 超出 §4.3.4.4 的 32 bits 上限三种情况。

///|

///|
const PVQ_P0_BITS : Bytes = b"\x92\xb1\x5d\xf1\x82\xba\x6f\xf5\x87\x3b\x90\x18\x34\x64\x1b\xa6\xcb\x9e\x86\xb9\xac\x74\xd8\xf1\xf8\x03\x91\x47\xec\x33\xaf\x16\x18\x28\xc8\xbc\x8e\xf0\xd6\xf0\x29\xc9\xa9\x46\xcd\xda\xa6\xca\x51\xc6\xbe\x15\xdd\x98\x8f\x74\xf7\x01\xf6\x99\x84\x6c\x7a\xba"

///|
fn play_p0(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P0_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 1, 1)
  expect_pulses(got, [-1], "p0")
  expect_dec_state(dec, "p0", 1073741824L, 916934919L, 2, 16)
}

///|
test "金标：PVQ 脉冲 · 小码本 V=2 (N=1,K=1)" {
  let dec = RangeDecoder::new(PVQ_P0_BITS)
  play_p0(dec)
}

///|
const PVQ_P1_BITS : Bytes = b"\x0d\x83\x70\xd7\xeb\x4e\x45\x15\xc0\x02\xa2\x63\x20\x86\x50\x1a\xd8\x16\x8f\x1f\xa7\x43\xc2\x67\x8c\x09\x7f\xab\x96\xc2\x82\xec\x82\x55\x42\xa9\x88\x84\x5f\xcc\xfe\x21\x7f\xab\x8f\x4f\x5e\x95\x8c\xe0\x1f\x8c\xde\x9f\xa1\xb9\x94\xdb\x37\xef\x99\x06\x26\x6f"

///|
fn play_p1(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P1_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 8, 33)
  expect_pulses(got, [9, 1, 1, 5, -8, -1, -8, 0], "p1")
  expect_dec_state(dec, "p1", 16146493L, 15813067L, 33, 257)
}

///|
test "金标：PVQ 脉冲 · 越过 Int32 的码本 V=2220686864 (N=8,K=33)" {
  let dec = RangeDecoder::new(PVQ_P1_BITS)
  play_p1(dec)
}

///|
const PVQ_P2_BITS : Bytes = b"\x4c\x77\xf7\xed\x8f\x23\x17\x9d\x02\xa5\x05\x02\xb5\xf9\xb9\x25\x0a\xa4\x74\xfa\x51\x28\xdd\x3c\x0b\xba\x0b\xe9\x24\xc5\x59\xa2\xc2\x3a\x96\xe0\x16\x27\xd5\xa7\xe8\x52\x52\x53\xb4\x06\x67\x25\x41\xa0\x6e\x73\x0c\x92\xdb\xa5\x1c\xf1\x12\xa3\x9d\x8f\x38\x96"

///|
fn play_p2(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P2_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 8, 37)
  expect_pulses(got, [3, -2, 8, -2, -1, 17, 1, 3], "p2")
  expect_dec_state(dec, "p2", 14608732L, 1318917L, 34, 266)
}

///|
test "金标：PVQ 脉冲 · 超出 32 bits 上限 V=4920955600 (N=8,K=37)" {
  let dec = RangeDecoder::new(PVQ_P2_BITS)
  play_p2(dec)
}

///|
const PVQ_P3_BITS : Bytes = b"\xc6\x33\xac\xf8\x08\x65\x67\x34\x52\x56\x78\x51\x67\x49\xc7\xce\x44\x06\x32\x6d\xd6\x51\x18\xe2\xf3\x06\x9d\x7b\x93\x10\xe0\xbc\x3f\x7a\x63\x4b\x25\xa1\xcd\x1d\x11\x32\x9f\x34\xf9\x37\xbf\x4c\x5c\x50\x49\xe2\x9e\xf1\x71\x49\xad\x7b\xfc\x7f\x70\xee\x46\xe5"

///|
fn play_p3(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P3_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 1, 1)
  expect_pulses(got, [-1], "p3")
  expect_dec_state(dec, "p3", 1073741824L, 484845955L, 2, 16)
}

///|
test "金标：PVQ 脉冲 · N=1 K=1 V=2" {
  let dec = RangeDecoder::new(PVQ_P3_BITS)
  play_p3(dec)
}

///|
const PVQ_P4_BITS : Bytes = b"\xe8\xe1\x8a\xce\x3f\x84\x26\x82\x42\xd5\x92\xfc\xda\x97\xca\x66\x12\xcc\xa5\x76\x92\x2f\x1d\x80\x98\xff\xe0\xe0\xb6\x14\xa4\xc4\xcf\x40\xd0\x2c\xf1\x4b\x1d\x64\x77\xad\xea\x2f\xa7\x20\xe4\x4f\x3e\x99\x9b\x9f\x30\x67\xd7\x94\xba\x94\xe7\x45\x12\x63\xee\x48"

///|
fn play_p4(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P4_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 8, 0)
  expect_pulses(got, [0, 0, 0, 0, 0, 0, 0, 0], "p4")
  expect_dec_state(dec, "p4", 2147483648L, 193936024L, 1, 8)
}

///|
test "金标：PVQ 脉冲 · N=8 K=0 V=1" {
  let dec = RangeDecoder::new(PVQ_P4_BITS)
  play_p4(dec)
}

///|
const PVQ_P5_BITS : Bytes = b"\xbe\x5e\x76\x7f\x52\x82\x21\xa9\x30\x50\xe8\x00\x9c\x81\x39\x6f\x1e\x6b\x1e\x8c\x6a\xf0\x0b\x84\x05\x1d\x9a\x70\x1c\xef\x31\x34\xe0\x3f\x43\xe1\x4b\x72\x63\x2e\x8d\x58\x64\x35\xe7\xf0\x27\x9d\x4a\x5a\x30\x42\xfb\x80\x5e\x87\x94\x17\xa2\x7f\xe4\x5f\xfa\x04"

///|
fn play_p5(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P5_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 8, 3)
  expect_pulses(got, [0, -1, 1, 0, 0, 0, 0, 1], "p5")
  expect_dec_state(dec, "p5", 12485370L, 1196488L, 11, 84)
}

///|
test "金标：PVQ 脉冲 · N=8 K=3 V=688" {
  let dec = RangeDecoder::new(PVQ_P5_BITS)
  play_p5(dec)
}

///|
const PVQ_P6_BITS : Bytes = b"\x52\x0d\xd8\xb6\x7d\xa5\x4c\x37\xc2\x91\xdb\x96\x17\xcc\x23\x29\xd0\x61\xa8\x91\x2a\x12\x0b\x0e\x1f\x3a\xa4\x2c\x94\x60\x06\x9e\xe0\xcd\x5b\x3a\xb0\xfa\x01\x4f\x5a\xcf\x06\xba\x5d\x64\x6e\xd4\x17\xd6\x65\xb7\xa0\x42\x1d\xfe\x59\x80\x61\x37\x01\x00\x18\xb3"

///|
fn play_p6(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P6_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 12, 6)
  expect_pulses(got, [0, 1, -1, 0, 0, 1, 0, -1, 0, -1, 1, 0], "p6")
  expect_dec_state(dec, "p6", 15449522L, 6909000L, 20, 153)
}

///|
test "金标：PVQ 脉冲 · N=12 K=6 V=284000" {
  let dec = RangeDecoder::new(PVQ_P6_BITS)
  play_p6(dec)
}

///|
const PVQ_P7_BITS : Bytes = b"\x09\x7a\x7c\x49\x0f\xb4\x23\x17\xc0\x35\x7f\x5b\x86\xbb\xbd\xe4\xa7\x59\x23\x9a\xa1\x42\x77\x6e\xb6\xc0\x08\xd5\x8b\x78\xd6\x0c\x36\x78\x6e\x6a\x86\x4b\xfe\xda\x65\x0a\x97\xe3\x41\x8b\xd9\xec\x7a\x39\xee\xff\x55\x9d\x3e\x07\xcd\x52\x0f\x3b\x1b\x27\xaf\xc9"

///|
fn play_p7(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P7_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 48, 4)
  expect_pulses(
    got,
    [
      0, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    ],
    "p7",
  )
  expect_dec_state(dec, "p7", 9896238L, 9555067L, 23, 183)
}

///|
test "金标：PVQ 脉冲 · N=48 K=4 V=3542016" {
  let dec = RangeDecoder::new(PVQ_P7_BITS)
  play_p7(dec)
}

///|
const PVQ_P8_BITS : Bytes = b"\xe0\x14\xf4\x07\x13\x84\x2b\xad\xa9\xd5\xa8\x2c\xdf\xca\xc3\x47\xff\xbf\x15\xb8\xf8\x98\xad\x6b\xc8\x44\x17\x8d\xeb\xe6\xa0\xb1\x32\x65\x51\x35\x33\x67\xfb\x38\x1f\xac\xab\x79\xfc\x5d\x29\xa0\xa2\x84\x8d\x79\x78\xc5\xf2\x1b\xad\x38\x8a\x87\xd3\xa3\xb9\x2e"

///|
fn play_p8(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P8_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 176, 2)
  expect_pulses(
    got,
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0,
    ],
    "p8",
  )
  expect_dec_state(dec, "p8", 8873899L, 1531890L, 17, 136)
}

///|
test "金标：PVQ 脉冲 · N=176 K=2 V=61952" {
  let dec = RangeDecoder::new(PVQ_P8_BITS)
  play_p8(dec)
}

///|
const PVQ_P9_BITS : Bytes = b"\x02\x7f\x8b\x4c\x2b\xa8\xa8\x2b\xfc\x99\x7b\xe3\x06\xb7\x5a\xf5\x2c\x6c\x29\xf1\x6a\xc1\x9a\x8e\x82\xc1\xf9\xcf\xde\x31\x6f\x23\xe4\x5b\x2b\x03\xc4\x4f\xd1\x5e\xb5\x69\x3e\x96\x56\xd9\xb5\x79\xdb\x38\xd5\x0c\x3f\xa9\x63\x96\x28\x3f\x3a\xfc\x85\xc6\xe4\x4d"

///|
fn play_p9(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P9_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 176, 5)
  expect_pulses(
    got,
    [
      1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0,
    ],
    "p9",
  )
  expect_dec_state(dec, "p9", 12782640L, 4608825L, 37, 292)
}

///|
test "金标：PVQ 脉冲 · N=176 K=5 V=45040392672" {
  let dec = RangeDecoder::new(PVQ_P9_BITS)
  play_p9(dec)
}

///|
const PVQ_P10_BITS : Bytes = b"\xf4\x14\xa1\x61\xac\x1a\x09\x08\x18\x11\xdd\x31\xd2\x8a\x41\xaa\x94\x02\x49\xf0\x36\x93\xc7\x17\xe3\xbe\x6a\x06\x01\x69\xa3\x3d\x1c\x05\x3e\xb0\x8e\x61\x72\x93\x18\x29\xf9\xaa\xe0\x30\x1c\x10\x4e\x82\xa9\xfb\xea\xca\x1f\x72\xed\x74\x56\x6b\x78\x3f\xcf\xe0"

///|
fn play_p10(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P10_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 176, 0)
  expect_pulses(
    got,
    [
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0,
    ],
    "p10",
  )
  expect_dec_state(dec, "p10", 2147483648L, 99987279L, 1, 8)
}

///|
test "金标：PVQ 脉冲 · N=176 K=0 V=1" {
  let dec = RangeDecoder::new(PVQ_P10_BITS)
  play_p10(dec)
}

///|
const PVQ_P11_BITS : Bytes = b"\x35\xb4\x89\x17\x94\x42\x86\x5b\x59\xd8\x7a\x01\xc7\x3d\xd1\xd8\xb7\xa3\x27\x34\x3a\x4d\x7f\x7c\x52\x9e\x00\x85\x5c\x5f\x84\xc1\x67\x30\x6c\xba\x5a\xb7\x5f\xd8\x20\x39\x2b\xf7\x24\x7e\x92\x52\x4e\x7e\x4f\xa1\x3e\xb4\xb3\xa9\x00\x9f\x4d\x42\x63\x15\xd0\x03"

///|
fn play_p11(dec : RangeDecoder) -> Unit raise {
  // 载荷见 PVQ_P11_BITS；期望值由
  // tools/gen_pvq_goldens.py 的独立参考端算出。
  let got = celt_decode_pulses(dec, 20, 8)
  expect_pulses(
    got,
    [0, 1, 0, 1, -1, 0, 0, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, -1, -2, 0],
    "p11",
  )
  expect_dec_state(dec, "p11", 12859183L, 12418663L, 29, 228)
}

///|
test "金标：PVQ 脉冲 · N=20 K=8 V=174074240" {
  let dec = RangeDecoder::new(PVQ_P11_BITS)
  play_p11(dec)
}
