// 由 tools/gen_quant_band_goldens.py 生成，请勿手改。
//
// band 级量化解码（RFC 6716 §4.3.4）金标：载荷、折叠源与期望频谱
// 由本脚本内的独立 Python 参考端算出（四段结构：n=1 符号、TF 前段、
// 递归分割 + 叶上谱应用、频序还原与 cm 变换），MoonBit 端重放同一
// 载荷后整带按相对容差比对，cm/seed/剩余预算与解码器状态精确比对。

///|

///|
const QB_QB0_BITS : Bytes = b"\x40\x9f\x2a\x8f\x9d\x48\xe2\x9b\x70\x5e\x6d\x6c\xa0\xd9\xd7\x91\xba\xc4\x70\xc1\xc7\x74\xa9\xa5\x45\x44\x26\xda\xe0\x3e\x29\x23"

///|
fn play_qb0(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(1, 0.0)
  let lowband : Array[Double] = []
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [-1.0]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 0, 0, 1, 8, 1, 0, 15, 1.0, 0, 424242L, 100, lo_out,
  )
  expect_band(x, want_x, lo_out, want_lo, cm, 1, seed2, 424242L, rem, 92, "qb0")
  expect_dec_state(dec, "qb0", 2147483648L, 1605397176L, 2, 16)
}

///|
test "金标：quant_band · n=1 符号位（预算充足）" {
  let dec = RangeDecoder::new(QB_QB0_BITS)
  play_qb0(dec)
}

///|
const QB_QB1_BITS : Bytes = b"\x95\xe3\x4a\xb4\x7c\x90\xb7\xaa\xf3\x91\xc4\xbc\x6c\x2d\x0e\x0c\xe0\xe2\x5b\x85\xd2\xe6\xd9\x07\xae\xfb\x65\xab\x85\xb7\x54\xbf"

///|
fn play_qb1(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(1, 0.0)
  let lowband : Array[Double] = []
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [1.0]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 0, 0, 1, 8, 1, 0, 15, 1.0, 0, 424243L, 3, lo_out,
  )
  expect_band(x, want_x, lo_out, want_lo, cm, 1, seed2, 424243L, rem, 3, "qb1")
  expect_dec_state(dec, "qb1", 2147483648L, 890133157L, 1, 8)
}

///|
test "金标：quant_band · n=1 符号位（预算不足不读）" {
  let dec = RangeDecoder::new(QB_QB1_BITS)
  play_qb1(dec)
}

///|
const QB_QB2_BITS : Bytes = b"\x64\xcc\x01\x1f\xc5\xe8\x19\x01\x52\xa6\x05\xaf\xdc\x3f\xcc\xe0\x63\x39\x36\xf1\xe0\xdc\xbf\xa1\x16\x22\xa9\x75\xd4\x7b\x00\xdf\x18\x29\x1d\x1e\x54\x2e\x1d\x35\xe0\x1d\xbb\x59\xbb\x4e\x0c\xad\x33\xa6\x1d\x2d\x47\x0b\xa5\x77\xe2\x97\xd3\x47\x35\x71\xbb\x72\xb3\x18\x25\x96\x85\x25\x37\x9b\x1a\xa6\x43\xe2\xac\xec\xc2\x17\xb1\xa9\x93\xfa\x9d\xbe\x15\x44\xb8\x5b\x7b\x45\x52\x3c\x5a\xa0\xfd\x62\x67\xf9\x12\xba\x4d\x75\xde\x00\xc6\xe7\x89\x45\xb5\x06\x7d\xa8\xb3\xe8\xe5\xe7\x7c\xdd\xec\xc2\x4d\xe8\xe6\xd2\x7f\x86"

///|
fn play_qb2(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(24, 0.0)
  let lowband : Array[Double] = []
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [
    0.0, 0.0, 0.35355339, -0.35355339, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  ]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 15, 2, 24, 60, 4, 1, 15, 0.5, 0, 424244L, 800, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 12, seed2, 424244L, rem, 755, "qb2",
  )
  expect_dec_state(dec, "qb2", 44739242L, 4500014L, 7, 53)
}

///|
test "金标：quant_band · recombine 变换（tf=+1, B=4）" {
  let dec = RangeDecoder::new(QB_QB2_BITS)
  play_qb2(dec)
}

///|
const QB_QB3_BITS : Bytes = b"\xee\x7f\x88\x1e\x1b\xb2\xb5\x1c\x1b\x7e\x4a\x04\x33\x44\x1e\x17\x01\xb7\xef\x05\xc6\x17\x3e\x6d\xf7\x97\x46\x43\x6e\xe1\x78\x0c\xa1\x99\x41\x1b\x3c\x3f\x1d\xe2\xe6\xac\x3c\x49\x41\xa7\x19\xa4\x0d\xb1\xf8\x06\xf6\xfb\x43\x2f\xc0\xf0\x21\x47\x11\x49\x79\xbc\xe1\x19\xc3\x9c\x24\x85\x62\xa0\x64\x87\x7d\x3c\x62\xfb\x7d\xbd\x28\xe3\x39\xc8\xee\x4c\xe2\x54\x2f\xf3\x11\x88\xe8\xe3\xa6\xd6\xc7\x3d\xc9\x8c\x0d\x12\xd5\xad\x72\x66\x4d\x0d\xf3\x09\x30\x21\x38\x81\x9d\xaf\x63\xaf\xfb\x41\x45\x9d\x05\xac\x0b\xb2\x06\x82"

///|
fn play_qb3(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(48, 0.0)
  let lowband : Array[Double] = []
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [
    0.0, 0.0, 0.0, 0.0, 0.0, -0.31622776548619774, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
    0.0, -0.31622776548619774, 0.0, 0.0, -0.31622776548619774, 0.31622776548619774,
    0.0, 0.0, 0.0, 0.0, 0.31622776548619774, 0.0, -0.31622776548619774, -0.31622776548619774,
    0.0, 0.0, 0.0, 0.0, -0.31622776548619774, 0.0, 0.0, 0.0, 0.0, 0.0, -0.31622776548619774,
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.31622776548619774, 0.0, 0.0, 0.0,
  ]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 15, 3, 48, 200, 8, -1, 15, 1.0, 0, 424245L, 3000, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 115, seed2, 424245L, rem, 2791, "qb3",
  )
  expect_dec_state(dec, "qb3", 16519104L, 14663152L, 28, 217)
}

///|
test "金标：quant_band · 时间升频与重排（tf=-1, B=8）" {
  let dec = RangeDecoder::new(QB_QB3_BITS)
  play_qb3(dec)
}

///|
const QB_QB4_BITS : Bytes = b"\xfd\xf7\x69\x29\x0f\x26\x13\xb6\x14\x42\xcd\xfd\x3e\xae\x07\xb2\x13\x8a\xbb\xad\x31\x8f\x5a\xbe\xaf\x48\x12\xf3\x01\x26\x92\xee\x31\x35\xc5\xb2\x60\xbe\x5a\xe3\x93\x88\x29\x1c\x2f\xd8\x9a\xf5\xcd\x25\xe7\x90\x1d\x29\x12\x86\x72\x9c\xf3\x94\xd4\x32\xea\xbd"

///|
fn play_qb4(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(12, 0.0)
  let lowband : Array[Double] = []
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [
    -0.9533614417510624, 0.0, -0.29820594185903637, 0.0, -0.04607889892675615, 0.0,
    -0.007116970240052679, 0.0, -0.0011196747162811342, 0.0, -8.80859277039078e-05,
    0.0,
  ]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 15, 1, 12, 40, 2, 0, 15, 1.0, 1, 424246L, 800, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 1, seed2, 424246L, rem, 763, "qb4",
  )
  expect_dec_state(dec, "qb4", 89478485L, 17058667L, 6, 45)
}

///|
test "金标：quant_band · 仅重排（B=2, tf=0）" {
  let dec = RangeDecoder::new(QB_QB4_BITS)
  play_qb4(dec)
}

///|
const QB_QB5_BITS : Bytes = b"\x1f\xcb\xab\xfd\x6f\x27\x68\x0d\xb3\xd8\x1a\xe7\x7a\x16\xd5\xe3\xe8\x62\xce\x57\xa5\x85\x82\x40\x28\x90\xa0\xe0\xf6\xf0\x35\x9a\x9f\x8d\x29\xf2\x35\x74\x5a\x51\xb0\x9c\xe8\x11\xc5\x6e\xab\x3f\x74\xb3\xbb\x5c\x9f\x58\xe7\x22\x26\xd0\xe5\xec\x05\xf9\xc6\xe0"

///|
fn play_qb5(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(4, 0.0)
  let lowband : Array[Double] = [
    -0.29612488020304006, 0.39428096410812596, -0.18433505641380687, 0.8547519853738397,
  ]
  let lo_out : Array[Double] = Array::make(4, 0.0)
  let want_lo : Array[Double] = [
    -0.5946108085012423, 0.7891395174742803, -0.3575792898091105, 1.7017149760972219,
  ]
  let want_x : Array[Double] = [
    -0.29730540425062113, 0.3945697587371402, -0.17878964490455526, 0.8508574880486109,
  ]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 8, 1, 4, 8, 2, 0, 1, 1.0, 0, 424247L, 500, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 1, seed2, 3221462107L, rem, 500, "qb5",
  )
  expect_dec_state(dec, "qb5", 2147483648L, 1880762881L, 1, 8)
}

///|
test "金标：quant_band · 折叠填充与 lowband_out" {
  let dec = RangeDecoder::new(QB_QB5_BITS)
  play_qb5(dec)
}

///|
const QB_QB6_BITS : Bytes = b"\x88\x66\xff\x64\x8b\x39\x96\x87\x63\x3e\x62\x8a\x99\xeb\xcd\xeb\xf6\xbd\xa2\xd1\xee\xca\x89\x48\x2d\x59\x8d\xb0\x55\x10\xc8\xdc\x91\xbb\x44\x8d\x2d\x26\xd9\x89\x3a\x62\x79\x4a\x37\x8a\x8a\x41\xf7\x69\xab\xa8\xba\x66\x0d\x18\x72\x80\xcf\xdf\xcd\x86\x43\x34"

///|
fn play_qb6(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(48, 0.0)
  let lowband : Array[Double] = [
    -0.6546811797667247, 0.18489544092703225, -0.8218283258420442, -0.22832865686352988,
    0.3771317968603354, -0.5261235574294176, -0.9462033419938425, -0.9323417213968044,
    -0.3189483686462071, 0.3187010043751315, -0.9904097308117752, 0.16900539883964427,
    -0.8277370001486843, -0.3220951236626295, 0.020875825844847817, 0.12640812637374021,
    0.6265825607683153, 0.060363103114785766, 0.8894442228625057, 0.850522418274468,
    -0.866528504443423, 0.24948581911888001, -0.763261523835612, -0.19766177482149816,
    0.5034028506493595, -0.3098876621159341, -0.5649890088933716, 0.8148578123091748,
    -0.6417932519247165, -0.14764799747893287, -0.9911134461520772, -0.005261249479855623,
    -0.704754358610155, -0.026720493713130677, 0.7109594225805551, 0.25891502921766185,
    -0.8755811199605295, -0.11296370630341812, 0.39893349478856277, -0.2045304551054783,
    -0.8876885071454459, 0.5669670881422766, -0.5552414029066821, 0.6259680938520338,
    -0.4921440844332736, 0.40662346288546214, 0.7228151524075266, -0.1270985788899932,
  ]
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [
    -0.16104367005313186, 0.045869095768185465, -0.20388021464484313, -0.0552735947824715,
    0.09492980340012078, -0.13052140020668349, -0.2333648582376544, -0.23129651814563723,
    -0.07775464795178888, 0.07906374985670364, -0.24433163530954344, 0.04192707394973218,
    -0.20534604606975781, -0.08127623562683983, 0.00517890138402698, 0.03272995685312456,
    0.15544339731934817, 0.016345423618080862, 0.22065445223736063, 0.21236914987905836,
    -0.2135990233658412, 0.06189275880785118, -0.1907213563814729, -0.04903618409160704,
    0.12488481841759203, -0.07550685637033755, -0.14016319075779507, 0.2035214291437362,
    -0.1592168848961922, -0.03799917104760802, -0.24587668225214393, 6.525089561389141e-05,
    -0.17483635619167448, -0.005258385663047552, 0.17500524799334471, 0.06423196922250957,
    -0.21584480771847206, -0.028024179702762497, 0.0975974596114987, -0.0507401750184102,
    -0.2202188920528382, 0.1392834468222681, -0.13774499228696072, 0.1566614279338878,
    -0.12072126105076499, 0.10087566500920454, 0.17794643250340353, -0.03153077684271352,
  ]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 15, 3, 48, 8, 1, -1, 15, 1.0, 0, 424254L, 500, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 1, seed2, 1744832686L, rem, 500, "qb6",
  )
  expect_dec_state(dec, "qb6", 2147483648L, 1003257933L, 1, 8)
}

///|
test "金标：quant_band · 折叠源 × TF 前向变换（tf=-1）" {
  let dec = RangeDecoder::new(QB_QB6_BITS)
  play_qb6(dec)
}

///|
const QB_QB7_BITS : Bytes = b"\x3c\x94\xa6\x72\xb0\xf0\x32\xa6\x9b\xbb\x1f\xed\xcb\x8f\xaa\x42\xbc\x42\x18\x09\xe5\xb2\xe1\x3d\x7b\x03\xf0\x84\x46\xcc\x83\x3e\x93\xf4\x54\x27\x21\x99\x5f\x24\xc7\x58\x13\xae\xd0\xce\xa7\xb4\x3d\x5e\x81\xc9\x69\xd7\x4f\x1e\xda\xc3\x02\xb4\x74\x3d\x9f\x14"

///|
fn play_qb7(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(4, 0.0)
  let lowband : Array[Double] = []
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [
    -0.7770554823466586, 0.3808449892292239, -0.1470698229300173, -0.47907446051457125,
  ]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 8, 1, 4, 8, 1, 0, 15, 1.0, 0, 424248L, 500, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 1, seed2, 3380446188L, rem, 500, "qb7",
  )
  expect_dec_state(dec, "qb7", 2147483648L, 1639296198L, 1, 8)
}

///|
test "金标：quant_band · 噪声填充（无折叠源）" {
  let dec = RangeDecoder::new(QB_QB7_BITS)
  play_qb7(dec)
}

///|
const QB_QB8_BITS : Bytes = b"\xb0\xc1\xf8\xde\x68\x2e\xb9\xe4\xee\x9b\x2f\xa3\xf4\x0e\x63\x30\xb8\xee\x48\xd7\x72\x97\x1b\x46\xe8\x23\xc0\x39\xcd\x0d\x36\xa4"

///|
fn play_qb8(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(4, 0.0)
  let lowband : Array[Double] = [
    0.5719677643097185, -0.7702988217034621, 0.5304044695071588, 0.9706159820880553,
  ]
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [0.0, 0.0, 0.0, 0.0]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 8, 1, 4, 8, 1, 0, 0, 1.0, 0, 424249L, 500, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 0, seed2, 424249L, rem, 500, "qb8",
  )
  expect_dec_state(dec, "qb8", 2147483648L, 664732560L, 1, 8)
}

///|
test "金标：quant_band · fill=0 清零" {
  let dec = RangeDecoder::new(QB_QB8_BITS)
  play_qb8(dec)
}

///|
const QB_QB9_BITS : Bytes = b"\x86\xf9\x0c\x51\xd6\x2a\x23\xbf\x29\x26\xa0\x4a\x51\xed\xd8\x3b\xf9\x28\x1f\xc4\x56\xf6\xaa\x5e\x23\x3b\xbe\x41\xa3\x48\x28\xed\x67\xa3\xb0\x15\xa5\xf9\xb8\x70\x02\x8e\xfb\x44\xa2\x76\xda\x89\x3c\xe2\x70\x6c\xc3\x61\xed\x27\xec\x54\x00\x3d\x8a\x23\x1d\x20"

///|
fn play_qb9(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(18, 0.0)
  let lowband : Array[Double] = []
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [
    0.4078642268848174, -0.16379961969068613, -0.40930649640106664, -0.08623328455640014,
    -0.2628366227213692, 0.037830582012733954, 0.22046599781554918, -0.014265481061378302,
    0.24469635410765586, -0.06624996078706287, -0.26042933849259076, 0.012457474550487443,
    -0.2815887403774227, 0.08055446044095521, 0.2783075014036724, 0.01803075939601325,
    0.24768170459367403, -0.3941748775343654,
  ]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 19, 0, 18, 30, 1, 0, 0, 1.0, 3, 424250L, 800, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 1, seed2, 424250L, rem, 758, "qb9",
  )
  expect_dec_state(dec, "qb9", 59652323L, 1159876L, 7, 50)
}

///|
test "金标：quant_band · 展宽旋转（spread=3, 长块）" {
  let dec = RangeDecoder::new(QB_QB9_BITS)
  play_qb9(dec)
}

///|
const QB_QB10_BITS : Bytes = b"\xec\xae\x38\xcf\x92\xe3\x19\x89\x4a\x98\x0c\x04\xfa\x70\x6e\xd1\x04\x6a\xf9\x4f\xd3\x18\xcf\xbb\xcf\x03\x65\x62\xa0\xf1\xdc\x29\x9a\x07\xbf\xf8\x00\xe1\xaa\x10\xb9\x9d\x31\x00\xdc\x24\xd3\x5f\x6e\x13\xaa\xdf\x9d\x7d\x7d\xad\xd2\x02\x44\x25\x93\x54\xd7\x9d"

///|
fn play_qb10(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(6, 0.0)
  let lowband : Array[Double] = []
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [
    -0.4683372148810973, 0.6001089188554387, -0.015268257891233506, -0.13874199562033926,
    0.4899119271187099, -0.4012896476195937,
  ]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 15, 0, 6, 40, 1, 0, 15, 1.0, 0, 424251L, 6, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 1, seed2, 3027435561L, rem, 6, "qb10",
  )
  expect_dec_state(dec, "qb10", 2147483648L, 162063256L, 1, 8)
}

///|
test "金标：quant_band · 预算逼退脉冲" {
  let dec = RangeDecoder::new(QB_QB10_BITS)
  play_qb10(dec)
}

///|
const QB_QB11_BITS : Bytes = b"\xb8\xbf\x1b\x48\xdf\xdb\xd6\xc9\xc3\x5b\x7b\x75\x26\xf7\xcb\x80\xf8\x50\x48\xdb\x0f\x16\x07\x72\x45\xc6\x57\xdf\x3b\x9f\xa9\x66\x3c\xe9\xaa\x8d\x24\xd1\xe0\xf1\xe6\x79\x76\x58\xf6\x79\x84\x92\x2f\x9d\xe9\x16\x8a\xef\x23\x79\x95\x15\x8f\x86\xd5\x36\xda\xbb\xf8\x56\x82\xb8\x88\x56\x7a\xfb\x1b\xed\x8a\x9d\xa2\x74\x87\xd7\x03\xa1\xad\x8b\x0e\x94\x17\xb3\x4a\x82\xca\x31\xeb\x62\x11\x6e\x17\x0b\x53\x07\x51\xaa\x90\x5b\x1e\xd6\x1e\x62\x18\xc2\x42\xc1\x2a\x74\x59\x88\x23\xce\x33\x9d\x19\xcf\x85\xf5\x5b\x20\xf8\x0b\x02\xa1\x9b\x19\x8b\xb2\xd5\xe9\xe5\xff\xc2\x9d\x0b\x01\x6f\x20\x3b\xbf\x70\x4a\xe6\xee\xb7\x58\xd9\xbc\x72\x5f\xec\x1a\x3d\xbe\x41\x4d\x88\x72\x15\xaa\x85\x71\xa5\x89\x6b\xc7\xef\x91\x0f\xb8\xce\x73\x19\xd2\x0b\xbc\xfb\x29\x8d\xa0\xcd\xd8\x93\x31\xa1\x01\x6d\x24\x71\x46\x8e\x6b\x41\xcc\xe1\xd7\x3c\xa8\xb7\xa4\x3f\x8f\x1c\x3b\x26\x31\x04\x7c\xff\xe9\x6f\x73\x99\xc6\x26\xb2\x71\x3e\x82\x4e\xa3\x95\xf5\x04\x5d\x13\x96\x84\xf5\x7c\x99\x99\x23\xf9\xa9\xd3\x1c\x47\xb1\x96\x15\xca\x79\xda\x46\x6f\x93\x57\x35\x59"

///|
fn play_qb11(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(48, 0.0)
  let lowband : Array[Double] = []
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [
    -0.036531157820275204, -0.019229825157279105, -0.03950654624002613, -0.013062957917885996,
    0.031068656669566694, -0.024788031098805004, 0.001278342668221954, -0.01852367693279312,
    -0.003921070299642339, 0.021944977775941156, 0.01013702019091698, 0.02113178824414232,
    -0.005627278733176225, -0.004141330648512758, -0.0033617076623888758, 0.012878012267228307,
    -0.0008560090507039993, -0.012673479131219387, 0.0348123342891799, -0.07523598863345561,
    -0.05142479497860828, -0.03171134162715327, 0.033446420854715796, 0.010336642206755432,
    0.048302663413712074, 0.020559595196605652, -0.06376659301942063, -0.045003375110701335,
    -0.009022816904113553, 0.025075681334745026, -0.008110073027417434, 0.06412615882144018,
    0.008826777155421765, 0.05341331817127017, -0.048132340385975095, 0.011467266048069302,
    -0.054299905952019493, -0.07378625518019104, -0.05152714479702276, -0.010243812044849069,
    0.004236162875689464, 0.07136008916956889, -0.046323790708498604, 0.05086799858180666,
    -0.011055311691779314, 0.030554711148138534, -0.026349623265375852, -0.04581511072268053,
  ]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 15, 3, 48, 1200, 1, 0, 15, 0.25, 2, 424252L, 60, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 1, seed2, 3961491244L, rem, -493, "qb11",
  )
  expect_dec_state(dec, "qb11", 65398784L, 37115461L, 71, 561)
}

///|
test "金标：quant_band · 深分割 + 紧预算" {
  let dec = RangeDecoder::new(QB_QB11_BITS)
  play_qb11(dec)
}

///|
const QB_QB12_BITS : Bytes = b"\x7f\x5f\x47\x22\x8a\xc4\x97\x24\x03\x92\x83\xea\x70\x66\x38\xa0\x87\xd5\xd4\xf2\xe6\x0b\x55\x7c\x05\x4c\x81\x58\x51\xf3\xd2\x55\x9b\x6e\xdb\x79\x84\xa8\x71\x9a\x11\x89\xc5\x2d\x28\xcd\x73\x7d\xa2\xfb\xc9\x09\x1a\x35\xb8\x3c\xc4\x97\xcf\x8b\x71\xc8\x41\x58"

///|
fn play_qb12(dec : RangeDecoder) -> Unit raise {
  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立
  // Python 参考端算出，重放同一载荷后整带比对。
  let x : Array[Double] = Array::make(22, 0.0)
  let lowband : Array[Double] = []
  let lo_out : Array[Double] = []
  let want_lo : Array[Double] = []
  let want_x : Array[Double] = [
    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3333333333333333, -0.3333333333333333,
    0.0, 0.3333333333333333, 0.0, -0.6666666666666666, 0.0, 0.0, -0.3333333333333333,
    0.3333333333333333, 0.0, 0.0,
  ]
  let (cm, seed2, rem) = celt_quant_band(
    dec, x, lowband, 20, 0, 22, 200, 1, 0, 0, 1.0, 0, 424253L, 3000, lo_out,
  )
  expect_band(
    x, want_x, lo_out, want_lo, cm, 1, seed2, 424253L, rem, 2792, "qb12",
  )
  expect_dec_state(dec, "qb12", 8555711L, 988780L, 27, 216)
}

///|
test "金标：quant_band · 大带纯叶（q>0, cm 非零）" {
  let dec = RangeDecoder::new(QB_QB12_BITS)
  play_qb12(dec)
}
