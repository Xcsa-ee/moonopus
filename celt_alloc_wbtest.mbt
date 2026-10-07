// celt_alloc_wbtest.mbt
//
// 比特分配（RFC 6716 §4.3.3）的白盒测试。
//
// 金标由 tools/gen_alloc_goldens.py 的独立 Python 参考端算出，本文件提供
// 比对辅助函数；载荷常量、重放函数与 test 块都在生成的
// alloc_goldens_wbtest.mbt 里（用例多，test 块一并生成以免名字写岔）。

///|
/// 逐项比对分配结果：codedBands、balance，以及每带的 PVQ 位数、细能量位
/// 与收尾优先级。任一项不符就报出带下标与两侧数值。
fn expect_alloc(
  got : CeltAllocation,
  want_pulses : Array[Int],
  want_ebits : Array[Int],
  want_fine_priority : Array[Int],
  want_coded_bands : Int,
  want_balance : Int,
  tag : String,
) -> Unit raise {
  if got.coded_bands != want_coded_bands {
    @test.fail("\{tag}: codedBands \{got.coded_bands} != \{want_coded_bands}")
  }
  if got.balance != want_balance {
    @test.fail("\{tag}: balance \{got.balance} != \{want_balance}")
  }
  for i in 0..<want_pulses.length() {
    if got.pulses[i] != want_pulses[i] {
      @test.fail(
        "\{tag}: band \{i} pulses \{got.pulses[i]} != \{want_pulses[i]}",
      )
    }
    if got.ebits[i] != want_ebits[i] {
      @test.fail("\{tag}: band \{i} ebits \{got.ebits[i]} != \{want_ebits[i]}")
    }
    if got.fine_priority[i] != want_fine_priority[i] {
      @test.fail(
        "\{tag}: band \{i} fine_priority \{got.fine_priority[i]} != \{want_fine_priority[i]}",
      )
    }
  }
}

///|
/// celt_udiv 的无符号 32 位语义。这三个值都能手工推导，用来把位型行为钉死
/// ——参考实现把负的 `left` 按 opus_uint32 重解释后再除，若这里按有符号
/// 整除实现，遇到负值时两端就会分叉。
test "celt_udiv 的无符号 32 位语义" {
  // (-3) 按 uint32 是 4294967293，除以 5 得 858993458（余 3），仍在
  // int32 正区间，原样返回。
  @test.assert_eq(celt_udiv(-3, 5), 858993458)
  // 非负输入退化为普通整除
  @test.assert_eq(celt_udiv(10, 3), 3)
  // 结果 ≥ 2**31 时按 32 位回写成有符号：4294967295 → -1
  @test.assert_eq(celt_udiv(-1, 1), -1)
}

///|
/// total 的换算：帧载荷比特数左移 3 位变 1/8 bit，减去解码器已用位数与
/// 规范预留的 1 bit。
test "celt_alloc_total 的单位换算" {
  let dec = RangeDecoder::new(b"\x00\x00\x00\x00")
  // 解码器初始 tell_frac 为 8（1 字节），故 4*8*8 - 8 - 1 = 247
  @test.assert_eq(celt_alloc_total(4, dec), 247)
  @test.assert_eq(celt_alloc_total(1, dec), 64 - 8 - 1)
}
