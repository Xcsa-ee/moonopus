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
    dec, 22656, 704, "laplace#3", 0, 175383478L, 219178118L, 13, 101,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace#4", 0, 16450486L, 219178118L, 17, 129,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace#5", 0, 888518144L, 275023494L, 19, 147,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace#6", 1, 206995910L, 57344274L, 21, 163,
  )
  expect_laplace(dec, 9984, 3200, "laplace#7", 1, 57832135L, 29082016L, 23, 178)
  expect_laplace(
    dec, 10624, 4992, "laplace#8", -1, 13561632L, 3581632L, 25, 195,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace#9", 1, 816643072L, 249542736L, 27, 212,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace#10", 1, 191916621L, 189981546L, 29, 228,
  )
  expect_laplace(
    dec, 22656, 576, "laplace#11", 0, 132700749L, 189981546L, 30, 233,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace#12", 0, 11943373L, 189981546L, 33, 260,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace#13", 0, 791268608L, 1390635623L, 35, 276,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace#14", 0, 284374784L, 1390635623L, 36, 288,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace#15", 0, 85544448L, 1390635623L, 38, 302,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace#16", 0, 20398848L, 1390635623L, 40, 318,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace#17", 0, 8536064L, 1390635623L, 41, 328,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace#18", 0, 1162870784L, 1667917709L, 42, 336,
  )
  expect_laplace(
    dec, 20352, 640, "laplace#19", 0, 722251776L, 1667917709L, 43, 341,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace#20", 0, 59258496L, 1667917709L, 47, 370,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace#21", 0, 17370752L, 1667917709L, 48, 384,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace#22", 0, 1824489472L, 1785171378L, 50, 394,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace#23", 0, 548772224L, 1785171378L, 51, 408,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace#24", 0, 90038400L, 1785171378L, 54, 429,
  )
  expect_laplace(
    dec, 14208, 2560, "laplace#25", 0, 39054080L, 1785171378L, 55, 439,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace#26", 0, 21217664L, 1785171378L, 56, 446,
  )
  expect_laplace(
    dec, 17792, 960, "laplace#27", 0, 11528192L, 1785171378L, 57, 453,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace#28", 0, 259850240L, 1737339483L, 61, 481,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace#29", 0, 85263360L, 1737339483L, 62, 494,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace#30", 0, 37636352L, 1737339483L, 63, 503,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace#31", 0, 11333376L, 1737339483L, 65, 517,
  )
  expect_laplace(
    dec, 9216, 64, "laplace#32", 0, 821231616L, 229792744L, 67, 532,
  )
  expect_laplace(
    dec, 32640, 11456, "laplace#33", 0, 818023680L, 229792744L, 67, 532,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace#34", 2, 43262612L, 27883912L, 71, 566,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace#35", -1, 2002513920L, 1182103797L, 74, 585,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace#36", -1, 373082655L, 61144724L, 76, 605,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace#37", -2, 25274700L, 13350494L, 80, 636,
  )
  expect_laplace(
    dec, 22656, 704, "laplace#38", 0, 17478348L, 13350494L, 80, 640,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace#39", 1, 608830976L, 583428634L, 83, 663,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace",
  )
  expect_dec_state(dec, "laplace", 608830976L, 583428634L, 83, 663)
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
      -5.5, 0.57501220703125, -0.75, -3.70001220703125, 1.17498779296875, 0.04998779296875,
      -2.9000244140625, 1.9749755859375, -0.1500244140625, -2.9000244140625, 1.9749755859375,
      -0.1500244140625, -2.9000244140625, 1.9749755859375, -0.1500244140625, -2.9000244140625,
      1.9749755859375, -0.1500244140625, -2.9000244140625, 1.9749755859375, -0.1500244140625,
    ],
    "coarse_inter960",
  )
  expect_dec_state(dec, "coarse_inter960", 21844352L, 1619758408L, 24, 189)
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
      0.850006103515625, 0.850006103515625, 0.850006103515625, 0.850006103515625,
      0.850006103515625, 0.850006103515625, 0.850006103515625, 0.850006103515625,
      0.850006103515625, 0.850006103515625, 0.850006103515625, 0.850006103515625,
      0.850006103515625, 0.850006103515625, 0.850006103515625,
    ],
    "coarse_intra960",
  )
  expect_dec_state(dec, "coarse_intra960", 27391616L, 2034032935L, 32, 251)
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
      -7.0859375, -1.246185302734375, -3.224517822265625, -8.165924072265625, 0.593841552734375,
      -3.224517822265625, -8.165924072265625, 0.593841552734375, -3.224517822265625,
      -8.165924072265625, 0.593841552734375, -3.224517822265625, -8.165924072265625,
      -0.406158447265625, -2.30450439453125, -8.165924072265625, 0.593841552734375,
      -3.224517822265625, -8.165924072265625, 0.593841552734375, -3.224517822265625,
    ],
    "coarse_inter120",
  )
  expect_dec_state(dec, "coarse_inter120", 707589504L, 883020894L, 35, 277)
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
      4.0, 4.4000244140625, 2.250030517578125, 2.550018310546875, 2.550018310546875,
      2.550018310546875, 2.550018310546875, 2.550018310546875, 2.550018310546875,
      2.550018310546875, 2.550018310546875, 4.550018310546875, 3.250030517578125,
      3.4000244140625, 3.4000244140625, 4.4000244140625, 4.250030517578125, 4.250030517578125,
      4.250030517578125, 4.250030517578125, 4.250030517578125,
    ],
    "coarse_intra240",
  )
  expect_dec_state(dec, "coarse_intra240", 953826560L, 767677239L, 43, 338)
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
      -12.0, 0.75, -3.5, -12.0, 0.75, -1.26953125, -5.2059326171875, 1.1163330078125,
      -1.6395263671875, -5.2059326171875, 1.1163330078125, -1.6395263671875, -5.2059326171875,
      1.1163330078125, -1.6395263671875, -5.2059326171875, 1.1163330078125, -3.5,
      -12.0, 0.75, -3.5,
    ],
    "coarse_window",
  )
  expect_dec_state(dec, "coarse_window", 191447552L, 2118726022L, 13, 100)
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
      -4.949951171875, -7.699951171875, -2.824951171875, -4.949951171875, -7.699951171875,
      -0.824951171875, -2.3499755859375, -5.29998779296875, -0.42498779296875, -2.54998779296875,
      -5.29998779296875, -0.42498779296875, -2.54998779296875, -5.29998779296875,
      -0.42498779296875, -2.54998779296875,
    ],
    "coarse_short_100",
  )
  expect_dec_state(dec, "coarse_short_100", 665732608L, 1094713343L, 35, 278)
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
      -4.5, 0.375, -1.75, -4.5, 0.375, -1.75, -4.5, -0.625, -3.54998779296875, -7.0999755859375,
      -3.02496337890625, -5.949951171875, -9.49993896484375, -5.4249267578125, -8.34991455078125,
      -11.89990234375, -7.82489013671875, -10.7498779296875, -14.29986572265625,
      -10.224853515625, -13.14984130859375,
    ],
    "coarse_short_102",
  )
  expect_dec_state(dec, "coarse_short_102", 16777216L, 1518338047L, 8, 64)
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
      -8.5, -2.824951171875, -4.949951171875, -7.699951171875, -2.824951171875, -4.949951171875,
      -7.699951171875, -2.824951171875, -4.949951171875, -7.699951171875, -3.824951171875,
      -6.74993896484375, -10.2999267578125, -6.22491455078125, -9.14990234375, -12.69989013671875,
      -8.6248779296875, -11.54986572265625, -15.099853515625, -11.02484130859375,
      -13.9498291015625,
    ],
    "coarse_short_103",
  )
  expect_dec_state(dec, "coarse_short_103", 24969216L, 1560281087L, 16, 124)
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
      -4.5, 0.375, -1.75, -4.5, 0.375, -1.75, -4.5, 0.375, -1.75, -4.5, 0.375, -1.75,
      -4.5, 0.375, -1.75, -4.5, 0.375, -1.75, -4.5, 0.375, -2.75,
    ],
    "coarse_short_104",
  )
  expect_dec_state(dec, "coarse_short_104", 21272064L, 1174405119L, 24, 190)
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
      -4.5, 0.625, -1.8125, -4.625, 0.375, -1.833984375, -3.90625, 2.42498779296875,
      0.8499755859375, -0.99066162109375, 3.199951171875, 1.449951171875, -1.604736328125,
      3.762451171875, 1.699951171875, -1.300048828125, 3.250732421875, 1.074951171875,
      -1.456298828125, 3.824951171875, 1.449951171875,
    ],
    "fine",
  )
  expect_dec_state(dec, "fine", 1058819712L, 1281225948L, 77, 609)
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
      -4.75, 0.3125, -1.75, -4.375, 0.625, -1.748046875, -4.53125, 0.3671875, -1.5,
      -4.515625, 0.37890625, -1.875, -4.5625, 0.375, -2.0, -4.46875, 0.5, -1.751953125,
      -4.75, 0.3828125, -1.8125,
    ],
    "finalise",
  )
  expect_dec_state(dec, "finalise", 97966720L, 1521632000L, 41, 324)
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
      -5.75, 0.57501220703125, -0.75, -3.70001220703125, 1.42498779296875, -0.95001220703125,
      -3.73126220703125, 1.17498779296875, -1.20001220703125, -3.70001220703125,
      1.17108154296875, -0.95001220703125, -3.70001220703125, 1.17498779296875, -0.95001220703125,
      -3.70001220703125, 1.17498779296875, -0.95001220703125, -3.70001220703125,
      1.17498779296875, -0.95001220703125,
    ],
    "finalise_short",
  )
  expect_dec_state(dec, "finalise_short", 46250752L, 1128878125L, 28, 221)
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
      -0.0953369140625, -2.6500244140625, 2.2327880859375, -0.4000244140625, -2.7750244140625,
      2.3538818359375, -0.0250244140625, -2.8765869140625, 1.5374755859375, -0.6500244140625,
      -2.9312744140625, 2.2679443359375, -0.0269775390625, -2.4312744140625, 2.2171630859375,
      -0.0875244140625,
    ],
    "chain",
  )
  expect_dec_state(dec, "chain", 62030464L, 1165499426L, 92, 729)
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
      -5.5, 0.57501220703125, -0.75, -3.70001220703125, 1.17498779296875, -0.95001220703125,
      -3.70001220703125, 1.17498779296875, -0.95001220703125, -3.70001220703125,
      1.17498779296875, -0.95001220703125, -3.70001220703125, 2.17498779296875, -0.1500244140625,
      -2.9000244140625, 1.9749755859375, -0.1500244140625, -2.9000244140625, 1.9749755859375,
      0.8499755859375,
    ],
    "fine_exhausted_700",
  )
  expect_dec_state(dec, "fine_exhausted_700", 432226304L, 218103807L, 28, 219)
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
    dec, 9216, 8128, "laplace_tail_512#0", 0, 603979776L, 2064636843L, 3, 23,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_512#1", 0, 153354240L, 2064636843L, 5, 39,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_512#2", 0, 55111680L, 2064636843L, 7, 51,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_512#3", 0, 38113408L, 2064636843L, 7, 55,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_512#4", 0, 915701760L, 266054422L, 11, 82,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_512#5", 2, 90122625L, 73345702L, 14, 109,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_512#6", 0, 26058625L, 73345702L, 16, 123,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_512#7", 0, 2034008320L, 1596630691L, 18, 137,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_512#8", 0, 659463808L, 1596630691L, 19, 150,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_512#9", 0, 221543808L, 1596630691L, 21, 163,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_512#10", 0, 101269888L, 1596630691L, 22, 172,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_512#11", 0, 70023808L, 1596630691L, 22, 176,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_512#12", 0, 1617854464L, 715563800L, 26, 204,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_512#13", 1, 370100008L, 255012456L, 28, 221,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_512#14", 0, 133016360L, 255012456L, 30, 233,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_512#15", 0, 40016552L, 255012456L, 31, 246,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_512#16", 0, 9540392L, 255012456L, 33, 263,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_512#17", 0, 1021552640L, 858679380L, 35, 273,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_512#18", 0, 542704640L, 858679380L, 35, 280,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_512#19", 0, 337070848L, 858679380L, 36, 286,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_512#20", 0, 27667968L, 858679380L, 40, 315,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_512#21", 0, 2077229056L, 778589383L, 42, 329,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_512#22", -1, 473094496L, 26443303L, 44, 346,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_512#23", 2, 22651653L, 17117001L, 48, 381,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_512#24", -1, 1276304640L, 812721858L, 50, 399,
  )
  expect_laplace(
    dec, 14208, 2560, "laplace_tail_512#25", 0, 553411200L, 812721858L, 51, 408,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace_tail_512#26", 0, 300496512L, 812721858L, 52, 415,
  )
  expect_laplace(
    dec, 17792, 960, "laplace_tail_512#27", 0, 163166592L, 812721858L, 53, 422,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace_tail_512#28", 0, 14035584L, 812721858L, 57, 451,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace_tail_512#29", 0, 1180860416L, 1898365506L, 58, 463,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace_tail_512#30", 0, 521239168L, 1898365506L, 60, 473,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace_tail_512#31", 0, 156800896L, 1898365506L, 61, 487,
  )
  expect_laplace(
    dec, 9216, 64, "laplace_tail_512#32", 0, 44104576L, 1898365506L, 63, 501,
  )
  expect_laplace(
    dec, 32640, 11456, "laplace_tail_512#33", 0, 43932416L, 1898365506L, 63, 501,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace_tail_512#34", 0, 21806336L, 1898365506L, 64, 509,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_512#35", 0, 1572929536L, 650265214L, 66, 524,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_512#36", 1, 293052210L, 62816738L, 68, 543,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_512#37", 1, 65167641L, 5420564L, 71, 561,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_512#38", 1, 9590112L, 4498132L, 73, 583,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_512#39", 2, 233226240L, 65225958L, 77, 610,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_512#40", 2, 22952325L, 16147126L, 80, 637,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_512#41", -1, 1368012800L, 1327033984L, 82, 654,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_512#42", 0, 416826368L, 1327033984L, 84, 667,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_512#43", 0, 135154688L, 1327033984L, 85, 680,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_512#44", 0, 45416448L, 1327033984L, 87, 693,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_512#45", 0, 20756736L, 1327033984L, 88, 702,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_512#46", 0, 14355840L, 1327033984L, 89, 706,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_512#47", 0, 330989568L, 418283542L, 92, 734,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_512#48", 0, 85333248L, 418283542L, 94, 750,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_512#49", 0, 30670080L, 418283542L, 96, 762,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_512#50", 0, 9247360L, 418283542L, 97, 775,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_512#51", 0, 565411840L, 1853888224L, 99, 792,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_512#52", 0, 236324480L, 1853888224L, 101, 802,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_512#53", 0, 125548160L, 1853888224L, 102, 809,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_512#54", 0, 77982464L, 1853888224L, 102, 815,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_512#55", 0, 1644068864L, 1499172L, 106, 844,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_512#56", -11, 12844288L, 11303803L, 121, 964,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_512#57", 0, 1353482240L, 746289980L, 122, 974,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_512#58", -1, 395041020L, 194950840L, 124, 988,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_512#59", 1, 86976825L, 38693930L, 126, 1006,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace_tail_512",
  )
  expect_dec_state(dec, "laplace_tail_512", 86976825L, 38693930L, 126, 1006)
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
    dec, 8320, 8192, "laplace_tail_533#1", 0, 48921600L, 144187709L, 7, 52,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_533#2", 0, 17601536L, 144187709L, 8, 64,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_533#3", 0, 12171392L, 144187709L, 9, 68,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_533#4", 0, 295469056L, 404831638L, 12, 95,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_533#5", 0, 62325504L, 404831638L, 15, 113,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_533#6", 0, 18016512L, 404831638L, 16, 128,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_533#7", 0, 1410072576L, 557684339L, 18, 141,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_533#8", 1, 330830016L, 266443763L, 20, 158,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_533#9", 0, 111141056L, 266443763L, 22, 171,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_533#10", 0, 50808384L, 266443763L, 23, 180,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_533#11", 0, 35134784L, 266443763L, 23, 184,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_533#12", 0, 809844736L, 1637610242L, 27, 212,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_533#13", 0, 208800256L, 1637610242L, 29, 227,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_533#14", 0, 75039232L, 1637610242L, 30, 239,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_533#15", 0, 22570752L, 1637610242L, 32, 253,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_533#16", 0, 1381957632L, 468910756L, 34, 270,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_533#17", -1, 337223304L, 1791532L, 36, 286,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_533#18", 2, 1388379392L, 158299831L, 42, 334,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_533#19", 1, 252137919L, 136522165L, 45, 353,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_533#20", -2, 24490002L, 22911L, 48, 380,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_533#21", 10, 48955392L, 32886814L, 63, 500,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_533#22", 0, 20079360L, 32886814L, 64, 510,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_533#23", 0, 1550647296L, 1976573532L, 66, 524,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_533#24", 0, 254403072L, 1976573532L, 69, 545,
  )
  expect_laplace(
    dec, 14208, 2560, "laplace_tail_533#25", 0, 110321792L, 1976573532L, 70, 555,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace_tail_533#26", 0, 59912576L, 1976573532L, 71, 562,
  )
  expect_laplace(
    dec, 17792, 960, "laplace_tail_533#27", 0, 32536448L, 1976573532L, 72, 569,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace_tail_533#28", 0, 722960384L, 1344167011L, 75, 597,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace_tail_533#29", 0, 237221376L, 1344167011L, 77, 610,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace_tail_533#30", 0, 104718720L, 1344167011L, 78, 619,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace_tail_533#31", 0, 31514880L, 1344167011L, 80, 633,
  )
  expect_laplace(
    dec, 9216, 64, "laplace_tail_533#32", 0, 8881408L, 1344167011L, 81, 648,
  )
  expect_laplace(
    dec, 32640, 11456, "laplace_tail_533#33", 0, 8846720L, 1344167011L, 81, 648,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace_tail_533#34", 0, 1127677952L, 509371173L, 82, 656,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_533#35", 1, 203937364L, 106727373L, 85, 676,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_533#36", 1, 37991415L, 30570299L, 87, 695,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_533#37", 0, 13661687L, 30570299L, 89, 707,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_533#38", 0, 9455095L, 30570299L, 89, 711,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_533#39", 0, 231077632L, 1383545849L, 93, 738,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_533#40", 0, 48766976L, 1383545849L, 95, 756,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_533#41", 0, 14102528L, 1383545849L, 97, 771,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_533#42", 0, 1102184448L, 2000419251L, 98, 784,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_533#43", 0, 357348864L, 2000419251L, 100, 797,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_533#44", 0, 120056064L, 2000419251L, 102, 810,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_533#45", 0, 54883968L, 2000419251L, 103, 819,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_533#46", 0, 37956480L, 2000419251L, 103, 823,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_533#47", 0, 875593728L, 1006220128L, 107, 851,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_533#48", 0, 225739008L, 1006220128L, 109, 866,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_533#49", 0, 81125120L, 1006220128L, 110, 878,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_533#50", 0, 24417920L, 1006220128L, 112, 892,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_533#51", 0, 1490616320L, 2041798859L, 114, 909,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_533#52", 0, 623031040L, 2041798859L, 115, 919,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_533#53", 0, 330991360L, 2041798859L, 116, 926,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_533#54", 0, 205577344L, 2041798859L, 117, 932,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_533#55", 0, 16885504L, 2041798859L, 120, 960,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_533#56", 0, 1268219904L, 861981530L, 122, 975,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_533#57", 0, 520168320L, 861981530L, 124, 985,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_533#58", 0, 156463232L, 861981530L, 125, 999,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_533#59", 0, 25693824L, 861981530L, 128, 1020,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace_tail_533",
  )
  expect_dec_state(dec, "laplace_tail_533", 25693824L, 861981530L, 128, 1020)
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
    dec, 3072, 11456, "laplace_tail_645#4", 0, 17338728L, 178914591L, 16, 128,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_645#5", 0, 937191424L, 704978937L, 19, 146,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_645#6", 0, 270925824L, 704978937L, 20, 160,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_645#7", 0, 82547712L, 704978937L, 22, 174,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_645#8", 0, 26766976L, 704978937L, 24, 187,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_645#9", 0, 9010816L, 704978937L, 25, 200,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_645#10", 0, 1058766848L, 85981445L, 27, 209,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_645#11", 1, 157128393L, 73509399L, 29, 231,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_645#12", 2, 15133020L, 4298369L, 33, 258,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_645#13", -2, 338705920L, 338235208L, 36, 286,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_645#14", 0, 121732608L, 338235208L, 38, 298,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_645#15", 0, 36637440L, 338235208L, 39, 311,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_645#16", 0, 8732160L, 338235208L, 41, 328,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_645#17", 0, 936706048L, 688867377L, 43, 338,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_645#18", 0, 497625088L, 688867377L, 44, 345,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_645#19", 0, 309075712L, 688867377L, 44, 351,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_645#20", 0, 25361152L, 688867377L, 48, 380,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_645#21", 0, 1907785728L, 256389435L, 50, 394,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_645#22", 1, 434503323L, 100593L, 52, 411,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_645#23", -17, 868941824L, 509901227L, 67, 531,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_645#24", 1, 191327370L, 166174911L, 69, 548,
  )
  expect_laplace(
    dec, 14208, 2560, "laplace_tail_645#25", 0, 82974090L, 166174911L, 70, 558,
  )
  expect_laplace(
    dec, 17792, 1344, "laplace_tail_645#26", 0, 45054858L, 166174911L, 71, 565,
  )
  expect_laplace(
    dec, 17792, 960, "laplace_tail_645#27", 0, 24477834L, 166174911L, 72, 572,
  )
  expect_laplace(
    dec, 2816, 11392, "laplace_tail_645#28", 0, 538544640L, 1738587967L, 75, 600,
  )
  expect_laplace(
    dec, 10752, 5312, "laplace_tail_645#29", 0, 176711680L, 1738587967L, 77, 613,
  )
  expect_laplace(
    dec, 14464, 3520, "laplace_tail_645#30", 0, 78016512L, 1738587967L, 78, 623,
  )
  expect_laplace(
    dec, 9856, 2560, "laplace_tail_645#31", 0, 23485952L, 1738587967L, 80, 637,
  )
  expect_laplace(
    dec, 9216, 64, "laplace_tail_645#32", 0, 1695416320L, 549404463L, 82, 651,
  )
  expect_laplace(
    dec, 32640, 11456, "laplace_tail_645#33", 0, 1688793600L, 549404463L, 82, 651,
  )
  expect_laplace(
    dec, 16256, 11456, "laplace_tail_645#34", -2, 89313621L, 43259586L, 86, 685,
  )
  expect_laplace(
    dec, 9216, 8128, "laplace_tail_645#35", 1, 16148350L, 11377086L, 89, 705,
  )
  expect_laplace(
    dec, 8320, 8192, "laplace_tail_645#36", -1, 768936960L, 602196537L, 91, 724,
  )
  expect_laplace(
    dec, 11776, 4992, "laplace_tail_645#37", 0, 276338688L, 602196537L, 92, 736,
  )
  expect_laplace(
    dec, 22656, 704, "laplace_tail_645#38", 0, 191064192L, 602196537L, 93, 740,
  )
  expect_laplace(
    dec, 3072, 11456, "laplace_tail_645#39", 0, 17936512L, 602196537L, 96, 768,
  )
  expect_laplace(
    dec, 6912, 8448, "laplace_tail_645#40", 0, 971079680L, 1690974692L, 99, 786,
  )
  expect_laplace(
    dec, 9472, 5632, "laplace_tail_645#41", 0, 280702720L, 1690974692L, 100, 800,
  )
  expect_laplace(
    dec, 9984, 3200, "laplace_tail_645#42", 0, 85534976L, 1690974692L, 102, 814,
  )
  expect_laplace(
    dec, 10624, 4992, "laplace_tail_645#43", 0, 27739136L, 1690974692L, 104, 827,
  )
  expect_laplace(
    dec, 11008, 4736, "laplace_tail_645#44", 0, 9330176L, 1690974692L, 105, 839,
  )
  expect_laplace(
    dec, 14976, 2176, "laplace_tail_645#45", 0, 1094975488L, 1245307947L, 106, 848,
  )
  expect_laplace(
    dec, 22656, 576, "laplace_tail_645#46", 0, 757072896L, 1245307947L, 107, 853,
  )
  expect_laplace(
    dec, 2944, 11392, "laplace_tail_645#47", 0, 68019200L, 1245307947L, 110, 880,
  )
  expect_laplace(
    dec, 8448, 6272, "laplace_tail_645#48", 0, 17555200L, 1245307947L, 112, 896,
  )
  expect_laplace(
    dec, 11776, 4224, "laplace_tail_645#49", 0, 1619066880L, 971254644L, 114, 908,
  )
  expect_laplace(
    dec, 9856, 2880, "laplace_tail_645#50", -1, 465936300L, 305109024L, 116, 922,
  )
  expect_laplace(
    dec, 7808, 5760, "laplace_tail_645#51", -1, 114932177L, 65134961L, 118, 938,
  )
  expect_laplace(
    dec, 13696, 2624, "laplace_tail_645#52", -1, 28041972L, 26291429L, 120, 955,
  )
  expect_laplace(
    dec, 17408, 1216, "laplace_tail_645#53", 0, 14909172L, 26291429L, 121, 962,
  )
  expect_laplace(
    dec, 20352, 640, "laplace_tail_645#54", 0, 9272308L, 26291429L, 121, 967,
  )
  expect_laplace(
    dec, 2688, 11392, "laplace_tail_645#55", 0, 202175488L, 288154988L, 125, 996,
  )
  expect_laplace(
    dec, 9600, 5440, "laplace_tail_645#56", 0, 59252096L, 288154988L, 127, 1010,
  )
  expect_laplace(
    dec, 13440, 3712, "laplace_tail_645#57", 0, 24307072L, 288154988L, 128, 1020,
  )
  expect_laplace(
    dec, 9856, 2688, "laplace_tail_645#58", 0, 1876295680L, 753232976L, 130, 1034,
  )
  expect_laplace(
    dec, 5376, 7744, "laplace_tail_645#59", 1, 413130900L, 11028856L, 132, 1052,
  )
  expect_energy(
    old_e,
    [
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
      -12.0, 0.75, -3.5, -12.0, 0.75, -3.5, -12.0, 0.75, -3.5,
    ],
    "laplace_tail_645",
  )
  expect_dec_state(dec, "laplace_tail_645", 413130900L, 11028856L, 132, 1052)
}
