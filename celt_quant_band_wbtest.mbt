// celt_quant_band_wbtest.mbt
//
// band 级量化解码（RFC 6716 §4.3.4）的白盒测试辅助。
//
// 金标由 tools/gen_quant_band_goldens.py 的独立 Python 参考端算出
// （比对助手复用反归一化的相对容差 expect_dn_close），本文件另提供
// 不依赖金标的锚点：塌缩位图的分块判定、fill/cm 位图变换的推导值。

///|
/// 比对整带重放结果：频谱与 lowband_out 按相对容差，cm/seed/剩余预算
/// 精确比对。`want_lo` 为空数组时跳过 lowband_out。
fn expect_band(
  x : Array[Double],
  want_x : Array[Double],
  lo_out : Array[Double],
  want_lo : Array[Double],
  cm : Int,
  want_cm : Int,
  seed : Int64,
  want_seed : Int64,
  rem : Int,
  want_rem : Int,
  tag : String,
) -> Unit raise {
  expect_dn_close(x, want_x, tag, 0.000000000001)
  if want_lo.length() > 0 {
    expect_dn_close(lo_out, want_lo, "\{tag} lowband_out", 0.000000000001)
  }
  if cm != want_cm {
    @test.fail("\{tag}: cm \{cm} != \{want_cm}")
  }
  if seed != want_seed {
    @test.fail("\{tag}: seed \{seed} != \{want_seed}")
  }
  if rem != want_rem {
    @test.fail("\{tag}: remaining \{rem} != \{want_rem}")
  }
}

///|
/// 塌缩位图的分块判定（手推值）：B≤1 恒 1；B=2 时按 N/2 分块，
/// 块内全零则该位为 0。
test "collapse mask 的分块判定" {
  if celt_extract_collapse_mask([7, -7], 2, 1) != 1 {
    @test.fail("B=1 应恒为 1")
  }
  // 块0 = [0, 5] 非全零 → bit0；块1 = [0, 0] 全零 → bit1 清
  if celt_extract_collapse_mask([0, 5, 0, 0], 4, 2) != 1 {
    @test.fail("后块全零时应只剩 bit0")
  }
  // 块0 全零、块1 非全零 → bit1
  if celt_extract_collapse_mask([0, 0, 3, 0], 4, 2) != 2 {
    @test.fail("前块全零时应只剩 bit1")
  }
  // 两块都非零
  if celt_extract_collapse_mask([-1, 0, 0, 2], 4, 2) != 3 {
    @test.fail("两块都非零应为 3")
  }
}

///|
/// cm 反向变换的小型推导：无 TF 时按最终 B=1 掩蔽；时间升频一级时
/// 先 `cm |= cm>>2` 再按 B=2 掩蔽。
test "cm 位图反向变换推导" {
  let plain = CelTfLayout::{
    recombine: 0,
    time_divide: 0,
    b_start: 1,
    nb_start: 6,
    b_end: 1,
    nb_end: 6,
    deint_n0: 0,
    deint_stride: 0,
    long_blocks: true,
  }
  // 0b11 → 掩蔽到 0b1
  if celt_cm_transform(3, plain) != 1 {
    @test.fail("B=1 掩蔽应取最低位")
  }
  let timed = CelTfLayout::{
    recombine: 0,
    time_divide: 1,
    b_start: 1,
    nb_start: 6,
    b_end: 4,
    nb_end: 3,
    deint_n0: 3,
    deint_stride: 4,
    long_blocks: true,
  }
  // B: 4→2，c=0b1100 → c|=c>>2 → 0b1111 → 掩蔽 0b11
  if celt_cm_transform(0b1100, timed) != 3 {
    @test.fail("时间升频一级的 cm 展开应为 3")
  }
}

///|
/// fill 正向变换的小型推导：recombine 一级按 4 bit 交织表重排；
/// 时间升频一级按当时的 B 展开。
test "fill 位图正向变换推导" {
  let recombined = CelTfLayout::{
    recombine: 1,
    time_divide: 0,
    b_start: 2,
    nb_start: 12,
    b_end: 2,
    nb_end: 12,
    deint_n0: 12,
    deint_stride: 2,
    long_blocks: true,
  }
  // 表[8]|表[0]<<2 = 2|0 = 2；表[3]|表[0]<<2 = 1|0 = 1
  // （f=8 专门区分索引掩码 0xF 与 0x7：表[8]=2 而表[0]=0）
  if celt_fill_transform(0b1000, recombined) != 2 {
    @test.fail("f=8 交织后应为 2（高 4 bit 落低半字节）")
  }
  if celt_fill_transform(0b0011, recombined) != 1 {
    @test.fail("低 2 位位图交织后应为 1")
  }
  let timed = CelTfLayout::{
    recombine: 0,
    time_divide: 1,
    b_start: 1,
    nb_start: 6,
    b_end: 2,
    nb_end: 3,
    deint_n0: 3,
    deint_stride: 2,
    long_blocks: true,
  }
  // f=0b01，B=1：f|=f<<1 → 0b11；B 翻倍后无更多级
  if celt_fill_transform(0b01, timed) != 3 {
    @test.fail("时间段展开应为 3")
  }
}
