// celt_alloc_flags_wbtest.mbt
//
// band boost 与 allocation trim（RFC 6716 §4.3.3）的白盒测试。
//
// 金标由 tools/gen_alloc_flags_goldens.py 的独立 Python 参考端算出；载荷
// 常量、重放函数与 test 块都在生成的 alloc_flags_goldens_wbtest.mbt 里。

///|
/// 逐项比对每带 boost 加成与 trim 值。偏一格都会让后续比特分配错位，
/// 所以整份比对，不只看总数。
fn expect_alloc_flags(
  got : CeltAllocFlags,
  want_offsets : Array[Int],
  want_alloc_trim : Int,
  tag : String,
) -> Unit raise {
  // §4.3.3：trim 是 0..10 的整数，5 表示不加不减。icdf 表若有 11 项之外
  // 的符号或索引算错，这里会先露出来。
  if got.alloc_trim < 0 || got.alloc_trim > 10 {
    @test.fail("\{tag}: alloc_trim \{got.alloc_trim} 超出 0..10")
  }
  if got.alloc_trim != want_alloc_trim {
    @test.fail("\{tag}: alloc_trim \{got.alloc_trim} != \{want_alloc_trim}")
  }
  for i in 0..<want_offsets.length() {
    if got.offsets[i] != want_offsets[i] {
      @test.fail(
        "\{tag}: band \{i} boost \{got.offsets[i]} != \{want_offsets[i]}",
      )
    }
  }
}
