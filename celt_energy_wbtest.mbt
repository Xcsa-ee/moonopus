// celt_energy_wbtest.mbt
//
// 能量解码（RFC 6716 §4.3.2）的白盒测试。
//
// 金标由 tools/gen_energy_goldens.py 的独立 Python 参考端算出，本文件提供
// 比对辅助函数，energy_goldens_wbtest.mbt 负责重放每个用例的参数与期望值。
//
// 比对是逐项精确相等：两端的浮点求值顺序刻意与参考实现对齐，末位不一致
// 就说明表达式分组写错了，不该用容差掩盖。

///|
/// 逐项比对能量向量，不一致时报出频带下标与两侧数值。
fn expect_energy(
  actual : Array[Double],
  want : Array[Double],
  tag : String,
) -> Unit raise {
  if actual.length() != want.length() {
    @test.fail("\{tag}: energy length \{actual.length()} != \{want.length()}")
  }
  for i in 0..<want.length() {
    if actual[i] != want[i] {
      @test.fail("\{tag}: band \{i} energy \{actual[i]} != \{want[i]}")
    }
  }
}

///|
/// 比对能量解码后的范围解码器状态。能量解码没有单一「符号」，故只比
/// rng / val / 已用位数。
fn expect_dec_state(
  dec : RangeDecoder,
  tag : String,
  want_rng : Int64,
  want_val : Int64,
  want_tell : Int,
  want_tell_frac : Int,
) -> Unit raise {
  if dec.rng != want_rng {
    @test.fail("\{tag}: rng \{dec.rng} != \{want_rng}")
  }
  if dec.val != want_val {
    @test.fail("\{tag}: val \{dec.val} != \{want_val}")
  }
  if dec.tell() != want_tell {
    @test.fail("\{tag}: ec_tell \{dec.tell()} != \{want_tell}")
  }
  if dec.tell_frac() != want_tell_frac {
    @test.fail("\{tag}: ec_tell_frac \{dec.tell_frac()} != \{want_tell_frac}")
  }
}

///|
/// 解一个 Laplace 符号并比对符号与解码器状态。
fn expect_laplace(
  dec : RangeDecoder,
  fs : Int,
  decay : Int,
  tag : String,
  want_sym : Int,
  want_rng : Int64,
  want_val : Int64,
  want_tell : Int,
  want_tell_frac : Int,
) -> Unit raise {
  let got = cel_laplace_decode(dec, fs, decay)
  if got != want_sym {
    @test.fail("\{tag}: laplace \{got} != \{want_sym}")
  }
  expect_dec_state(dec, tag, want_rng, want_val, want_tell, want_tell_frac)
}

///|
/// Laplace 直测：真实表里的 (fs, decay) 参数轮转 40 个符号，覆盖
/// 零、衰减链与尾部三条路径（尾部另见 laplace_tail_* 用例）。
test "金标：Laplace 解码" {
  let dec = RangeDecoder::new(ENER_LAPLACE_BITS)
  play_laplace(dec)
}

///|
/// 粗能量帧间预测：时间方向乘 coef、频率方向由 prev 累积，
/// 初始能量含低于 -9 的值以覆盖解码前的下限钳位。
test "金标：粗能量 inter 960" {
  let dec = RangeDecoder::new(ENER_COARSE_INTER960_BITS)
  play_coarse_inter960(dec)
}

///|
test "金标：粗能量 intra 960" {
  let dec = RangeDecoder::new(ENER_COARSE_INTRA960_BITS)
  play_coarse_intra960(dec)
}

///|
test "金标：粗能量 inter 120" {
  let dec = RangeDecoder::new(ENER_COARSE_INTER120_BITS)
  play_coarse_inter120(dec)
}

///|
test "金标：粗能量 intra 240" {
  let dec = RangeDecoder::new(ENER_COARSE_INTRA240_BITS)
  play_coarse_intra240(dec)
}

///|
/// 只解 5..17 带：期望向量里窗外频带保持初始值，验证窗口边界。
test "金标：粗能量带窗" {
  let dec = RangeDecoder::new(ENER_COARSE_WINDOW_BITS)
  play_coarse_window(dec)
}

///|
/// 短载荷让 budget-tell 迅速跌破 15，自然走出 icdf / bit_logp / 无比特
/// 三条降级路径（budget 恒等于载荷长度，与参考实现语义一致）。
test "金标：粗能量降级分支 A" {
  let dec = RangeDecoder::new(ENER_COARSE_SHORT_100_BITS)
  play_coarse_short_100(dec)
}

///|
test "金标：粗能量降级分支 B" {
  let dec = RangeDecoder::new(ENER_COARSE_SHORT_102_BITS)
  play_coarse_short_102(dec)
}

///|
test "金标：粗能量降级分支 C" {
  let dec = RangeDecoder::new(ENER_COARSE_SHORT_103_BITS)
  play_coarse_short_103(dec)
}

///|
test "金标：粗能量降级分支 D" {
  let dec = RangeDecoder::new(ENER_COARSE_SHORT_104_BITS)
  play_coarse_short_104(dec)
}

///|
/// 细能量：不同位数的修正量，含 extra=0 的跳过与 extra=8 的满格。
test "金标：细能量" {
  let dec = RangeDecoder::new(ENER_FINE_BITS)
  play_fine(dec)
}

///|
test "金标：能量收尾" {
  let dec = RangeDecoder::new(ENER_FINALISE_BITS)
  play_finalise(dec)
}

///|
/// 只剩 5 位：优先级 0 的带补完就停，验证 bits_left 的截断。
test "金标：能量收尾位不足" {
  let dec = RangeDecoder::new(ENER_FINALISE_SHORT_BITS)
  play_finalise_short(dec)
}

///|
/// 粗 → 细 → 收尾串成一帧，验证三步在同一个解码器状态上衔接。
test "金标：能量三步链路" {
  let dec = RangeDecoder::new(ENER_CHAIN_BITS)
  play_chain(dec)
}

///|
/// 短载荷下细能量位数超过剩余比特，按参考实现的判据整带跳过。
test "金标：细能量预算跳过" {
  let dec = RangeDecoder::new(ENER_FINE_EXHAUSTED_700_BITS)
  play_fine_exhausted_700(dec)
}

///|
/// Laplace 衰减链走到尾部：此后每格只剩 LAPLACE_MINP 的概率质量。
test "金标：Laplace 尾部 A" {
  let dec = RangeDecoder::new(ENER_LAPLACE_TAIL_512_BITS)
  play_laplace_tail_512(dec)
}

///|
test "金标：Laplace 尾部 B" {
  let dec = RangeDecoder::new(ENER_LAPLACE_TAIL_533_BITS)
  play_laplace_tail_533(dec)
}

///|
test "金标：Laplace 尾部 C" {
  let dec = RangeDecoder::new(ENER_LAPLACE_TAIL_645_BITS)
  play_laplace_tail_645(dec)
}
