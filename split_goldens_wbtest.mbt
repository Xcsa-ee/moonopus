// 由 tools/gen_split_goldens.py 生成，请勿手改。
//
// split 解码（RFC 6716 §4.3.4.4）金标：载荷与期望值由本脚本内的
// 独立 Python 参考端算出（θ 的三种 PDF、递归分割、位数划分与叶上
// 预算循环），MoonBit 端重放同一载荷后逐项比对控制量、脉冲向量
// 与范围解码器状态。

///|

///|
const SPLIT_TH0_BITS : Bytes = b"\xe0\xdb\xa3\xd1\x22\xf3\x08\x8a\x0d\x46\xf3\x27\x24\x5b\x84\xaa\x77\xa6\x59\x4d\x27\xe3\x0c\xb7\x7c\xa3\x12\xf0\xa1\xab\xd6\x02\xd5\xf6\xaa\x4d\x98\x6d\x4f\xb0\x05\x92\x5e\x3c\x8c\x44\x04\xf7\x62\xbc\x23\x1c\x11\xeb\x21\x87\xd3\x09\x29\x72\x89\xca\x17\xf8"

///|
fn play_split_th0(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH0_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 6, 120, 1, 1, false, 21, 4000, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 12540, 30274, 51, 12288, 18, 4, 102, 15],
    before,
    "th0",
  )
  expect_dec_state(dec, "th0", 477218588L, 22629001L, 4, 26)
}

///|
test "金标：theta · 三角 PDF 长块单声道" {
  let dec = RangeDecoder::new(SPLIT_TH0_BITS)
  play_split_th0(dec)
}

///|
const SPLIT_TH1_BITS : Bytes = b"\xad\x4b\x53\xf8\xe4\x17\x4f\x9f\x6f\x02\x54\x01\xa3\xf4\x46\xcc\xc8\xd9\x23\xea\xb6\x34\x1c\xe5\x23\x2b\xe5\xba\xa9\x42\x9f\xd0\x18\xed\x80\xef\xec\x92\xd4\x98\x1d\x6a\x3c\x6b\xe7\x64\xf3\xc1\x01\xd3\x2b\x89\xc7\x65\x71\xdd\x0f\x39\x1e\xdd\xba\xab\x47\x44"

///|
fn play_split_th1(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH1_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 6, 120, 2, 2, false, 21, 4000, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 12540, 30274, 51, 12288, 19, 4, 101, 15],
    before,
    "th1",
  )
  expect_dec_state(dec, "th1", 429496729L, 264289386L, 4, 27)
}

///|
test "金标：theta · 均匀 PDF B0>1" {
  let dec = RangeDecoder::new(SPLIT_TH1_BITS)
  play_split_th1(dec)
}

///|
const SPLIT_TH2_BITS : Bytes = b"\x48\x25\x5f\xae\xfb\x6c\x5e\x6d\xc2\x52\x0a\x52\xe4\xd1\x7d\x9e\xa8\x17\xdc\xe3\x81\x5e\xc1\x34\xd8\x1c\xbf\x13\xd9\xee\xb9\x9b\xd8\xc2\x65\xbe\xc7\xae\x2a\xe1\x2b\x41\x9d\xe5\x71\xce\x09\xe6\x5b\x62\xb9\x6a\xda\xe2\xe6\xcb\xd4\x6c\x6c\x02\xdc\x07\x3d\x80"

///|
fn play_split_th2(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH2_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 6, 120, 1, 1, true, 21, 4000, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 30274, 12540, -51, 4096, 15, 4, 105, 15],
    before,
    "th2",
  )
  expect_dec_state(dec, "th2", 585677358L, 566150278L, 3, 23)
}

///|
test "金标：theta · 阶梯 PDF 立体声 N>2" {
  let dec = RangeDecoder::new(SPLIT_TH2_BITS)
  play_split_th2(dec)
}

///|
const SPLIT_TH3_BITS : Bytes = b"\xf8\xf6\xf9\x8e\x7b\x6d\x1e\xe8\xb4\xc7\xf0\x4b\x7b\x63\x7a\xe4\xb6\xa3\x7e\x11\x8d\x30\xcb\x98\xab\xcc\xd4\x30\xcb\x44\x1f\xb4\xb8\x19\xb6\xef\xd9\x49\xb9\xc3\x44\xb3\xa4\xc2\x3f\x19\x53\x49\x9a\x2d\x56\xdb\xe0\xca\x73\xd0\xf9\xcc\x51\x7c\x6c\xe1\x5b\x6a"

///|
fn play_split_th3(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH3_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 2, 120, 1, 1, true, 21, 4000, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 956, 32754, 41, 16080, 55, 108, 65, 15],
    before,
    "th3",
  )
  expect_dec_state(dec, "th3", 19701684L, 19612624L, 8, 63)
}

///|
test "金标：theta · 两相偏移 立体声 N==2" {
  let dec = RangeDecoder::new(SPLIT_TH3_BITS)
  play_split_th3(dec)
}

///|
const SPLIT_TH4_BITS : Bytes = b"\x81\xa4\x16\xdd\xce\x92\x14\x95\xbb\x67\x8d\x63\xa9\x4e\x2c\x8c"

///|
fn play_split_th4(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH4_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 6, 10, 1, 1, false, 21, 4000, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 32767, 0, -16384, 0, 0, 1, 10, 1],
    before,
    "th4",
  )
  expect_dec_state(dec, "th4", 2147483648L, 1059976337L, 1, 8)
}

///|
test "金标：theta · qn=1 单声道" {
  let dec = RangeDecoder::new(SPLIT_TH4_BITS)
  play_split_th4(dec)
}

///|
const SPLIT_TH5_BITS : Bytes = b"\x66\x9c\x95\xfe\x13\x6b\x68\xb7\xcc\x47\xaa\xe2\xa9\xec\x92\xe3"

///|
fn play_split_th5(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH5_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 6, 20, 1, 1, true, 21, 400, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 32767, 0, -16384, 0, 4, 1, 16, 1],
    before,
    "th5",
  )
  expect_dec_state(dec, "th5", 1610612736L, 749843712L, 2, 12)
}

///|
test "金标：theta · qn=1 立体声 inv 读取" {
  let dec = RangeDecoder::new(SPLIT_TH5_BITS)
  play_split_th5(dec)
}

///|
const SPLIT_TH6_BITS : Bytes = b"\x56\x36\x1a\x98\xa7\x82\xc4\xc6\xa1\xe4\x62\x4f\xf6\xa0\xd2\x0b"

///|
fn play_split_th6(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH6_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 6, 10, 1, 1, true, 21, 400, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 32767, 0, -16384, 0, 0, 1, 10, 1],
    before,
    "th6",
  )
  expect_dec_state(dec, "th6", 2147483648L, 1424290483L, 1, 8)
}

///|
test "金标：theta · qn=1 立体声 inv 预算不足" {
  let dec = RangeDecoder::new(SPLIT_TH6_BITS)
  play_split_th6(dec)
}

///|
const SPLIT_TH7_BITS : Bytes = b"\x15\x2f\xf5\x6d\x0c\xbd\xfa\x44\xb1\x39\x32\x22\x0f\x1b\x9c\xd6\x6b\x16\x13\x58\xd3\xcf\x3c\x22\x52\xc1\x5a\xe1\x65\x77\x83\x12\x3b\x38\xa3\x08\x53\x16\xf7\xbf\x5c\xe0\x0d\x9d\x11\x8e\x19\x83\xc6\x61\x37\x3c\x0a\x09\x81\x28\x01\x29\x38\x54\xd2\x3d\x91\x56"

///|
fn play_split_th7(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH7_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 6, 300, 1, 1, true, 15, 4000, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 32767, 0, -16384, 0, 4, 1, 296, 1],
    before,
    "th7",
  )
  expect_dec_state(dec, "th7", 1610612736L, 1432880457L, 2, 12)
}

///|
test "金标：theta · intensity 强制 qn=1" {
  let dec = RangeDecoder::new(SPLIT_TH7_BITS)
  play_split_th7(dec)
}

///|
const SPLIT_TH8_BITS : Bytes = b"\x27\x37\x6e\xa1\x2e\x99\x75\x7c\x66\x4b\xa3\xd9\xad\xc5\xc1\x86"

///|
fn play_split_th8(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH8_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 6, 20, 1, 1, true, 21, 400, true, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 32767, 0, -16384, 0, 4, 1, 16, 1],
    before,
    "th8",
  )
  expect_dec_state(dec, "th8", 1610612736L, 1281640623L, 2, 12)
}

///|
test "金标：theta · disable_inv 覆盖 inv" {
  let dec = RangeDecoder::new(SPLIT_TH8_BITS)
  play_split_th8(dec)
}

///|
const SPLIT_TH9_BITS : Bytes = b"\x53\x24\x28\xe0\xce\xff\x18\x00\x8f\x47\xad\x6e\x53\xcf\xab\xc6\x9c\xab\x76\x2a\xf7\x4b\xaf\xdf\x90\x3d\x93\xcf\x73\xb2\x52\x2f\x33\x3c\x6f\x64\x44\xb0\x10\x6d\xcd\x13\xb9\xd2\x4b\x8f\x30\x53\xc0\x0b\x1f\x3d\xf5\xad\x27\x14\xc7\x9b\x68\xb6\x46\x9b\x8e\x5e\xf1\x3e\x8d\x44\xdc\x43\xd7\x8c\xec\x50\x79\xbf\xc2\x0d\xf7\x02\xc2\xda\x06\xfb\xd3\x82\x7d\x16\x0b\x39\x5e\xb6\xdb\xa6\x7b\xe0\x34\x17\x3b\xd1\x5f\x65\x10\xf7\x7a\x2a\x27\x59\x79\x8b\xdd\x4b\x27\x11\x2f\x81\xf5\x55\x8e\xe7\x5a\x32\xb6\x24\xd9\x7d\x49\x17"

///|
fn play_split_th9(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH9_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 3, 48, 400, 1, 1, false, 21, 8000, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 28379, 16384, -295, 5461, 20, 6, 380, 15],
    before,
    "th9",
  )
  expect_dec_state(dec, "th9", 402653184L, 107867023L, 4, 28)
}

///|
test "金标：theta · lm=3 三角" {
  let dec = RangeDecoder::new(SPLIT_TH9_BITS)
  play_split_th9(dec)
}

///|
const SPLIT_TH10_BITS : Bytes = b"\x37\x0f\xd4\xea\x52\x2c\x20\x1d\x4a\xee\xc5\xff\x9d\xb1\x30\x06\xb2\xaa\xbc\xfc\x91\xb2\x9b\xba\x1d\xbe\x29\xf3\x4c\x62\xcd\xc7\xea\x05\x56\xb2\x42\x25\x0e\xa9\xae\x41\x2c\x80\x36\xca\x1d\xc5\x2c\xf4\x33\xfc\x31\x30\x32\x3b\x7d\x15\x9d\x68\x1b\xdd\x29\xea\x88\x6f\x90\xc8\x27\xa1\x38\x73\xee\x14\x38\x9b\x92\xe8\xbb\x6d\xbc\xb1\xa1\xf6\x07\x3f\x92\x5a\x6e\x88\x60\x69\x1e\xf4\x03\xb6\xab\xa7\xa7\x55\xa0\xca\x81\x0c\xc2\x37\x68\x12\xc5\x40\x2e\xc9\x79\x5b\x14\x50\x25\x4c\xda\x36\x24\xff\x6c\x1b\xb6\x8e\x2f\x2e"

///|
fn play_split_th10(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH10_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 6, 100000, 1, 1, false, 21, 80000, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 28511, 16151, -33, 5376, 61, 256, 99939, 15],
    before,
    "th10",
  )
  expect_dec_state(dec, "th10", 10968995L, 9787092L, 9, 69)
}

///|
test "金标：theta · 大 b 触 qn 上限" {
  let dec = RangeDecoder::new(SPLIT_TH10_BITS)
  play_split_th10(dec)
}

///|
const SPLIT_TH11_BITS : Bytes = b"\xf1\xfc\x98\xc6\xf1\xed\xf4\x4d\x64\x71\xc0\xf9\x72\x29\x2a\xb3"

///|
fn play_split_th11(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH11_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 0, 0, 1, 8, 1, 1, false, 21, 400, false, 1,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 32767, 0, -16384, 0, 0, 1, 8, 1],
    before,
    "th11",
  )
  expect_dec_state(dec, "th11", 2147483648L, 117552028L, 1, 8)
}

///|
test "金标：theta · N==1 带" {
  let dec = RangeDecoder::new(SPLIT_TH11_BITS)
  play_split_th11(dec)
}

///|
const SPLIT_TH12_BITS : Bytes = b"\xbe\x96\xd1\x03\xea\x89\x29\x5d\x69\x20\x5d\xc1\x5d\xf9\x45\x83"

///|
fn play_split_th12(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_TH12_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let before = dec.tell_frac()
  let (sctx, b_after, fill_after) = celt_compute_theta(
    dec, 15, 0, 6, 54, 1, 1, false, 21, 4000, false, 15,
  )
  expect_theta(
    dec,
    sctx,
    b_after,
    fill_after,
    [0, 32767, 0, -16384, 0, 0, 1, 54, 1],
    before,
    "th12",
  )
  expect_dec_state(dec, "th12", 2147483648L, 548706174L, 1, 8)
}

///|
test "金标：theta · qb∈[1,3] 的 qn=1 边界" {
  let dec = RangeDecoder::new(SPLIT_TH12_BITS)
  play_split_th12(dec)
}

///|
const SPLIT_PT0_BITS : Bytes = b"\x17\xde\x46\x68\xf6\x95\xb7\xaa\xad\x5a\x09\x03\xad\xf7\x5f\xb0\x3c\x90\xe4\x06\xc3\x8e\x45\x65\xa6\x9d\x8b\xe8\x29\xc3\x88\x9b\x50\x93\x85\x1e\x3e\xc8\x6c\xe5\xab\xed\xf3\xaa\x85\x15\x6e\xfc\x36\xec\x1f\x86\x4b\x8b\xc5\x38\x7d\xd8\x68\xec\x7e\x63\x00\xcc"

///|
fn play_split_pt0(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT0_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 15, 0, 6, 40, 1, 15, 4000)
  expect_partition(
    got,
    15,
    4000,
    [],
    [6, 1, 0, 40, 2, 50, 15, 6, 1, 0, 0, 0, 0, -1],
    3950,
    "pt0",
  )
  expect_dec_state(dec, "pt0", 29826161L, 8561690L, 8, 58)
}

///|
test "金标：split · 无分割 落叶" {
  let dec = RangeDecoder::new(SPLIT_PT0_BITS)
  play_split_pt0(dec)
}

///|
const SPLIT_PT1_BITS : Bytes = b"\x6a\x2b\x99\xa8\x60\xe3\x7a\x10\xdb\xc6\x66\x92\xdb\x2b\x49\xfc"

///|
fn play_split_pt1(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT1_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 15, 0, 6, 8, 1, 15, 4000)
  expect_partition(got, 15, 4000, [], [6, 1, 0, 8, 0, 0, 15, 0], 4000, "pt1")
  expect_dec_state(dec, "pt1", 2147483648L, 1256862507L, 1, 8)
}

///|
test "金标：split · 零脉冲叶" {
  let dec = RangeDecoder::new(SPLIT_PT1_BITS)
  play_split_pt1(dec)
}

///|
const SPLIT_PT2_BITS : Bytes = b"\xd4\xc4\xeb\x0d\xe2\x69\xd8\xf8\xde\xb1\x32\xa8\x2e\xd5\xb2\xde\xa9\x76\x6a\xaa\x78\xdb\x85\xa7\x56\xaf\x17\xfa\xe1\x67\xc4\xec\xb5\x76\xe6\x97\x5a\x63\x28\xdc\x9e\xe0\x73\x1d\x72\x4a\x55\x0a\xd9\x22\xf6\xd2\xa4\x71\xdb\x66\xd5\xff\x05\xed\x74\x1c\x8d\x90\xb8\x5b\xd0\xc5\xf4\x1a\x80\x28\x3b\xea\x79\x6d\x80\xa2\x5c\xe7\x3a\x26\xee\x83\x45\x52\x06\x84\xd4\xe4\x63\xa9\x53\xe1\xae\x5c\xb3\x88\x6d\x11\x25\x05\x68\x10\x3c\xf9\x98\x92\x25\xf4\x5d\x95\x14\xef\xb6\xf2\x60\x4f\x6a\x26\x72\x51\x07\x3d\x75\x3b\x7b\xc9\xa5\x87\xb7\x56\x05\x53\x60\x32\xb7\xa4\x9d\x96\xea\xfa\x8e\xd2\x59\x76\x41\x92\x80\xa1\xd7\x3c\x2b\x21\xef\xda\xd1\x73\x38\xc1\xd7\x37\x23\xc0\x92\x88\xd6\x6e\x29\xff\xc7\x30\x50\xe9\xbd\xeb\x11\x08\xb7\x39\xbe\xcb\xf7\x6b\xcc\xb4\x6e\x54\x3a\x0b\xbc\x13\xe1\xed\xd3\x6d\x32\xbd\x8a\x9f\xe7\x7e\xf9\xc5\x49\xbc\xe8\x7f\xc9\x1b\x76\xe3\x0d\xf4\x3f\xe1\x72\x5c\xec\xa8\x0a\xe9\xc8\x55\xde\xfe\x9d\x94\xe0\xfc\xdc\xa0\xc8\x89\x3a\xfe\x46\xb0\xc1\xb2\x24\x06\xba\xec\x51\x46\x0f\xed\x9c\x68\x13\xcc\xda\x44\x27\x8e"

///|
fn play_split_pt2(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT2_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 15, 3, 12, 400, 1, 15, 8000)
  expect_partition(
    got,
    15,
    8000,
    [76, 11641, 14392, 29439, 41, 0, 49],
    [
      6, 1, 2, 196, 6, 193, 15, 6, -1, 2, -1, -1, -1, 0, 6, 1, 2, 155, 4, 143, 31,
      6, 2, 0, 0, 1, 1, 0,
    ],
    7615,
    "pt2",
  )
  expect_dec_state(dec, "pt2", 55892480L, 27244235L, 30, 235)
}

///|
test "金标：split · 深分割到 lm=-1 与 N=1 叶" {
  let dec = RangeDecoder::new(SPLIT_PT2_BITS)
  play_split_pt2(dec)
}

///|
const SPLIT_PT3_BITS : Bytes = b"\xf3\x2f\x6e\xaa\xee\x2a\xe3\x5f\x79\x57\x8c\x48\x7f\xd2\xa2\x84\x81\xd7\x49\x36\x26\x2e\x18\x5c\x12\xde\xde\x4c\xcb\x66\x51\x2c\x97\xa7\x7c\x89\x19\x4f\x57\xdb\x87\x03\xdb\x60\x0b\xce\x67\x71\x57\x9f\x81\x16\xf8\xd7\x3b\x1a\x11\x75\xa7\x2e\x59\x4f\xdc\xaf"

///|
fn play_split_pt3(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT3_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 15, 0, 6, 40, 1, 15, 10)
  expect_partition(got, 15, 10, [], [6, 1, 0, 40, 0, 0, 15, 0], 10, "pt3")
  expect_dec_state(dec, "pt3", 2147483648L, 107497642L, 1, 8)
}

///|
test "金标：split · 预算循环逼退脉冲" {
  let dec = RangeDecoder::new(SPLIT_PT3_BITS)
  play_split_pt3(dec)
}

///|
const SPLIT_PT4_BITS : Bytes = b"\xf7\xfe\xec\x7a\x88\x1f\xa5\xd9\xd1\xac\x8a\xbe\x3d\x49\xa0\x6b\xfd\xa1\xb3\x9c\xe4\x02\x4d\x9f\x4a\x28\xcb\x84\x10\x6a\x61\x16\x92\x56\xbd\x61\x26\x1a\x50\x77\x62\xd6\x14\xaf\xb0\xc4\x8e\x80\x5b\xf3\xd0\xa7\xe0\x6c\x04\x21\xc2\xd9\xbb\x08\x25\xdd\x26\x60\x63\x4a\xc5\x19\x24\x6d\x4e\xd0\x46\x2a\xad\x85\x03\xd7\xaf\x9d\xf1\x70\x86\xf1\xfd\x48\x2b\x61\x53\x4b\xd4\x00\xb3\x65\x66\x19\x64\x97\x96\x2f\x24\x66\x65\xe6\xf0\x10\xdf\x6f\xec\x88\x38\x93\x3b\xaa\x74\xce\xb5\x44\x2b\xb5\x33\x1f\x71\x87\x7a\x0f\x94\x7e"

///|
fn play_split_pt4(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT4_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 15, 1, 12, 300, 2, 15, 8000)
  expect_partition(
    got,
    15,
    8000,
    [18, 16384, 0, 32767, 16384, 0, 34, 118, 7358, 24947, 21246, -4, 0, 49],
    [
      3, 1, -1, 110, 30, 109, 3, 3, -37, 3, -16, 3, 1, -1, 107, 28, 106, 1, 3, -29,
      17, 2, 6, 1, 0, 0, 0, 0, 2, 0,
    ],
    7702,
    "pt4",
  )
  expect_dec_state(dec, "pt4", 995725824L, 865450029L, 39, 305)
}

///|
test "金标：split · B0=2 的 delta 微调" {
  let dec = RangeDecoder::new(SPLIT_PT4_BITS)
  play_split_pt4(dec)
}

///|
const SPLIT_PT5_BITS : Bytes = b"\x1c\xb6\x61\x50\x71\xcb\x06\x8c\x33\xbb\xf0\xdb\x81\xc5\xef\x53\xa4\xa9\x04\x37\x6c\xf3\xdf\xa7\x61\xa8\xc6\x35\xbb\x6f\x66\x03\x36\x39\x4d\x35\x06\xfc\x0b\xff\xbc\x0a\x4f\x29\xc1\xb5\xf0\xb6\x3d\x5d\x83\x57\x01\x62\xb8\xf2\xa4\x5e\xfa\x31\x80\xe9\xcc\x48\x5c\xbe\xe7\xb5\x06\xdb\x96\xaa\x30\xd5\x7c\x2c\x0b\xc8\x58\xff\x1d\xb3\xc3\x7d\x38\x41\xd2\x55\x9f\xbf\xf5\xa0\x34\x45\xda\x94\x78\xbb\x4e\xa8\xd6\x5f\x00\x88\x9c\xbb\xbb\x7a\xb8\x74\x73\xe3\x46\x38\x8c\xef\x51\xe9\x1d\x38\x9b\xaf\xf2\x81\x08\x22\x17\x06\x44\xee\x5f\x5d\x6a\xb0\x19\x41\x64\x60\xdc\x80\x40\x8f\x28\xb5\x30\xf9\x4d\x10\x46\xe8\xc3\x35\xa9\x7b\xde\x48\xa6\xef\x38\x97\xe1\xd2\xe6\x81\x4a\x58\xe8\x62\x3e\x71\x0a\xe2\xed\x80\x5e\x9b\x86\x70\xa4\xca\x40\xa4\x8d\xad\xf5\x7a\xa1\xfa\x78\x2d\xca\x9b\xcd\xa4\x62\xe7\xd2\x2f\xe7\xb2\x3d\xd7\xa1\xea\xb2\xe8\xed\x15\xb1\xdd\x6e\x27\xbc\xa4\x60\x0f\x87\x72\xf3\x60\x8b\x6e\x57\xb4\xad\xc5\x2e\x32\x8e\x96\x8f\x4f\xb4\xf9\x89\xaf\x48\xed\x77\xbe\x08\x4f\x38\x1c\x08\x25\x8d\x06\xf7\x1c\x84\x21\xcd\xec\xa2\xe2"

///|
fn play_split_pt5(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT5_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 15, 3, 48, 400, 1, 15, 60)
  expect_partition(
    got,
    15,
    60,
    [
      6, 2730, 31652, 8479, -348, 0, 24, 8, 6144, 27246, 18205, -51, 0, 22, 20, 15564,
      2574, 32667, 147, 0, 47, 6, 8192, 23171, 23171, 0, 0, 16,
    ],
    [
      12, 1, 1, 195, 0, 0, 63, 0, 6, 1, 0, 208, 0, 0, 31, 0, 6, 1, 0, 245, 0, 0,
      63, 0, 12, 1, 1, 134, 0, 0, 15, 0, 12, 1, 1, 243, 0, 0, 31, 0,
    ],
    -49,
    "pt5",
  )
  expect_dec_state(dec, "pt5", 45434240L, 29052551L, 15, 117)
}

///|
test "金标：split · 紧预算下的深树" {
  let dec = RangeDecoder::new(SPLIT_PT5_BITS)
  play_split_pt5(dec)
}

///|
const SPLIT_PT6_BITS : Bytes = b"\xa1\x43\x56\xba\x2d\x3d\x3a\x45\xd8\x38\x5c\xde\xc3\x72\x2f\xa3\xf4\x7b\x88\x20\x29\xb6\x5e\x3d\xd9\x10\xbd\x1d\xd5\x6d\x8c\xe1\x7d\x1f\x17\xce\x8a\x8d\x6b\x96\x09\xa0\x79\xc8\x3c\x89\x1b\xa6\x25\xc3\x63\x56\xf7\xcd\x10\xb0\x54\x2d\xf6\x54\xbc\xd0\xc2\xae\xd8\xda\x28\xde\xe0\xbd\xfe\x93\x17\x21\x97\x11\x15\x70\xfc\xfa\xde\x05\x64\xab\x27\xc6\x7b\x74\xf9\xbf\xc1\x7a\xf3\x9a\x44\xec\x85\x3b\x6a\xd2\x88\x80\x0a\x89\x24\x34\x57\xba\x0e\xfc\x7d\x3b\x72\xaf\x83\x53\x16\xd9\xcb\xf6\x4b\x22\xf6\x4b\x9d\x9f\x72\xf4"

///|
fn play_split_pt6(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT6_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 8, 1, 16, 260, 4, 15, 8000)
  expect_partition(
    got,
    8,
    8000,
    [
      4, 12288, 12540, 30274, 71, 0, 19, 4, 0, 32767, 0, -16384, 0, 19, 8, 16384,
      0, 32767, 16384, 0, 25,
    ],
    [
      4, 1, -1, 135, 40, 8, 1, 4, -27, 38, -8, -55, 4, 1, -1, 0, 0, 0, 0, 0, 4, 1,
      -1, 165, 40, 8, 1, 4, -35, -14, 74, -5, 4, 1, -1, 0, 0, 0, 2, 0,
    ],
    7921,
    "pt6",
  )
  expect_dec_state(dec, "pt6", 21391104L, 2778209L, 54, 430)
}

///|
test "金标：split · 升频 B=4" {
  let dec = RangeDecoder::new(SPLIT_PT6_BITS)
  play_split_pt6(dec)
}

///|
const SPLIT_PT7_BITS : Bytes = b"\xaa\xfc\x1b\xe2\xd6\x6c\xab\x0c\x26\x33\x05\xf3\x1c\x66\x3e\x2d\xe2\xc3\x57\xd0\xc9\x1a\xa1\x2a\x31\x0e\xcb\x96\xac\xf2\xe2\xce\x84\xdf\xaa\xb1\x39\x7b\xf9\xeb\x5f\xa1\xb4\xea\x4b\x7f\x77\x9c\x73\x6e\xe3\x3b\x62\x1c\x69\x3c\x95\xf0\xb2\xd3\xd7\xcc\xf9\xcf"

///|
fn play_split_pt7(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT7_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 0, 0, 1, 30, 1, 0, 4000)
  expect_partition(
    got,
    0,
    4000,
    [],
    [1, 1, 0, 30, 40, 8, 0, 1, -128],
    3992,
    "pt7",
  )
  expect_dec_state(dec, "pt7", 1073741824L, 713159182L, 2, 16)
}

///|
test "金标：split · fill=0 的低带" {
  let dec = RangeDecoder::new(SPLIT_PT7_BITS)
  play_split_pt7(dec)
}

///|
const SPLIT_PT8_BITS : Bytes = b"\x59\xf8\xf3\x1d\x0d\xbb\x95\x73\xde\xad\xb0\xb7\x4b\x6f\xc1\x97\xa4\xb6\xb0\xf1\x5c\x8d\xe9\x40\x04\xf5\xc4\x6f\xcf\x9a\xb8\x52\xd0\x04\xdb\xb4\xa4\x17\x3f\x44\xb9\xa0\x5d\x4c\x13\x0d\xd9\xa3\x0d\x02\xe5\xec\xb6\xe8\xa7\x77\x73\x74\xd7\x3b\x71\xd1\x13\x45\x34\x59\x52\x4e\x63\xad\x1a\x3b\xc0\x20\x91\xc8\x91\x86\x1b\x50\x15\x3e\xb7\xa1\x13\xde\x95\x76\xdf\x4b\xc9\x8a\xaa\xa8\x3e\x63\x64\x9f\x80\xdf\x05\xa7\xb8\xac\xb0\xf5\x55\x7b\x91\xe5\xf5\x05\x9b\xfb\xd4\xb4\x71\x6d\x2f\x03\xeb\x4c\xe7\x9b\xde\xa7\x6d\x1c"

///|
fn play_split_pt8(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT8_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 15, 1, 6, 1200, 1, 15, 8000)
  expect_partition(
    got,
    15,
    8000,
    [
      256, 6848, 25956, 20001, -6, 0, 59, 256, 9536, 20001, 25956, 0, 0, 58, 256,
      11968, 13462, 29875, 0, 0, 63,
    ],
    [
      1, 1, -1, 258, 40, 129, 31, 1, -128, 1, 1, -1, 362, 40, 129, 63, 1, -128, 1,
      1, -1, 369, 40, 129, 31, 1, -128, 1, 1, -1, 585, 40, 129, 15, 1, -128,
    ],
    7304,
    "pt8",
  )
  expect_dec_state(dec, "pt8", 398715520L, 48019765L, 28, 220)
}

///|
test "金标：split · n=3 处继续分割到 N=1" {
  let dec = RangeDecoder::new(SPLIT_PT8_BITS)
  play_split_pt8(dec)
}

///|
const SPLIT_PT9_BITS : Bytes = b"\x38\xb5\xf4\x29\x13\x96\x97\xa5"

///|
fn play_split_pt9(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT9_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 20, 0, 22, 400, 4, 0, 60)
  expect_partition(
    got,
    20,
    60,
    [12, 2730, 31652, 8479, -151, 0, 30],
    [11, 2, -1, 260, 0, 0, 0, 0, 11, 2, -1, 346, 0, 0, 0, 0],
    30,
    "pt9",
  )
  expect_dec_state(dec, "pt9", 165191049L, 19848849L, 5, 38)
}

///|
test "金标：split · 覆盖搜索 6" {
  let dec = RangeDecoder::new(SPLIT_PT9_BITS)
  play_split_pt9(dec)
}

///|
const SPLIT_PT10_BITS : Bytes = b"\x9b\x89\x0e\x3c\xd6\x8c\x60\xe3\xef\x87\x2a\x0b\x86\xff\xd3\xc9\x0c\x36\xd7\xd9\x67\x50\x61\x17\x5e\xf3\x87\x09\xde\x84\x8d\x29\xe0\x66\x6c\x0c\x6a\x38\x77\xea\x39\x23\x67\x3d\x40\xb8\xba\xe4\x6c\x90\xc4\x2a\xb1\xd3\xce\xbb\x55\x9a\x1f\xc1\x26\x6f\x23\x92\x9b\x9d\x47\xe0\x21\xeb\x5f\xe9\x3d\xc3\xba\xfc\x91\x12\xf4\x76\xa9\x9e\xe9\x61\x14\xf6\x79\xe5\x40\xbe\x2d\xec\xaf\x6b\x02\xea\x6e\xad\x7d\x78\x5b\x15\x65\x54\xbe\x46\x98\x5b\x1f\xbb\x10\x10\x52\x66\x9c\x93\x74\x6b\x63\x83\x8a\x86\x67\xfc\x5c\x06\xb9\x2a\x45\x7d\x40\xe8\x58\x98\x11\x66\x3f\x19\x1d\xa0\xb0\x92\xa6\x7f\x79\x1a\xac\x85\x2d\xfd\x2d\xb1\xb1\xd0\x37\xad\x44\xc8\xa7\x26\xb0\x41\xd2\x42\x7c\xc4\x6c\x4f\x1a\x36\x77\x7b\x05\xf0\xf6\x31\x4e\x26\x37\x7f\x2c\xfb\xb0\x86\x1e\x03\x5b\x61\x53\xc2\xeb\x6d\xd5\x8f\x86\x06\x29\xe2\xd7\xd1\x2d\x92\x89\x2c\x98\x59\xfa\xdc\x30\xc2\xff\xbe\x22\xa9\xa2\xeb\x8f\xbe\x4f\x34\x04\x1d\xa2\xcf\xa9\xff\x96\x85\x5d\x7e\x4d\x81\x9d\xad\x16\x39\x17\xd8\x3a\x5b\xd2\x0d\xca\x74\xba\x50\xd9\xb2\x0d\x38\xb9\x39\x01\xea\x0a\xf5"

///|
fn play_split_pt10(dec : RangeDecoder) -> Unit raise {
  // 载荷见 SPLIT_PT10_BITS；期望值由
  // tools/gen_split_goldens.py 的独立参考端算出。
  let got = celt_decode_quant_partition(dec, 20, 1, 44, 700, 2, 0, 300)
  expect_partition(
    got,
    20,
    300,
    [
      14, 10532, 17436, 27745, 112, 0, 32, 12, 2730, 31652, 8479, -151, 0, 32, 12,
      10922, 16386, 28377, 63, 0, 26,
    ],
    [
      11, 1, -1, 253, 15, 231, 0, 11, -1, 2, 1, -3, 3, 2, 0, 2, 0, 1, 0, 11, 1, -1,
      102, 0, 0, 0, 0, 11, 1, -1, 209, 0, 0, 0, 0, 11, 1, -1, 331, 0, 0, 0, 0,
    ],
    -21,
    "pt10",
  )
  expect_dec_state(dec, "pt10", 268878080L, 38146745L, 41, 328)
}

///|
test "金标：split · 覆盖搜索 342" {
  let dec = RangeDecoder::new(SPLIT_PT10_BITS)
  play_split_pt10(dec)
}
