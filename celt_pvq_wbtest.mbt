// celt_pvq_wbtest.mbt
//
// PVQ 脉冲解码（RFC 6716 §4.3.4.2）的白盒测试。
//
// 这里的两条主测试都不依赖参考实现，属于规范自身的数学性质：
//   1. V(N,K) 的闭式值——由「K 个脉冲在 N 维怎么摆」的组合意义直接得出；
//   2. 脉冲数守恒——穷举每个码字下标，断言 Σ|X| = K。
// 金标（独立 Python 端）另在 pvq_goldens_wbtest.mbt 里，主要覆盖
// decode_uint64 那条 32 位码本的路径。

///|
/// V(N,K) 的闭式交叉验证。这三个式子来自脉冲分配的组合意义，与本文件
/// 用动态规划填表的方式无关，对上了才说明递归实现没写歪：
///   - V(N,1) = 2N      N 个位置 × 正负两种符号
///   - V(1,K) = 2       一维里 K 个脉冲只能是 +K 或 −K
///   - V(2,K) = 4K      K≥1，按落点拆分可枚举
test "V(N,K) 的闭式交叉验证" {
  for n in 1..<9 {
    let cols = 2
    let got = celt_pvq_v_table(n, 1)[n * cols + 1]
    if got != (2 * n).to_int64() {
      @test.fail("V(\{n},1) = \{got} != \{2 * n}")
    }
  }
  for k in 1..<9 {
    let t1 = celt_pvq_v_table(1, k)
    if t1[1 * (k + 1) + k] != 2L {
      @test.fail("V(1,\{k}) = \{t1[1 * (k + 1) + k]} != 2")
    }
    let t2 = celt_pvq_v_table(2, k)
    if t2[2 * (k + 1) + k] != (4 * k).to_int64() {
      @test.fail("V(2,\{k}) = \{t2[2 * (k + 1) + k]} != \{4 * k}")
    }
  }
}

///|
/// 脉冲数守恒：穷举每个码字下标，还原出的向量必须满足 Σ|X| = K。
///
/// 这是 §4.3.4.2 五步迭代的数学性质，不依赖任何参考端——只要某一步的
/// 区间划分算错，总会在某个下标上把脉冲数算多或算少。
test "脉冲数守恒：穷举所有码字下标" {
  for n in 1..<13 {
    for k in 1..<6 {
      let tab = celt_pvq_v_table(n, k)
      let v = tab[n * (k + 1) + k]
      if v > 40000L {
        continue // 控制穷举规模，更大的码本由金标抽样覆盖
      }
      let mut i = 0L
      while i < v {
        let x = celt_pvq_unindex(n, k, tab, i)
        if x.length() != n {
          @test.fail("n=\{n} k=\{k}: 长度 \{x.length()} != \{n}")
        }
        let mut sum = 0
        for p in x {
          sum += if p < 0 { -p } else { p }
        }
        if sum != k {
          @test.fail("n=\{n} k=\{k} 下标 \{i}: Σ|X| = \{sum} != \{k}")
        }
        i += 1L
      }
    }
  }
}

///|
/// k=0 的码字唯一（全零向量），不读比特。
test "k=0 返回全零且不推进解码器" {
  let dec = RangeDecoder::new(b"\x5a\xa5\x3c\xff\x11\x22\x33\x44")
  let before_rng = dec.rng
  let before_tell = dec.tell()
  let x = celt_decode_pulses(dec, 8, 0)
  if x.length() != 8 {
    @test.fail("长度 \{x.length()} != 8")
  }
  for p in x {
    if p != 0 {
      @test.fail("k=0 却解出 \{p}")
    }
  }
  if dec.rng != before_rng || dec.tell() != before_tell {
    @test.fail("k=0 不该消耗比特")
  }
}

///|
/// 码字总数随 N 单调不减：维度更多，同样的脉冲能摆出更多花样。
test "V(N,K) 随 N 单调不减" {
  let k = 4
  let mut prev = 0L
  for n in 1..<33 {
    let v = celt_pvq_v_table(n, k)[n * (k + 1) + k]
    if v < prev {
      @test.fail("V(\{n},\{k}) = \{v} 小于上一维的 \{prev}")
    }
    prev = v
  }
}

///|
/// 金标比对：逐项比脉冲向量与长度，另比两侧的脉冲总数。
///
/// 守恒本身（Σ|X| = K）由上面那条穷举测试独立保证——这里比的是两侧一致，
/// 用来把失败定位到具体下标。
fn expect_pulses(
  got : Array[Int],
  want : Array[Int],
  tag : String,
) -> Unit raise {
  if got.length() != want.length() {
    @test.fail("\{tag}: 长度 \{got.length()} != \{want.length()}")
  }
  let mut got_sum = 0
  let mut want_sum = 0
  for i in 0..<want.length() {
    if got[i] != want[i] {
      @test.fail("\{tag}: 下标 \{i} 处 \{got[i]} != \{want[i]}")
    }
    got_sum += if got[i] < 0 { -got[i] } else { got[i] }
    want_sum += if want[i] < 0 { -want[i] } else { want[i] }
  }
  if got_sum != want_sum {
    @test.fail("\{tag}: Σ|X| = \{got_sum} != \{want_sum}")
  }
}
