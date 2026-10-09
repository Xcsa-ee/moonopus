// 由 tools/gen_energy_goldens.py 生成，请勿手改。
//
// 能量解码（RFC 6716 §4.3.2）金标：载荷与期望值由本脚本内的独立
// 参考端算出（不同语言、不同实现路径），MoonBit 的 celt_energy.mbt
// 重放同一参数后逐项比对能量向量与范围解码器状态。
//
// 每个用例的 budget 都等于载荷长度，与参考实现「budget = ec_dec
// 的 storage × 8」一致；降级分支由短载荷自然触发，不人为缩短预算。

///|

///|
const ENER_LAPLACE_BITS : Bytes = b"\xe7\xee\xe7\x61\x5e\xf3\x5f\x30\xe4\x9b\x48\x2e\x15\xca\xe7\x50\x07\x20\x1e\x12\x61\x7b\x0f\xed\xa7\xe1\x64\x77\x96\xff\x02\x2b\xea\x8e\xd0\x2a\x82\xa1\x75\x93\x0f\x23\x37\xcd\x37\x94\xc5\x22\x08\x00\x6d\x6b\x1a\xf0\xc0\xcb\xd6\x25\x65\x8a\xac\x2c\x9f\xaa"

///|
fn play_laplace(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_LAPLACE_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  expect_laplace(dec, 9216, 8128, "laplace#0", 3, 95617024L, 11701327L, 6, 44)
  expect_laplace(
    dec, 8320, 8192, "laplace#1", 3, 1140681216L, 696249168L, 10, 80,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace#2", -1, 253660470L, 219178118L, 13, 97,
  )
  expect_laplace(
    dec, 22656, 704, "laplace#3", 0, 175383478L, 140901126L, 13, 101,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace#4", -1, 23880624L, 5848758L, 16, 124,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace#5", 2, 601036800L, 212088454L, 19, 151,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace#6", 1, 140022828L, 64838878L, 21, 168,
  )
  expect_laplace(dec, 9984, 3200, "laplace#7", -1, 39119315L, 6602161L, 23, 183)
  expect_laplace(
    dec, 10624, 4992, "laplace#8", -2, 715570944L, 338722896L, 27, 213,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace#9", -1, 168668988L, 32218764L, 29, 230,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace#10", 1, 39637047L, 19917434L, 31, 247,
  )
  expect_laplace(dec, 22656, 576, "laplace#11", 0, 27411639L, 7692026L, 32, 251)
  expect_laplace(
    dec, 2944, 11392, "laplace#12", -4, 326374400L, 145528423L, 36, 286,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace#13", 1, 74660160L, 52621543L, 38, 303,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace#14", 0, 26840384L, 4801767L, 40, 315,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace#15", 1, 1977131520L, 379693965L, 42, 329,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace#16", -2, 171477754L, 20568141L, 45, 358,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace#17", 1, 41843068L, 4450501L, 47, 374,
  )
  expect_laplace(dec, 17408, 1216, "laplace#18", 1, 9054496L, 2960133L, 49, 392)
  expect_laplace(
    dec, 20352, 640, "laplace#19", -1, 420473856L, 301003186L, 52, 411,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace#20", 1, 58740318L, 32527342L, 55, 434,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace#21", -1, 13848576L, 4858862L, 57, 451,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace#22", 1, 806242816L, 768311899L, 59, 468,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace#23", 0, 242515968L, 204585051L, 61, 482,
  )
  expect_laplace(dec, 5376, 7744, "laplace#24", 0, 39787776L, 1856859L, 63, 503)
  expect_laplace(
    dec, 14208, 2560, "laplace#25", 2, 379778048L, 325558248L, 68, 540,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace#26", 0, 206221184L, 152001384L, 69, 548,
  )
  expect_laplace(
    dec, 17792, 960, "laplace#27", 0, 111977216L, 57757416L, 70, 555,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace#28", 2, 10831890L, 8231418L, 73, 582,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace#29", 0, 913052160L, 247331573L, 75, 594,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace#30", 1, 199896336L, 137101589L, 77, 612,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace#31", -1, 58883300L, 56221689L, 79, 626,
  )
  expect_laplace(dec, 9216, 64, "laplace#32", 0, 16583908L, 13922297L, 81, 641)
  expect_laplace(
    dec, 32640, 11456, "laplace#33", 0, 16519140L, 13857529L, 81, 641,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace#34", 0, 2098455552L, 1417083162L, 82, 649,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace#35", -1, 379495114L, 288331748L, 84, 669,
  )
  expect_laplace(dec, 8320, 8192, "laplace#36", 0, 96362826L, 5199460L, 86, 684)
  expect_laplace(
    dec, 11776, 4992, "laplace#37", -3, 509537280L, 351877260L, 92, 729,
  )
  expect_laplace(
    dec, 22656, 704, "laplace#38", 0, 352305792L, 194645772L, 92, 733,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace#39", -2, 33543120L, 4869120L, 96, 761,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace",
  )
  expect_dec_state(dec, "laplace", 33543120L, 4869120L, 96, 761)
}

///|
test "能量金标：laplace" {
  let dec = RangeDecoder::new(ENER_LAPLACE_BITS)
  play_laplace(dec)
}

///|
const ENER_COARSE_INTER960_BITS : Bytes = b"\x54\xd6\xd6\x90\xf5\x6e\xf3\x5d\x78\x01\x07\xbd\xdb\x23\x4a\x76\x77\x15\xdf\xd0\xe2\x11\xa8\xfe\x3b\xbc\x0b\x4f\x2d\x3f\x0a\xe8\x52\xaf\xcd\xf8\x4d\x5f\x13\xf0\x78\x26\x65\x6a\x24\x3e\xf3\xc6\x66\xae\x4a\xd1\x95\xba\xe7\xc5\xa2\xf8\xc5\x88\x0d\x2f\x51\xfd"

///|
fn play_coarse_inter960(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_INTER960_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  expect_energy(
    old_e,
    [
      -5.5, 0.57501220703125, -0.75, -3.70001220703125, 1.17498779296875, -0.95001220703125,
      -3.70001220703125, 1.17498779296875, -0.95001220703125, -3.70001220703125,
      1.17498779296875, -0.95001220703125, -4.70001220703125, -0.625, -2.54998779296875,
      -5.29998779296875, -1.42498779296875, -3.3499755859375, -6.0999755859375, -1.2249755859375,
      -2.3499755859375,
    ],
    "coarse_inter960",
  )
  expect_dec_state(dec, "coarse_inter960", 91870065L, 2053352L, 30, 237)
}

///|
test "能量金标：coarse_inter960" {
  let dec = RangeDecoder::new(ENER_COARSE_INTER960_BITS)
  play_coarse_inter960(dec)
}

///|
const ENER_COARSE_INTRA960_BITS : Bytes = b"\x47\x7c\x0c\xe4\x5e\x3d\xb0\x28\x76\x89\x19\xa3\x5b\xdc\x18\x0a\x87\x9f\xd7\x61\x5c\x39\x1f\xa7\xab\x84\x5e\xc9\x9f\x48\x8f\x8a\x5e\xdd\x19\xaf\x10\xd6\x80\x91\xd1\xcb\x5e\x9d\xbf\xcb\x0c\x98\xdd\xda\x2d\x2e\xe3\xb6\x32\xdd\xce\x1d\x64\x7a\xcd\x03\x31\xea"

///|
fn play_coarse_intra960(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_INTRA960_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, true, 3)
  expect_energy(
    old_e,
    [
      1.0, -0.149993896484375, 1.0, 1.850006103515625, 0.70001220703125, 0.850006103515625,
      -0.149993896484375, 0.0, 0.0, 3.0, 4.550018310546875, 5.250030517578125, 5.10003662109375,
      5.10003662109375, 5.10003662109375, 5.10003662109375, 7.10003662109375, 6.800048828125,
      7.800048828125, 8.650054931640625, 9.50006103515625,
    ],
    "coarse_intra960",
  )
  expect_dec_state(dec, "coarse_intra960", 27694457L, 18424022L, 48, 379)
}

///|
test "能量金标：coarse_intra960" {
  let dec = RangeDecoder::new(ENER_COARSE_INTRA960_BITS)
  play_coarse_intra960(dec)
}

///|
const ENER_COARSE_INTER120_BITS : Bytes = b"\x94\x2a\x08\x9d\xd8\xc2\xb7\x42\x62\x88\xe3\x07\x71\xe8\x0c\x36\x2b\xff\xd7\x0a\xdc\xb7\x1d\x69\x12\xbc\x58\x6e\xb9\xbc\x90\xa0"

///|
fn play_coarse_inter120(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_INTER120_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 0)
  expect_energy(
    old_e,
    [
      -7.0859375, -1.246185302734375, -3.224517822265625, -5.165924072265625, 2.83380126953125,
      -3.8245849609375, -6.845977783203125, 1.9937744140625, -2.744598388671875,
      -8.686004638671875, 0.9937744140625, -2.8245849609375, -6.7659912109375, 0.073760986328125,
      -2.8245849609375, -8.7659912109375, 1.913787841796875, -1.8245849609375, -7.686004638671875,
      1.073760986328125, -1.744598388671875,
    ],
    "coarse_inter120",
  )
  expect_dec_state(dec, "coarse_inter120", 42702048L, 15235982L, 47, 374)
}

///|
test "能量金标：coarse_inter120" {
  let dec = RangeDecoder::new(ENER_COARSE_INTER120_BITS)
  play_coarse_inter120(dec)
}

///|
const ENER_COARSE_INTRA240_BITS : Bytes = b"\xc4\x5d\x6f\x55\x63\x56\x2e\x4d\x91\x06\xe1\xef\x3b\x0e\x56\xfb\xe3\x9b\xff\x2b\x82\x50\xa7\x9c\x26\xbb\x11\x6d\xa1\xad\x23\x9f"

///|
fn play_coarse_intra240(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_INTRA240_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, true, 1)
  expect_energy(
    old_e,
    [
      4.0, 4.4000244140625, 2.250030517578125, 2.550018310546875, 1.550018310546875,
      3.70001220703125, 3.4000244140625, 4.4000244140625, 5.250030517578125, 4.10003662109375,
      4.250030517578125, 5.250030517578125, 7.10003662109375, 7.800048828125, 7.650054931640625,
      7.650054931640625, 6.650054931640625, 6.800048828125, 6.800048828125, 5.800048828125,
      5.950042724609375,
    ],
    "coarse_intra240",
  )
  expect_dec_state(dec, "coarse_intra240", 30368316L, 421875L, 48, 378)
}

///|
test "能量金标：coarse_intra240" {
  let dec = RangeDecoder::new(ENER_COARSE_INTRA240_BITS)
  play_coarse_intra240(dec)
}

///|
const ENER_COARSE_WINDOW_BITS : Bytes = b"\xc1\x07\x6d\x9c\xf2\x15\x82\x11\x9c\xd9\x31\x3f\x64\xa1\x5c\xb7\xf0\x35\x32\xb6\xd4\xb4\x60\x52\xeb\x25\x24\xce\x23\x41\x14\x58\x27\x71\xd9\xe4\xdf\xfc\xf7\xe2\x1d\xfd\x90\x56\x18\xd1\xc0\xea\x09\xf4\x70\xdb\xb3\x20\x42\x3f\x2f\x77\x5f\x45\x70\x4b\xbf\x6b"

///|
fn play_coarse_window(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_WINDOW_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 5, 17, false, 2)
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -1.26953125, -5.2059326171875, 0.1163330078125,
      -4.26953125, -8.095947265625, -1.4036865234375, -4.1595458984375, -8.7259521484375,
      -2.03369140625, -5.78955078125, -8.9859619140625, -2.6636962890625, -3.5, -12.0,
      0.75, -3.5,
    ],
    "coarse_window",
  )
  expect_dec_state(dec, "coarse_window", 47958930L, 42373511L, 23, 180)
}

///|
test "能量金标：coarse_window" {
  let dec = RangeDecoder::new(ENER_COARSE_WINDOW_BITS)
  play_coarse_window(dec)
}

///|
const ENER_COARSE_SHORT_100_BITS : Bytes = b"\x4a\xeb\xe8\x59\xc9"

///|
fn play_coarse_short_100(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_SHORT_100_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  expect_energy(
    old_e,
    [
      -5.5, -1.42498779296875, -5.3499755859375, -7.699951171875, -2.824951171875,
      -4.949951171875, -7.699951171875, -2.824951171875, -5.949951171875, -9.49993896484375,
      -5.4249267578125, -7.34991455078125, -10.09991455078125, -6.22491455078125,
      -8.14990234375, -10.89990234375, -7.02490234375, -8.94989013671875, -11.69989013671875,
      -7.82489013671875, -10.7498779296875,
    ],
    "coarse_short_100",
  )
  expect_dec_state(dec, "coarse_short_100", 213554304L, 68723071L, 37, 291)
}

///|
test "能量金标：coarse_short_100" {
  let dec = RangeDecoder::new(ENER_COARSE_SHORT_100_BITS)
  play_coarse_short_100(dec)
}

///|
const ENER_COARSE_SHORT_102_BITS : Bytes = b"\x4b"

///|
fn play_coarse_short_102(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_SHORT_102_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  expect_energy(
    old_e,
    [
      -4.5, -0.625, -2.54998779296875, -6.29998779296875, -2.2249755859375, -5.14996337890625,
      -8.699951171875, -4.62493896484375, -7.5499267578125, -11.09991455078125, -7.02490234375,
      -9.94989013671875, -13.4998779296875, -9.42486572265625, -12.349853515625,
      -15.89984130859375, -11.8248291015625, -14.74981689453125, -18.2998046875,
      -14.22479248046875, -17.1497802734375,
    ],
    "coarse_short_102",
  )
  expect_dec_state(dec, "coarse_short_102", 16777216L, 8388607L, 8, 64)
}

///|
test "能量金标：coarse_short_102" {
  let dec = RangeDecoder::new(ENER_COARSE_SHORT_102_BITS)
  play_coarse_short_102(dec)
}

///|
const ENER_COARSE_SHORT_103_BITS : Bytes = b"\xe9\x6e"

///|
fn play_coarse_short_103(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_SHORT_103_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  expect_energy(
    old_e,
    [
      -8.5, -2.824951171875, -4.949951171875, -7.699951171875, -2.824951171875, -5.949951171875,
      -8.49993896484375, -2.62493896484375, -5.949951171875, -9.49993896484375, -5.4249267578125,
      -8.34991455078125, -11.89990234375, -7.82489013671875, -10.7498779296875, -14.29986572265625,
      -10.224853515625, -13.14984130859375, -16.6998291015625, -12.62481689453125,
      -15.5498046875,
    ],
    "coarse_short_103",
  )
  expect_dec_state(dec, "coarse_short_103", 24969216L, 12845055L, 16, 124)
}

///|
test "能量金标：coarse_short_103" {
  let dec = RangeDecoder::new(ENER_COARSE_SHORT_103_BITS)
  play_coarse_short_103(dec)
}

///|
const ENER_COARSE_SHORT_104_BITS : Bytes = b"\x0a\x65\x74"

///|
fn play_coarse_short_104(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_SHORT_104_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  expect_energy(
    old_e,
    [
      -4.5, 0.375, -2.75, -2.29998779296875, 1.9749755859375, -0.1500244140625, -3.9000244140625,
      0.17498779296875, -1.75, -3.5, 0.17498779296875, -2.75, -6.29998779296875,
      -2.2249755859375, -5.14996337890625, -8.699951171875, -4.62493896484375, -7.5499267578125,
      -11.09991455078125, -7.02490234375, -9.94989013671875,
    ],
    "coarse_short_104",
  )
  expect_dec_state(dec, "coarse_short_104", 23665664L, 19214335L, 24, 189)
}

///|
test "能量金标：coarse_short_104" {
  let dec = RangeDecoder::new(ENER_COARSE_SHORT_104_BITS)
  play_coarse_short_104(dec)
}

///|
const ENER_LAPLACE_TAIL_512_BITS : Bytes = b"\x09\xe0\x48\xa9\xd2\xb9\xcf\x56\x70\x7b\x7b\x02\x32\xff\xd2\x3f\xb7\x09\x86\x30\x8b\x0a\x7c\x22\x6a\xb9\x5a\xe6\xfc\x0b\x5a\x05\x49\xe5\x9c\x64\xd8\x47\x70\x54\xf1\x27\x26\x5e\xb3\x51\xc1\x3f\x2e\x73\x31\x1d\x03\x0f\x14\x0a\xbe\x5a\x63\x28\x94\xa5\xe6\x90"

///|
fn play_laplace_tail_512(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_LAPLACE_TAIL_512_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_512#0", 0, 603979776L, 521132971L, 3, 23,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_512#1", 0, 153354240L, 70507435L, 5, 39,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_512#2", -1, 34103160L, 6368035L, 7, 56,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_512#3", -1, 1284341760L, 222339862L, 10, 78,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_512#4", 5, 41781870L, 26835202L, 15, 118,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_512#5", -1, 2041632000L, 472045475L, 18, 137,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_512#6", -2, 163488320L, 135349255L, 21, 166,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_512#7", 0, 49818944L, 21679879L, 23, 180,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_512#8", 1, 11685760L, 11392519L, 25, 197,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_512#9", 0, 1008435200L, 933365528L, 27, 209,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_512#10", 0, 460886400L, 385816728L, 28, 218,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_512#11", 0, 318661120L, 243591448L, 28, 223,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_512#12", 1, 44137236L, 41857344L, 31, 245,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_512#13", 0, 11402516L, 9122624L, 33, 261,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_512#14", 0, 1054282752L, 470630484L, 35, 273,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_512#15", -1, 303400820L, 36860616L, 36, 287,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_512#16", 2, 26314078L, 8065126L, 40, 315,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_512#17", 1, 1643721728L, 1431523015L, 42, 332,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_512#18", 0, 873233408L, 661034695L, 43, 339,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_512#19", 0, 542371840L, 330173127L, 43, 344,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_512#20", -2, 52681833L, 36541836L, 47, 371,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_512#21", -1, 12418896L, 11729756L, 49, 388,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_512#22", 0, 1308905472L, 1132485826L, 50, 398,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_512#23", 0, 393708544L, 217288898L, 52, 412,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_512#24", 1, 86688225L, 61550468L, 54, 430,
  )
  expect_laplace(
    dec, 14208, 2560, "laplace_tail_512#25", 0, 37597025L, 12459268L, 55, 439,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace_tail_512#26", -1, 2014315520L, 806455362L, 58, 457,
  )
  expect_laplace(
    dec, 17792, 960, "laplace_tail_512#27", -1, 432455520L, 318306210L, 60, 475,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace_tail_512#28", 1, 60165123L, 43359912L, 63, 498,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace_tail_512#29", 0, 19743747L, 2938536L, 64, 511,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace_tail_512#30", 1, 1105599488L, 142598270L, 66, 528,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace_tail_512#31", 1, 325692220L, 20931830L, 68, 542,
  )
  expect_laplace(
    dec, 9216, 64, "laplace_tail_512#32", 1, 116435385L, 19719272L, 70, 554,
  )
  expect_laplace(
    dec, 32640, 11456, "laplace_tail_512#33", 0, 115980601L, 19264488L, 70, 554,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace_tail_512#34", -4, 767368448L, 567584230L, 75, 596,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_512#35", 0, 215827712L, 16043494L, 77, 611,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_512#36", -4, 1288116224L, 205693568L, 82, 654,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_512#37", -2, 87268200L, 40670188L, 86, 685,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_512#38", 0, 60339944L, 13741932L, 87, 690,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_512#39", 4, 718726400L, 162307094L, 91, 725,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_512#40", 2, 70733925L, 11057126L, 94, 752,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_512#41", 2, 1449623552L, 1294819040L, 98, 781,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_512#42", 0, 441682176L, 286877664L, 100, 795,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_512#43", -1, 103626552L, 92025240L, 102, 811,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_512#44", 0, 34821432L, 23220120L, 103, 824,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_512#45", 0, 15926328L, 4325016L, 105, 833,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_512#46", -1, 605035008L, 454144548L, 107, 855,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_512#47", 1, 83808096L, 71090404L, 110, 878,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_512#48", 0, 21621856L, 8904164L, 112, 894,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_512#49", -1, 1312348416L, 50380155L, 114, 910,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_512#50", 2, 66401242L, 20904091L, 119, 945,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_512#51", 1, 16376158L, 3087447L, 121, 961,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_512#52", 1, 1021441024L, 396934972L, 123, 977,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_512#53", -1, 221189416L, 139337828L, 125, 995,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_512#54", 0, 137381416L, 55529828L, 125, 1000,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_512#55", -3, 9276896L, 3779588L, 129, 1031,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_512#56", 1, 559878144L, 408855783L, 131, 1048,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_512#57", 0, 229639936L, 78617575L, 133, 1058,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_512#58", 1, 67024512L, 52099303L, 135, 1073,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_512#59", -1, 14754675L, 10837338L, 137, 1090,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace_tail_512",
  )
  expect_dec_state(dec, "laplace_tail_512", 14754675L, 10837338L, 137, 1090)
}

///|
test "能量金标：laplace_tail_512" {
  let dec = RangeDecoder::new(ENER_LAPLACE_TAIL_512_BITS)
  play_laplace_tail_512(dec)
}

///|
const ENER_LAPLACE_TAIL_533_BITS : Bytes = b"\xc1\x57\xbd\x84\xd3\x19\xfa\xb6\x90\x5f\xc3\x47\x39\xb4\x0c\x99\x3e\x69\x4a\x87\x32\x00\x45\x00\x7a\xfd\x3e\x04\x08\xf3\x03\x3a\x60\xad\x10\x6e\x9e\x85\x76\xcd\x2e\xe8\x46\xb1\x5c\xf6\x2b\x27\xe4\x34\x3e\xeb\x59\x39\xd3\x26\x2c\xaf\x79\xb9\xb3\x44\x3d\xc5"

///|
fn play_laplace_tail_533(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_LAPLACE_TAIL_533_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_533#0", 2, 192675840L, 144187709L, 5, 36,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_533#1", 0, 48921600L, 433469L, 7, 52,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_533#2", 4, 78682112L, 29994390L, 14, 111,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_533#3", 0, 54403200L, 5715478L, 15, 115,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_533#4", -7, 221404160L, 198056563L, 21, 163,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_533#5", 0, 46721024L, 23373427L, 23, 181,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_533#6", -1, 10878450L, 1055077L, 25, 198,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_533#7", -2, 151507968L, 42498818L, 29, 231,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_533#8", 1, 35541624L, 11210354L, 31, 248,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_533#9", 1, 2143440896L, 1118245540L, 34, 265,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_533#10", -1, 503737812L, 458173048L, 36, 281,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_533#11", 0, 348296148L, 302731384L, 36, 285,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_533#12", -1, 48245031L, 33977119L, 39, 308,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_533#13", -1, 11034112L, 9212191L, 41, 325,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_533#14", 0, 1019084800L, 552673207L, 43, 337,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_533#15", -1, 293273000L, 133383007L, 44, 351,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_533#16", 1, 72334767L, 54685501L, 46, 368,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_533#17", 0, 30242863L, 12593597L, 48, 378,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_533#18", -1, 1674883072L, 1273392592L, 50, 395,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_533#19", 0, 1040264064L, 638773584L, 51, 401,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_533#20", -2, 101047518L, 75567798L, 54, 428,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_533#21", 0, 29620574L, 4140854L, 56, 442,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_533#22", 1, 1725206784L, 42457118L, 58, 459,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_533#23", 2, 82606281L, 8445864L, 62, 494,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_533#24", 3, 1039933440L, 279681116L, 67, 529,
  )
  expect_laplace(
    dec, 14208, 2560, "laplace_tail_533#25", 1, 248080312L, 186821580L, 69, 545,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace_tail_533#26", 0, 134711992L, 73453260L, 69, 552,
  )
  expect_laplace(
    dec, 17792, 960, "laplace_tail_533#27", 0, 73145656L, 11886924L, 70, 560,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace_tail_533#28", 5, 608532480L, 247802979L, 75, 599,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace_tail_533#29", 1, 137956530L, 114878919L, 77, 616,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace_tail_533#30", 0, 60896690L, 37819079L, 79, 626,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace_tail_533#31", -1, 17935274L, 13183857L, 80, 640,
  )
  expect_laplace(
    dec, 9216, 64, "laplace_tail_533#32", 0, 1293396480L, 77033765L, 82, 654,
  )
  expect_laplace(
    dec, 32640, 11456, "laplace_tail_533#33", 0, 1288344192L, 71981477L, 82, 654,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace_tail_533#34", -7, 11362613L, 6361404L, 89, 709,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_533#35", -1, 524901376L, 67279097L, 92, 729,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_533#36", 3, 24459486L, 17975693L, 96, 764,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_533#37", 0, 8799454L, 2315661L, 97, 776,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_533#38", -1, 330964992L, 230010291L, 100, 798,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_533#39", 1, 45066200L, 20213091L, 103, 821,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_533#40", 1, 8600625L, 1862341L, 105, 840,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_533#41", -2, 175996928L, 114302304L, 109, 869,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_533#42", -1, 49171505L, 41100945L, 111, 884,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_533#43", 0, 15955505L, 7884945L, 113, 897,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_533#44", -1, 960989184L, 272243147L, 115, 914,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_533#45", 1, 225847227L, 202151617L, 117, 930,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_533#46", 0, 156155323L, 132459713L, 117, 935,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_533#47", -1, 21628335L, 11976688L, 120, 958,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_533#48", -1, 1266524160L, 223449178L, 122, 975,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_533#49", 1, 300666129L, 13419644L, 124, 991,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_533#50", 2, 15212150L, 6666844L, 129, 1026,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_533#51", 1, 960131072L, 662125756L, 131, 1042,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_533#52", 0, 401321472L, 103316156L, 132, 1052,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_533#53", -1, 86904712L, 2106948L, 134, 1070,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_533#54", 1, 15782052L, 743820L, 137, 1089,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_533#55", -9, 30660864L, 14949222L, 144, 1146,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_533#56", -1, 1849774080L, 131282687L, 146, 1162,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_533#57", 2, 95456950L, 73703687L, 150, 1196,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_533#58", 0, 28714294L, 6961031L, 152, 1210,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_533#59", 2, 764712960L, 404643805L, 155, 1236,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace_tail_533",
  )
  expect_dec_state(dec, "laplace_tail_533", 764712960L, 404643805L, 155, 1236)
}

///|
test "能量金标：laplace_tail_533" {
  let dec = RangeDecoder::new(ENER_LAPLACE_TAIL_533_BITS)
  play_laplace_tail_533(dec)
}

///|
const ENER_LAPLACE_TAIL_645_BITS : Bytes = b"\x64\x4e\xd5\x37\x90\x0d\xf5\x6f\x9d\x89\x0c\xa9\x81\xa1\x8c\x37\xa9\x17\x27\x5e\x14\xbd\xa7\xf1\xbf\x39\x51\xe1\xc8\x9f\x18\xbe\x8a\x8b\x18\x2d\x0c\x65\x38\x0b\xd1\x2c\xb2\x1e\x48\x0b\xf6\xf3\xa8\xdc\x6a\xbc\x81\xf7\x4c\xde\x75\x68\x76\xf9\x22\xfe\x55\x76"

///|
fn play_laplace_tail_645(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_LAPLACE_TAIL_645_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_645#0", -1, 388366336L, 150902116L, 4, 28,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_645#1", 1, 72356460L, 5857340L, 6, 48,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_645#2", 2, 1254850560L, 381418551L, 10, 79,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_645#3", -1, 184735080L, 178914591L, 13, 101,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_645#4", 0, 17338728L, 11518239L, 16, 128,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_645#5", -1, 847077120L, 294223609L, 19, 147,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_645#6", 1, 197338900L, 86699809L, 21, 164,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_645#7", -1, 55131410L, 4625971L, 23, 179,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_645#8", 2, 1008877056L, 287756037L, 27, 209,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_645#9", 1, 237806512L, 93422181L, 29, 226,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_645#10", -1, 55886157L, 20191794L, 31, 243,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_645#11", 0, 38645197L, 2950834L, 31, 247,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_645#12", 7, 154533888L, 37676104L, 37, 295,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_645#13", -2, 13534920L, 7220176L, 41, 323,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_645#14", -1, 822458112L, 451381041L, 43, 340,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_645#15", -1, 236683570L, 112996323L, 45, 354,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_645#16", 1, 58383509L, 49477261L, 47, 370,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_645#17", 0, 24416277L, 15510029L, 48, 380,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_645#18", 0, 12973077L, 4066829L, 49, 387,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_645#19", -1, 601765120L, 387367483L, 51, 407,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_645#20", 1, 84070392L, 3119147L, 54, 430,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_645#21", 3, 559457280L, 223285113L, 59, 472,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_645#22", -1, 127415799L, 20713968L, 62, 489,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_645#23", 1, 37184832L, 6001776L, 63, 503,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_645#24", -3, 467970048L, 221377707L, 68, 538,
  )
  expect_laplace(
    dec, 14208, 2560, "laplace_tail_645#25", -1, 111634577L, 67956924L, 70, 555,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace_tail_645#26", 0, 60626321L, 16948668L, 71, 562,
  )
  expect_laplace(
    dec, 17792, 960, "laplace_tail_645#27", -1, 13014750L, 2257818L, 73, 579,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace_tail_645#28", 5, 108238080L, 80817727L, 78, 619,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace_tail_645#29", 0, 35519232L, 8098879L, 79, 632,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace_tail_645#30", 1, 1988977152L, 976519983L, 82, 649,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace_tail_645#31", -1, 585917794L, 171725201L, 83, 663,
  )
  expect_laplace(
    dec, 9216, 64, "laplace_tail_645#32", 1, 209464200L, 169543841L, 85, 675,
  )
  expect_laplace(
    dec, 32640, 11456, "laplace_tail_645#33", 0, 208646024L, 168725665L, 85, 675,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace_tail_645#34", 0, 103514120L, 63593761L, 86, 683,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_645#35", -1, 18720234L, 7913227L, 88, 703,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_645#36", 1, 892404480L, 236884281L, 91, 723,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_645#37", 1, 198454158L, 62096469L, 93, 740,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_645#38", 0, 137215886L, 858197L, 93, 744,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_645#39", 15, 31084288L, 26761700L, 104, 825,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_645#40", 0, 1682636800L, 576054315L, 106, 843,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_645#41", 1, 392005900L, 163816515L, 108, 860,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_645#42", -1, 109521265L, 772788L, 110, 875,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_645#43", 4, 186510336L, 11323508L, 117, 933,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_645#44", 2, 12708003L, 817922L, 121, 964,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_645#45", -2, 101350656L, 73956716L, 126, 1004,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_645#46", 0, 70084352L, 42690412L, 126, 1008,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_645#47", -2, 1727367168L, 1301246032L, 130, 1035,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_645#48", 0, 445338368L, 19217232L, 132, 1051,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_645#49", -3, 1798663680L, 1771080437L, 138, 1099,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_645#50", 0, 541024000L, 513440757L, 139, 1112,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_645#51", 0, 128934400L, 101351157L, 142, 1129,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_645#52", 0, 53905152L, 26321909L, 143, 1139,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_645#53", 0, 28637952L, 1054709L, 144, 1146,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_645#54", 1, 1329977088L, 155132833L, 146, 1166,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_645#55", 6, 30196728L, 16081771L, 152, 1210,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_645#56", -1, 1822076928L, 476551980L, 154, 1226,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_645#57", 1, 414980115L, 231778770L, 156, 1243,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_645#58", -1, 121118496L, 62739698L, 158, 1258,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_645#59", 1, 26666640L, 14832146L, 160, 1275,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace_tail_645",
  )
  expect_dec_state(dec, "laplace_tail_645", 26666640L, 14832146L, 160, 1275)
}

///|
test "能量金标：laplace_tail_645" {
  let dec = RangeDecoder::new(ENER_LAPLACE_TAIL_645_BITS)
  play_laplace_tail_645(dec)
}

///|
const ENER_COARSE_SHORT_106_BITS : Bytes = b"\xf5\x08\xf3\x1d\x84"

///|
fn play_coarse_short_106(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_SHORT_106_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  expect_energy(
    old_e,
    [
      -0.5, 6.574951171875, 1.84991455078125, 0.49993896484375, 6.1749267578125,
      4.84991455078125, 1.89990234375, 6.77490234375, 5.64990234375, 3.69989013671875,
      8.3748779296875, 6.2498779296875, 2.4998779296875, 7.57489013671875, 5.44989013671875,
      1.69989013671875, 6.77490234375, 4.64990234375, 0.89990234375, 4.97491455078125,
      2.0499267578125,
    ],
    "coarse_short_106",
  )
  expect_dec_state(dec, "coarse_short_106", 21592400L, 18656207L, 40, 318)
}

///|
test "能量金标：coarse_short_106" {
  let dec = RangeDecoder::new(ENER_COARSE_SHORT_106_BITS)
  play_coarse_short_106(dec)
}

///|
const ENER_COARSE_SHORT_108_BITS : Bytes = b"\x42"

///|
fn play_coarse_short_108(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_COARSE_SHORT_108_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  expect_energy(
    old_e,
    [
      -4.5, -0.625, -2.54998779296875, -5.29998779296875, -0.42498779296875, -3.54998779296875,
      -7.0999755859375, -3.02496337890625, -5.949951171875, -9.49993896484375, -5.4249267578125,
      -8.34991455078125, -11.89990234375, -7.82489013671875, -10.7498779296875, -14.29986572265625,
      -10.224853515625, -13.14984130859375, -16.6998291015625, -12.62481689453125,
      -15.5498046875,
    ],
    "coarse_short_108",
  )
  expect_dec_state(dec, "coarse_short_108", 16777216L, 16777215L, 8, 64)
}

///|
test "能量金标：coarse_short_108" {
  let dec = RangeDecoder::new(ENER_COARSE_SHORT_108_BITS)
  play_coarse_short_108(dec)
}

///|
const ENER_FINE_BITS : Bytes = b"\x06\xf0\x39\xc9\x48\x16\x47\x39\x76\x47\x4b\x10\x1f\x45\x76\xe5\xd3\x68\x2f\x3c\x0a\xce\xae\x65\x69\xa9\xc8\xba\x7e\x6b\x6f\xd5\x1e\x1a\x5c\xb6\x44\x68\x4b\xc0\x0f\x2c\xe0\x6f\x6a\xdd\xbc\x63\xa9\x70\xf6\x15\x86\xac\x96\xab\xca\xf6\xa1\x6d\x30\x9c\x5a\x97"

///|
fn play_fine(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_FINE_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  let extra_quant : Array[Int] = [
    0, 1, 3, 2, 0, 8, 4, 1, 0, 5, 2, 0, 6, 3, 1, 0, 7, 2, 4, 1, 0,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  cel_unquant_fine_energy(dec, old_e, 0, 21, extra_quant)
  expect_energy(
    old_e,
    [
      -4.5, 0.625, -2.8125, -5.42498779296875, -0.42498779296875, -2.63397216796875,
      -4.70623779296875, -0.375, -2.54998779296875, -5.19061279296875, 0.20001220703125,
      -1.75, -5.8046875, -0.23748779296875, -2.29998779296875, -5.29998779296875,
      0.25079345703125, -2.125, -4.65625, -0.375, -1.54998779296875,
    ],
    "fine",
  )
  expect_dec_state(dec, "fine", 12437880L, 8483983L, 83, 660)
}

///|
test "能量金标：fine" {
  let dec = RangeDecoder::new(ENER_FINE_BITS)
  play_fine(dec)
}

///|
const ENER_FINALISE_BITS : Bytes = b"\x27\x6d\x4a\x9b\x79\xfe\x0c\x13\x33\xa6\xa9\x1d\xf0\xbd\x00\x40\x04\xf8\x67\x93\x67\xe4\x29\xab\x3d\x12\x39\x51\xe0\x0a\xdc\x19\x13\xb4\x74\x53\xef\x9e\xfc\x55\x99\x2a\x10\x94\x75\x93\xa8\x28\x7c\xcd\x94\xda\x23\xf4\x04\x5c\xe4\x53\x2e\x1f\x43\x85\x18\x9a"

///|
fn play_finalise(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_FINALISE_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  let fine_quant : Array[Int] = [
    0, 2, 8, 1, 0, 7, 3, 5, 0, 4, 6, 1, 2, 8, 0, 3, 1, 7, 0, 5, 2,
  ]
  let fine_priority : Array[Int] = [
    0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  cel_unquant_energy_finalise(dec, old_e, 0, 21, fine_quant, fine_priority, 40)
  expect_energy(
    old_e,
    [
      -4.75, 2.3125, 0.8499755859375, -1.97503662109375, 3.02496337890625, 0.65191650390625,
      -4.13128662109375, 1.16717529296875, 0.29998779296875, -2.9156494140625, 1.9788818359375,
      -0.2750244140625, -3.9625244140625, 1.17498779296875, -2.20001220703125, -3.46875,
      1.29998779296875, -0.95196533203125, -3.95001220703125, 1.18280029296875, -0.01251220703125,
    ],
    "finalise",
  )
  expect_dec_state(dec, "finalise", 160067355L, 34946220L, 56, 446)
}

///|
test "能量金标：finalise" {
  let dec = RangeDecoder::new(ENER_FINALISE_BITS)
  play_finalise(dec)
}

///|
const ENER_FINALISE_SHORT_BITS : Bytes = b"\x55\x77\x8d\xf5\x5f\xa4\xf6\xe3\x90\x24\x9a\xd3\x9e\xfe\x1a\xda\x8f\xa3\x7d\x3c\x1c\xa3\x91\x6d\x21\xbb\x3f\xa4\x7c\x8b\xa3\x03\xb5\x9b\xc9\xc7\x5e\x38\x10\xba\x3f\x20\x4c\x2f\x3d\xa2\x01\x1d\xd1\x8d\xb2\x67\x62\xc6\xea\xf2\xb7\xe8\x9d\xf8\x23\x04\xf6\xc2"

///|
fn play_finalise_short(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_FINALISE_SHORT_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  let fine_quant : Array[Int] = [
    0, 2, 8, 1, 0, 7, 3, 5, 0, 4, 6, 1, 2, 8, 0, 3, 1, 7, 0, 5, 2,
  ]
  let fine_priority : Array[Int] = [
    0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  cel_unquant_energy_finalise(dec, old_e, 0, 21, fine_quant, fine_priority, 5)
  expect_energy(
    old_e,
    [
      -5.75, 0.57501220703125, -0.75, -3.70001220703125, 0.42498779296875, -1.75,
      -4.53125, 0.375, -2.0, -5.5, -0.42889404296875, -2.54998779296875, -5.29998779296875,
      -0.42498779296875, -2.54998779296875, -5.29998779296875, -0.42498779296875,
      -1.54998779296875, -5.5, -0.42498779296875, -2.54998779296875,
    ],
    "finalise_short",
  )
  expect_dec_state(dec, "finalise_short", 78753464L, 67866172L, 35, 279)
}

///|
test "能量金标：finalise_short" {
  let dec = RangeDecoder::new(ENER_FINALISE_SHORT_BITS)
  play_finalise_short(dec)
}

///|
const ENER_CHAIN_BITS : Bytes = b"\xb6\x0e\x75\x0f\xc7\xba\x21\xd9\x9c\xae\x30\x4f\x31\x8c\xb1\x00\x4f\x2c\x1f\xbd\x82\x1e\xc6\x55\x9e\x95\xc3\xa0\x6c\x69\xe7\x5b\x43\xc8\xd9\x78\x7f\x39\x26\xe3\x8f\xd4\x3b\x90\x65\x59\xcf\xaf\xe6\x2e\xf2\xd7\xec\xb9\x43\xe3\x8c\x47\x77\x50\x97\x9f\x23\x99"

///|
fn play_chain(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_CHAIN_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  let extra_quant : Array[Int] = [
    0, 1, 3, 2, 0, 8, 4, 1, 0, 5, 2, 0, 6, 3, 1, 0, 7, 2, 4, 1, 0,
  ]
  let fine_quant : Array[Int] = [
    0, 2, 8, 1, 0, 7, 3, 5, 0, 4, 6, 1, 2, 8, 0, 3, 1, 7, 0, 5, 2,
  ]
  let fine_priority : Array[Int] = [
    0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  cel_unquant_fine_energy(dec, old_e, 0, 21, extra_quant)
  cel_unquant_energy_finalise(dec, old_e, 0, 21, fine_quant, fine_priority, 40)
  expect_energy(
    old_e,
    [
      -2.25, 2.1624755859375, -0.0875244140625, -3.1500244140625, 1.7249755859375,
      0.9046630859375, -2.85003662109375, 2.2327880859375, -0.4000244140625, -2.7750244140625,
      2.3538818359375, -0.0250244140625, -1.8765869140625, 2.33746337890625, 0.14996337890625,
      -2.13128662109375, 2.06793212890625, 0.9730224609375, -1.63128662109375, 3.01715087890625,
      2.71246337890625,
    ],
    "chain",
  )
  expect_dec_state(dec, "chain", 282399488L, 244894995L, 105, 840)
}

///|
test "能量金标：chain" {
  let dec = RangeDecoder::new(ENER_CHAIN_BITS)
  play_chain(dec)
}

///|
const ENER_FINE_EXHAUSTED_700_BITS : Bytes = b"\x55\x62\xe5\x6e"

///|
fn play_fine_exhausted_700(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_FINE_EXHAUSTED_700_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  let extra_quant : Array[Int] = [
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
  ]
  cel_unquant_coarse_energy(dec, old_e, 0, 21, false, 3)
  cel_unquant_fine_energy(dec, old_e, 0, 21, extra_quant)
  expect_energy(
    old_e,
    [
      -5.5, 0.57501220703125, -0.75, -3.70001220703125, 1.17498779296875, 0.04998779296875,
      -1.9000244140625, 2.77496337890625, 1.64996337890625, -1.300048828125, 2.574951171875,
      0.64996337890625, -2.10003662109375, 2.77496337890625, 0.64996337890625, -2.10003662109375,
      2.77496337890625, 0.64996337890625, -2.10003662109375, 3.77496337890625, 0.449951171875,
    ],
    "fine_exhausted_700",
  )
  expect_dec_state(dec, "fine_exhausted_700", 28195184L, 17746815L, 32, 251)
}

///|
test "能量金标：fine_exhausted_700" {
  let dec = RangeDecoder::new(ENER_FINE_EXHAUSTED_700_BITS)
  play_fine_exhausted_700(dec)
}

///|
const ENER_LAPLACE_TAIL_522_BITS : Bytes = b"\x27\x77\xc5\x0a\x44\x2e\x60\x46\x15\xe1\x9f\x9e\x7d\xd0\xf2\x47\x04\xae\xcf\x25\xf0\xe8\xbe\x49\xc7\xe0\xf1\xbb\x0d\xcc\xd6\x94\x45\x92\x9c\x69\x15\xc5\xd2\x00\xcc\x38\xe6\xfe\x25\xef\xc1\xc3\x29\xf3\x56\x0a\x74\x30\x8a\x97\xd1\x0f\x98\x0f\x83\xe2\x71\xff"

///|
fn play_laplace_tail_522(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_LAPLACE_TAIL_522_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_522#0", 0, 603979776L, 272899450L, 3, 23,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_522#1", 1, 112527360L, 47328634L, 6, 43,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_522#2", -1, 25023558L, 265664L, 8, 60,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_522#3", -2, 40628224L, 18006237L, 15, 118,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_522#4", 2, 989614080L, 279016L, 19, 145,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_522#5", -27, 1979187200L, 472960988L, 34, 265,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_522#6", -2, 158489600L, 146559388L, 37, 295,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_522#7", 0, 48306176L, 36375964L, 39, 308,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_522#8", 0, 15665920L, 3735708L, 41, 321,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_522#9", 1, 945170432L, 183954677L, 43, 338,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_522#10", 1, 222127644L, 115017517L, 45, 355,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_522#11", 0, 153588508L, 46478381L, 45, 359,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_522#12", -4, 1829804800L, 1674356239L, 50, 394,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_522#13", 0, 471751680L, 316303119L, 52, 410,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_522#14", 0, 169550848L, 14102287L, 53, 422,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_522#15", -2, 8578492L, 1715731L, 57, 456,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_522#16", -2, 189891072L, 41538352L, 61, 484,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_522#17", 1, 46336820L, 23689752L, 63, 501,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_522#18", 0, 24617780L, 1970712L, 64, 508,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_522#19", 1, 1144115456L, 405682736L, 66, 528,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_522#20", 3, 77266895L, 51923956L, 70, 559,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_522#21", -1, 18214896L, 15531876L, 72, 576,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_522#22", 0, 1916891136L, 1230038209L, 74, 586,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_522#23", -1, 559474872L, 449206905L, 75, 600,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_522#24", -1, 123181695L, 104724984L, 78, 617,
  )
  expect_laplace(
    dec, 14208, 2560, "laplace_tail_522#25", 0, 53414655L, 34957944L, 79, 627,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace_tail_522#26", 0, 29003775L, 10547064L, 80, 634,
  )
  expect_laplace(
    dec, 17792, 960, "laplace_tail_522#27", -1, 1593849600L, 900935447L, 82, 652,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace_tail_522#28", -2, 154188800L, 41758487L, 85, 679,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace_tail_522#29", 1, 34953445L, 8080097L, 87, 696,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace_tail_522#30", 1, 1957755904L, 988928390L, 90, 714,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace_tail_522#31", -1, 576718485L, 196769435L, 91, 728,
  )
  expect_laplace(
    dec, 9216, 64, "laplace_tail_522#32", 1, 206184000L, 194622235L, 93, 740,
  )
  expect_laplace(
    dec, 32640, 11456, "laplace_tail_522#33", 0, 205378624L, 193816859L, 93, 740,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace_tail_522#34", 0, 101897920L, 90336155L, 94, 748,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_522#35", 0, 28674752L, 17112987L, 96, 762,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_522#36", -1, 1367520000L, 272092892L, 98, 782,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_522#37", 1, 304108371L, 4250498L, 100, 799,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_522#38", -2, 494141440L, 479953533L, 108, 857,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_522#39", 0, 46325760L, 32137853L, 111, 885,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_522#40", -1, 8838315L, 4441640L, 113, 904,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_522#41", -1, 525707776L, 58512040L, 116, 921,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_522#42", -2, 28684884L, 15420542L, 120, 954,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_522#43", -1, 1722112000L, 709514904L, 122, 971,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_522#44", 1, 405927096L, 377794056L, 124, 988,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_522#45", 0, 185537592L, 157404552L, 125, 997,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_522#46", 0, 128283448L, 100150408L, 126, 1001,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_522#47", -1, 17765646L, 1184918L, 128, 1024,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_522#48", 3, 152488448L, 110473837L, 133, 1063,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_522#49", 0, 54812672L, 12798061L, 135, 1075,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_522#50", 1, 15766960L, 6023117L, 137, 1089,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_522#51", 1, 995308288L, 459059975L, 139, 1105,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_522#52", -1, 242870504L, 122637551L, 141, 1122,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_522#53", 0, 129037544L, 8804591L, 142, 1129,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_522#54", 1, 23429087L, 6780973L, 144, 1149,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_522#55", -4, 281304576L, 165266315L, 148, 1184,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_522#56", -1, 66337152L, 32729355L, 151, 1201,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_522#57", -1, 15105112L, 8714595L, 153, 1218,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_522#58", -1, 1126256640L, 659076000L, 154, 1232,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_522#59", 1, 247979550L, 213572060L, 157, 1249,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace_tail_522",
  )
  expect_dec_state(dec, "laplace_tail_522", 247979550L, 213572060L, 157, 1249)
}

///|
test "能量金标：laplace_tail_522" {
  let dec = RangeDecoder::new(ENER_LAPLACE_TAIL_522_BITS)
  play_laplace_tail_522(dec)
}

///|
const ENER_LAPLACE_TAIL_562_BITS : Bytes = b"\xbd\x3d\x1d\x64\x3b\xc3\x5d\xb7\xd8\xe7\x1f\xe8\xfd\xd2\x08\xd4\x98\x05\xc6\x2f\x01\x19\x7e\x3d\x28\xdc\x49\x90\x41\x03\xbb\x7a\x66\x8f\xff\xef\x1b\x58\x6c\x07\xb5\x04\xa8\x29\x26\x27\xa5\xaf\xd2\xe1\x64\x6b\x21\xd8\xa6\xb4\x24\xba\x59\x83\xfd\xad\xa9\x05"

///|
fn play_laplace_tail_562(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_LAPLACE_TAIL_562_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_562#0", 2, 192675840L, 178614605L, 5, 36,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_562#1", 0, 48921600L, 34860365L, 7, 52,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_562#2", 0, 17601536L, 3540301L, 8, 64,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_562#3", -1, 663164928L, 179365346L, 11, 86,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_562#4", -4, 30862950L, 4407836L, 16, 121,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_562#5", 3, 400610048L, 268407326L, 20, 156,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_562#6", -1, 93325650L, 76939376L, 22, 173,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_562#7", 0, 28436818L, 12050544L, 24, 186,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_562#8", 1, 1706366976L, 1582768209L, 26, 203,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_562#9", 0, 573236736L, 449637969L, 27, 216,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_562#10", 0, 262001280L, 138402513L, 29, 225,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_562#11", 0, 181155840L, 57557073L, 29, 229,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_562#12", 3, 12128432L, 2022785L, 33, 260,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_562#13", 2, 271846400L, 177977636L, 36, 288,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_562#14", 0, 97696768L, 3828004L, 38, 300,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_562#15", 2, 1265279488L, 418300947L, 42, 335,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_562#16", 1, 312108879L, 78738225L, 44, 351,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_562#17", 1, 76153904L, 49404305L, 46, 367,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_562#18", 0, 40457264L, 13707665L, 47, 374,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_562#19", -1, 1879944704L, 1466843020L, 50, 394,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_562#20", -1, 262644438L, 3767778L, 53, 417,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_562#21", 4, 580670720L, 328480880L, 59, 472,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_562#22", -1, 132244360L, 118233080L, 62, 489,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_562#23", 0, 39794440L, 25783160L, 63, 503,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_562#24", -1, 8759010L, 1288282L, 65, 520,
  )
  expect_laplace(
    dec, 14208, 2560, "laplace_tail_562#25", 1, 534307584L, 129802251L, 68, 537,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace_tail_562#26", 1, 111852300L, 109323171L, 70, 555,
  )
  expect_laplace(
    dec, 17792, 960, "laplace_tail_562#27", 0, 60739212L, 58210083L, 71, 562,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace_tail_562#28", 0, 1340967936L, 693511041L, 74, 590,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace_tail_562#29", -1, 304016967L, 96567240L, 76, 607,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace_tail_562#30", 1, 66553198L, 59867428L, 79, 625,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace_tail_562#31", 0, 20018926L, 13333156L, 80, 638,
  )
  expect_laplace(
    dec, 9216, 64, "laplace_tail_562#32", -1, 1829414400L, 1564822038L, 82, 650,
  )
  expect_laplace(
    dec, 32640, 11456, "laplace_tail_562#33", 0, 1822268288L, 1557675926L, 82, 650,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace_tail_562#34", 0, 904019456L, 639427094L, 83, 658,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_562#35", -1, 163486488L, 153161006L, 85, 678,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_562#36", 0, 41515416L, 31189934L, 87, 694,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_562#37", 0, 14939544L, 4614062L, 89, 706,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_562#38", 0, 10338584L, 13102L, 89, 710,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_562#39", -31, 20643840L, 12319637L, 104, 830,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_562#40", 1, 1008806400L, 1001384371L, 107, 849,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_562#41", 0, 291615744L, 284193715L, 108, 864,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_562#42", 0, 88860928L, 81438899L, 110, 877,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_562#43", 0, 28828544L, 21406515L, 112, 890,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_562#44", 0, 9701504L, 2279475L, 113, 903,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_562#45", 1, 583550976L, 402441213L, 115, 920,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_562#46", 0, 403476480L, 222366717L, 116, 924,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_562#47", -2, 38859828L, 5781047L, 119, 951,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_562#48", 2, 870643200L, 391492380L, 123, 979,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_562#49", -1, 206680251L, 40436183L, 125, 996,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_562#50", 1, 59475010L, 14880219L, 127, 1010,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_562#51", -2, 1320506880L, 1043799016L, 130, 1038,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_562#52", 0, 551943424L, 275235560L, 131, 1048,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_562#53", 0, 293234944L, 16527080L, 132, 1055,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_562#54", 1, 53249548L, 11927808L, 135, 1075,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_562#55", 4, 640224000L, 119054975L, 139, 1110,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_562#56", -2, 50134508L, 18512427L, 143, 1140,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_562#57", -1, 11410927L, 370842L, 145, 1157,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_562#58", 2, 139779072L, 37384819L, 149, 1192,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_562#59", 2, 14543650L, 11189189L, 153, 1218,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace_tail_562",
  )
  expect_dec_state(dec, "laplace_tail_562", 14543650L, 11189189L, 153, 1218)
}

///|
test "能量金标：laplace_tail_562" {
  let dec = RangeDecoder::new(ENER_LAPLACE_TAIL_562_BITS)
  play_laplace_tail_562(dec)
}

///|
const ENER_LAPLACE_TAIL_632_BITS : Bytes = b"\xbb\x77\x12\x01\x9a\x2a\x6d\x8e\xb9\xeb\xd4\x59\x57\x79\x04\x20\xd8\xcd\xe5\x60\x11\x30\x52\x8e\x4e\x5b\xa7\xdd\xa0\xfb\xfa\x01\x07\x34\xfb\xdb\xc0\x0b\x15\x9e\x86\xfa\xef\x93\xeb\xf3\xbd\x70\x45\x68\x24\x12\x31\x4a\x2f\x97\xab\x39\xb3\x86\x15\x29\x40\x5d"

///|
fn play_laplace_tail_632(dec : RangeDecoder) -> Unit raise {
  // 载荷见 ENER_LAPLACE_TAIL_632_BITS；期望值由 tools/gen_energy_goldens.py 的
  // 独立参考端算出，本函数重放同一参数后逐项比对。
  let old_e : Array[Double] = [
    -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0,
    0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
  ]
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_632#0", -2, 192675840L, 816895L, 5, 36,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_632#1", 8, 72253440L, 34512690L, 14, 112,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_632#2", -1, 16067835L, 4293165L, 17, 129,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_632#3", -1, 605122560L, 435723754L, 19, 151,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_632#4", 1, 82395292L, 52148002L, 22, 174,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_632#5", -1, 15725070L, 2871088L, 25, 193,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_632#6", -2, 321765376L, 72338633L, 28, 222,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_632#7", 1, 89892945L, 28408427L, 30, 237,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_632#8", 1, 21088184L, 9843803L, 32, 254,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_632#9", -1, 1271432192L, 209575736L, 34, 271,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_632#10", 1, 298806501L, 116841346L, 36, 287,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_632#11", 0, 206605285L, 24640130L, 37, 292,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_632#12", 6, 1189576960L, 816773283L, 42, 335,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_632#13", -1, 272127288L, 206011611L, 44, 352,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_632#14", 0, 97809720L, 31694043L, 46, 364,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_632#15", 1, 28139120L, 19602875L, 48, 379,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_632#16", -1, 1775414784L, 1311336714L, 50, 395,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_632#17", 0, 742074752L, 277996682L, 51, 405,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_632#18", -1, 160696016L, 90850138L, 53, 422,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_632#19", 0, 99807952L, 29962074L, 54, 428,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_632#20", -4, 1199681280L, 971875605L, 58, 463,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_632#21", 0, 351477632L, 123671957L, 60, 477,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_632#22", 1, 80048138L, 76456105L, 62, 494,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_632#23", 0, 24097034L, 20505001L, 64, 508,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_632#24", 0, 1014761984L, 95201747L, 67, 529,
  )
  expect_laplace(
    dec, 14208, 2560, "laplace_tail_632#25", 1, 242076856L, 4589379L, 69, 546,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace_tail_632#26", 2, 1064673536L, 929041748L, 75, 593,
  )
  expect_laplace(
    dec, 17792, 960, "laplace_tail_632#27", 0, 578088320L, 442456532L, 75, 600,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace_tail_632#28", 1, 80425319L, 74923938L, 78, 622,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace_tail_632#29", 0, 26398055L, 20896674L, 80, 635,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace_tail_632#30", 0, 11663335L, 6161954L, 81, 645,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace_tail_632#31", -1, 877264640L, 372482371L, 83, 659,
  )
  expect_laplace(
    dec, 9216, 64, "laplace_tail_632#32", -1, 313622265L, 55594044L, 84, 671,
  )
  expect_laplace(
    dec, 32640, 11456, "laplace_tail_632#33", 0, 312397305L, 54369084L, 84, 671,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace_tail_632#34", 3, 11553996L, 374172L, 89, 709,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_632#35", 5, 32350208L, 29465725L, 96, 761,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_632#36", 0, 2104328192L, 1365900783L, 98, 777,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_632#37", 0, 756242944L, 17815535L, 99, 789,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_632#38", 1, 111328272L, 7107343L, 102, 811,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_632#39", -8, 316546048L, 209811L, 108, 863,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_632#40", -21, 633077760L, 455579917L, 123, 983,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_632#41", 0, 182999040L, 5501197L, 125, 997,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_632#42", 2, 9984192L, 486765L, 129, 1030,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_632#43", -3, 55566336L, 18148687L, 135, 1075,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_632#44", 1, 13092180L, 7449847L, 137, 1091,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_632#45", 0, 1534252032L, 89815031L, 138, 1100,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_632#46", 1, 227690523L, 71742125L, 141, 1122,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_632#47", 3, 15243912L, 1942517L, 145, 1154,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_632#48", 2, 341644800L, 70168935L, 148, 1182,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_632#49", 1, 81103854L, 13514051L, 150, 1198,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_632#50", 1, 23339250L, 3485351L, 152, 1213,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_632#51", 2, 518017024L, 325384150L, 156, 1241,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_632#52", 0, 216526848L, 23893974L, 157, 1251,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_632#53", 1, 46883272L, 16176998L, 159, 1269,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_632#54", -1, 8509930L, 6932048L, 161, 1288,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_632#55", -1, 303539712L, 83719864L, 164, 1311,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_632#56", 1, 71584464L, 12283608L, 166, 1328,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_632#57", 1, 16299192L, 2669640L, 169, 1345,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_632#58", 1, 1216846848L, 201982168L, 170, 1359,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_632#59", -3, 59861620L, 33760618L, 175, 1394,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace_tail_632",
  )
  expect_dec_state(dec, "laplace_tail_632", 59861620L, 33760618L, 175, 1394)
}

///|
test "能量金标：laplace_tail_632" {
  let dec = RangeDecoder::new(ENER_LAPLACE_TAIL_632_BITS)
  play_laplace_tail_632(dec)
}
