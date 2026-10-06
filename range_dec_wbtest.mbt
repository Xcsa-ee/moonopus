// Whitebox tests for range_dec.mbt（RFC 6716 §4.1）。
//
// 金标由 tools/gen_range_goldens.py 的独立 Python 参考解码端算出，本文件
// 提供逐步比对的断言方法并重放每个用例。失败时 MoonBit 会报出生成文件
// 内 play_* 的具体行号，可直接定位到出错的那一步。

///|
/// 比对一次操作后的完整状态：符号、rng、val、ec_tell、ec_tell_frac。
fn RangeDecoder::check_state(
  self : RangeDecoder,
  tag : String,
  want_sym : Int,
  want_rng : Int64,
  want_val : Int64,
  want_tell : Int,
  want_tell_frac : Int,
  got_sym : Int,
) -> Unit raise {
  if got_sym != want_sym {
    @test.fail("\{tag}: symbol \{got_sym} != \{want_sym}")
  }
  if self.rng != want_rng {
    @test.fail("\{tag}: rng \{self.rng} != \{want_rng}")
  }
  if self.val != want_val {
    @test.fail("\{tag}: val \{self.val} != \{want_val}")
  }
  if self.tell() != want_tell {
    @test.fail("\{tag}: ec_tell \{self.tell()} != \{want_tell}")
  }
  if self.tell_frac() != want_tell_frac {
    @test.fail("\{tag}: ec_tell_frac \{self.tell_frac()} != \{want_tell_frac}")
  }
}

///|
fn RangeDecoder::expect_ctx(
  self : RangeDecoder,
  freqs : Array[Int],
  want_sym : Int,
  want_rng : Int64,
  want_val : Int64,
  want_tell : Int,
  want_tell_frac : Int,
) -> Unit raise {
  let got = self.decode_ctx(freqs)
  self.check_state(
    "decode_ctx", want_sym, want_rng, want_val, want_tell, want_tell_frac, got,
  )
}

///|
fn RangeDecoder::expect_bit(
  self : RangeDecoder,
  logp : Int,
  want_sym : Int,
  want_rng : Int64,
  want_val : Int64,
  want_tell : Int,
  want_tell_frac : Int,
) -> Unit raise {
  let got = self.decode_bit_logp(logp)
  self.check_state(
    "decode_bit_logp", want_sym, want_rng, want_val, want_tell, want_tell_frac, got,
  )
}

///|
fn RangeDecoder::expect_bin(
  self : RangeDecoder,
  ftb : Int,
  want_sym : Int,
  want_rng : Int64,
  want_val : Int64,
  want_tell : Int,
  want_tell_frac : Int,
) -> Unit raise {
  let got = self.decode_bin(ftb)
  self.check_state(
    "decode_bin", want_sym, want_rng, want_val, want_tell, want_tell_frac, got,
  )
}

///|
fn RangeDecoder::expect_icdf(
  self : RangeDecoder,
  ftb : Int,
  want_sym : Int,
  want_rng : Int64,
  want_val : Int64,
  want_tell : Int,
  want_tell_frac : Int,
) -> Unit raise {
  let got = self.decode_icdf([200, 150, 100, 40, 0], ftb)
  self.check_state(
    "decode_icdf", want_sym, want_rng, want_val, want_tell, want_tell_frac, got,
  )
}

///|
fn RangeDecoder::expect_uint(
  self : RangeDecoder,
  ft : Int,
  want_sym : Int,
  want_rng : Int64,
  want_val : Int64,
  want_tell : Int,
  want_tell_frac : Int,
) -> Unit raise {
  let got = self.decode_uint(ft)
  self.check_state(
    "decode_uint", want_sym, want_rng, want_val, want_tell, want_tell_frac, got,
  )
}

///|
/// §4.1.1 初始化语义：rng 归一化到 2**31、offs 消费 4 字节、
/// ec_tell 报告 1 位已用（规范明文），且 ec_tell == ceil(ec_tell_frac/8)。
test "范围解码器初始化状态" {
  let dec = RangeDecoder::new(b"\x5a\xa5\x3c\xff\x11\x22\x33\x44")
  @test.assert_eq(dec.rng, 2147483648L) // 2**31
  @test.assert_eq(dec.offs, 4)
  @test.assert_eq(dec.tell(), 1)
  @test.assert_eq(dec.tell_frac(), 8)
  // §4.1.6：ec_tell() 保证返回 ceil(ec_tell_frac() / 8.0)
  let tf = dec.tell_frac()
  @test.assert_eq(dec.tell(), (tf + 7) / 8)
}

///|
/// 空输入：首字节按 0 处理（§4.1.1），不越界。
test "空输入初始化" {
  let dec = RangeDecoder::new(b"")
  @test.assert_eq(dec.rng, 2147483648L)
  @test.assert_eq(dec.tell(), 1)
}

///|
/// 均匀 4 符号上下文（ft=16）：符号、rng、val、位用量逐步比对。
test "金标：均匀上下文 uniform16" {
  let dec = RangeDecoder::new(RANGE_UNIFORM16_BITS)
  play_uniform16(dec)
}

///|
test "金标：二元符号 bitlogp" {
  let dec = RangeDecoder::new(RANGE_BITLOGP_BITS)
  play_bitlogp(dec)
}

///|
test "金标：icdf 表 icdf8" {
  let dec = RangeDecoder::new(RANGE_ICDF8_BITS)
  play_icdf8(dec)
}

///|
/// ec_dec_uint 的两条分支：ftb<=8（纯范围码）与 ftb>8（范围码 + raw bits）。
test "金标：均匀整数 uint" {
  let dec = RangeDecoder::new(RANGE_UINT_BITS)
  play_uint(dec)
}

///|
/// 混合序列：bit_logp、icdf、uint、bin、ctx 交替，覆盖状态在不同解码
/// 路径间切换。
test "金标：混合操作 mixed" {
  let dec = RangeDecoder::new(RANGE_MIXED_BITS)
  play_mixed(dec)
}

///|
/// 300 步随机操作：压测重归一化、补零读取与四种解码路径。
test "金标：随机大量操作 random300" {
  let dec = RangeDecoder::new(RANGE_RANDOM300_BITS)
  play_random300(dec)
}

///|
/// 2 字节短流：解码很快耗尽输入，后续 renormalization 全部补 0（§4.1.2.1）。
test "金标：短流补零 short" {
  let dec = RangeDecoder::new(RANGE_SHORT_BITS)
  play_short(dec)
}

///|
/// 256 字节长流：raw bits（uint ftb>8 读取）与范围数据前向消费重叠，
/// 两者独立指针必须互不干扰（§4.1.4）。
test "金标：长流与 raw bits 重叠 long" {
  let dec = RangeDecoder::new(RANGE_LONG_BITS)
  play_long(dec)
}
