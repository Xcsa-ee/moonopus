// celt_quant_all_bands_wbtest.mbt
//
// quant_all_bands 主循环（RFC 6716 §4.3.4）的白盒测试辅助。
//
// 金标由 tools/gen_quant_all_bands_goldens.py 的独立 Python 参考端算出
// （比对助手复用反归一化的相对容差 expect_dn_close），本文件另提供
// 不依赖金标的边界：空带窗不消费熵、不改 seed、不写 masks。

///|
/// 比对整循环重放结果：频谱按相对容差，masks 与 seed 精确比对。
fn expect_qab(
  x : Array[Double],
  want_x : Array[Double],
  masks : Array[Int],
  want_masks : Array[Int],
  seed : Int64,
  want_seed : Int64,
  tag : String,
) -> Unit raise {
  expect_dn_close(x, want_x, tag, 0.000000000001)
  if masks.length() != want_masks.length() {
    @test.fail(
      "\{tag}: masks 长度 \{masks.length()} != \{want_masks.length()}",
    )
  }
  for i in 0..<want_masks.length() {
    if masks[i] != want_masks[i] {
      @test.fail("\{tag}: mask[\{i}] \{masks[i]} != \{want_masks[i]}")
    }
  }
  if seed != want_seed {
    @test.fail("\{tag}: seed \{seed} != \{want_seed}")
  }
}

///|
/// 空带窗（start == end）：循环体一次都不进——不消费熵、不推进 seed、
/// 不写任何 mask。这是主循环的结构性边界，独立于金标载荷。
test "空带窗不消费熵不改状态" {
  let dec = RangeDecoder::new(b"\x00\x01\x02\x03")
  let before_tell = dec.tell()
  let before_frac = dec.tell_frac()
  let x : Array[Double] = Array::make(120, 0.0)
  let masks : Array[Int] = Array::make(21, 0)
  let pulses : Array[Int] = Array::make(21, 0)
  let tf_res : Array[Int] = Array::make(21, 0)
  let seed2 = celt_quant_all_bands(
    dec, x, 3, 3, 0, false, pulses, tf_res, 0, 1000, 0, 0, 7L, masks,
  )
  if seed2 != 7L {
    @test.fail("seed 被推进：\{seed2} != 7")
  }
  for i in 0..<21 {
    if masks[i] != 0 {
      @test.fail("mask[\{i}] 被写：\{masks[i]}")
    }
  }
  if dec.tell() != before_tell || dec.tell_frac() != before_frac {
    @test.fail("解码器状态被改动")
  }
  for j in 0..<120 {
    if x[j] != 0.0 {
      @test.fail("频谱被写：x[\{j}] = \{x[j]}")
    }
  }
}
