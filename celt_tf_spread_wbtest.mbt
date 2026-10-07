// celt_tf_spread_wbtest.mbt
//
// TF 调整（§4.3.1）与频谱扩展决策的白盒测试。
//
// 金标由 tools/gen_tf_goldens.py 的独立 Python 参考端算出；载荷常量、重放
// 函数与 test 块都在生成的 tf_goldens_wbtest.mbt 里。

///|
/// 逐项比对每带 TF 调整值与频谱扩展决策，另带两条不依赖金标的规范断言。
fn expect_tf(
  got_tf : Array[Int],
  got_spread : Int,
  want_tf : Array[Int],
  want_spread : Int,
  tag : String,
) -> Unit raise {
  // Table 56 的 spread PDF 是 {7,2,21,2}/32，四个取值
  if got_spread < 0 || got_spread > 3 {
    @test.fail("\{tag}: spread \{got_spread} 超出 0..3")
  }
  if got_spread != want_spread {
    @test.fail("\{tag}: spread \{got_spread} != \{want_spread}")
  }
  if got_tf.length() != want_tf.length() {
    @test.fail("\{tag}: tf 长度 \{got_tf.length()} != \{want_tf.length()}")
  }
  for i in 0..<want_tf.length() {
    if got_tf[i] != want_tf[i] {
      @test.fail("\{tag}: band \{i} tf \{got_tf[i]} != \{want_tf[i]}")
    }
    // §4.3.1：调整值来自 tf_select_table，值域 −3..3
    if got_tf[i] < -3 || got_tf[i] > 3 {
      @test.fail("\{tag}: band \{i} tf \{got_tf[i]} 超出 −3..3")
    }
  }
}

///|
/// 门控不足时 spread 必须停在默认的 NORMAL（2）——与编码端一致，因为
/// 门控失败意味着两端都不写这个符号。
test "spread 门控不足时取默认值" {
  let dec = RangeDecoder::new(b"\x00\x00")
  // 0 字节载荷：位数预算为 0，`tell+4 <= 0` 恒不成立
  @test.assert_eq(celt_decode_spread(dec, 0), 2)
}

///|
/// 2.5ms 帧（LM=0）永远不预留 tf_select，且该表行前后两列相同
/// （{0,-1,0,-1, 0,-1,0,-1}），故读不读这一位结果都一样——这里只能验值域，
/// 「真的没读」由金标的解码器状态比对负责。
test "LM=0 的 TF 调整值域" {
  let dec = RangeDecoder::new(b"\x5a\xa5\x3c\xff\x11\x22\x33\x44")
  let got = celt_decode_tf(dec, 0, 21, false, 0, 64)
  for i in 0..<21 {
    if got[i] != 0 && got[i] != -1 {
      @test.fail("band \{i} tf \{got[i]}，LM=0 行只该给出 0 或 −1")
    }
  }
}
