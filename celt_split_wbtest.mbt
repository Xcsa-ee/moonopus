// celt_split_wbtest.mbt
//
// split 解码（RFC 6716 §4.3.4.4）的白盒测试辅助。
//
// 金标由 tools/gen_split_goldens.py 的独立 Python 参考端算出，本文件提供
// 比对助手与不依赖金标的不变量（边界、账目守恒、PVQ 范数）；载荷常量、
// 重放函数与 test 块都在生成的 split_goldens_wbtest.mbt 里。

///|
/// 比对 θ 解码结果。`want` = [inv, imid, iside, delta, itheta, qalloc,
/// qn, b_after, fill_after]。先做不依赖金标的内部一致性检查，再逐项
/// 比对。
fn expect_theta(
  dec : RangeDecoder,
  got : CeltThetaSplit,
  b_after : Int,
  fill_after : Int,
  want : Array[Int],
  tell_before : Int,
  tag : String,
) -> Unit raise {
  if got.qn != 1 && (got.qn < 2 || got.qn > 256 || got.qn % 2 != 0) {
    @test.fail("\{tag}: qn \{got.qn} 不是 1 或 [2,256] 内的偶数")
  }
  if got.itheta < 0 || got.itheta > 16384 {
    @test.fail("\{tag}: itheta \{got.itheta} 越界 0..16384")
  }
  if got.imid < 0 || got.imid > 32767 || got.iside < 0 || got.iside > 32767 {
    @test.fail("\{tag}: imid/iside \{got.imid}/\{got.iside} 越界")
  }
  if got.inv != 0 && got.inv != 1 {
    @test.fail("\{tag}: inv \{got.inv} 不是 0/1")
  }
  // qalloc 必须精确等于解码器实际消耗的位数
  let tell_delta = dec.tell_frac() - tell_before
  if got.qalloc != tell_delta {
    @test.fail("\{tag}: qalloc \{got.qalloc} != tell_frac 增量 \{tell_delta}")
  }
  let got_arr = [
    got.inv,
    got.imid,
    got.iside,
    got.delta,
    got.itheta,
    got.qalloc,
    got.qn,
    b_after,
    fill_after,
  ]
  if got_arr.length() != want.length() {
    @test.fail("\{tag}: 期望数组长度 \{want.length()} 异常")
  }
  for i in 0..<want.length() {
    if got_arr[i] != want[i] {
      @test.fail("\{tag}: 分量 \{i} = \{got_arr[i]} != \{want[i]}")
    }
  }
}

///|
/// 比对整棵 split 树。`want_splits` 每 7 项一组
/// [qn, itheta, imid, iside, delta, inv, qalloc]；`want_leaves` 每叶
/// [n, blocks, lm, b, q, used, fill, plen] 再跟 plen 个脉冲值。
/// 同时校验不依赖金标的账目与 PVQ 不变量。
fn expect_partition(
  got : CeltPartitionResult,
  band : Int,
  remaining_init : Int,
  want_splits : Array[Int],
  want_leaves : Array[Int],
  remaining_end : Int,
  tag : String,
) -> Unit raise {
  if got.splits.length() * 7 != want_splits.length() {
    @test.fail("\{tag}: split 数 \{got.splits.length()} 与期望不符")
  }
  for s in 0..<got.splits.length() {
    let sp = got.splits[s]
    let base = s * 7
    let want = [
      sp.qn,
      sp.itheta,
      sp.imid,
      sp.iside,
      sp.delta,
      sp.inv,
      sp.qalloc,
    ]
    for k in 0..<7 {
      if want[k] != want_splits[base + k] {
        @test.fail(
          "\{tag}: split \{s} 分量 \{k} = \{want[k]} != \{want_splits[base + k]}",
        )
      }
    }
    if sp.qn != 1 && (sp.qn < 2 || sp.qn > 256 || sp.qn % 2 != 0) {
      @test.fail("\{tag}: split \{s} qn \{sp.qn} 非法")
    }
    if sp.itheta < 0 || sp.itheta > 16384 {
      @test.fail("\{tag}: split \{s} itheta \{sp.itheta} 越界")
    }
    if sp.qalloc < 0 {
      @test.fail("\{tag}: split \{s} qalloc \{sp.qalloc} 为负")
    }
  }
  let mut p = 0
  let mut li = 0
  let mut consumed = 0
  while p < want_leaves.length() {
    if li >= got.leaves.length() {
      @test.fail("\{tag}: 叶数少于期望（\{li}）")
    }
    let leaf = got.leaves[li]
    let n_w = want_leaves[p]
    let blocks_w = want_leaves[p + 1]
    let lm_w = want_leaves[p + 2]
    let b_w = want_leaves[p + 3]
    let q_w = want_leaves[p + 4]
    let used_w = want_leaves[p + 5]
    let fill_w = want_leaves[p + 6]
    let plen = want_leaves[p + 7]
    p += 8
    if leaf.n != n_w ||
      leaf.blocks != blocks_w ||
      leaf.lm != lm_w ||
      leaf.b != b_w ||
      leaf.q != q_w ||
      leaf.used != used_w ||
      leaf.fill != fill_w {
      @test.fail(
        "\{tag}: 叶 \{li} 控制量不符（n=\{leaf.n}/\{n_w} b=\{leaf.b}/\{b_w} q=\{leaf.q}/\{q_w}）",
      )
    }
    // used 必须是该叶位数的反查结果
    if leaf.used != celt_pulses2bits(band, leaf.lm, leaf.q) {
      @test.fail("\{tag}: 叶 \{li} used \{leaf.used} != pulses2bits")
    }
    // q 不超过该行缓存的 Kmax
    let off = cel_cache_index50[(leaf.lm + 1) * CEL_NB_EBANDS + band]
    if leaf.q > cel_cache_bits50[off].to_int() {
      @test.fail("\{tag}: 叶 \{li} q \{leaf.q} 超过 Kmax")
    }
    // 脉冲向量：长度与 L1 范数（q>0）；q==0 无熵消费
    if leaf.q == 0 {
      if plen != 0 || leaf.pulses.length() != 0 {
        @test.fail("\{tag}: 叶 \{li} q=0 却有脉冲")
      }
    } else {
      if plen != n_w || leaf.pulses.length() != n_w {
        @test.fail(
          "\{tag}: 叶 \{li} 脉冲长度 \{leaf.pulses.length()} != \{n_w}",
        )
      }
      let mut l1 = 0
      for y in leaf.pulses {
        l1 += if y >= 0 { y } else { -y }
      }
      if l1 != celt_get_pulses(leaf.q) {
        @test.fail("\{tag}: 叶 \{li} L1 \{l1} != get_pulses(\{leaf.q})")
      }
      for j in 0..<plen {
        if leaf.pulses[j] != want_leaves[p + j] {
          @test.fail(
            "\{tag}: 叶 \{li} 脉冲 \{j} = \{leaf.pulses[j]} != \{want_leaves[p + j]}",
          )
        }
      }
    }
    p += plen
    li += 1
    consumed += leaf.used
  }
  if li != got.leaves.length() {
    @test.fail(
      "\{tag}: 叶数多于期望（\{li} vs \{got.leaves.length()}）",
    )
  }
  // 账目守恒：剩余预算 = 初始 − 全部熵消费（split 的 qalloc + 叶 used）
  for s in 0..<got.splits.length() {
    consumed += got.splits[s].qalloc
  }
  if got.remaining_bits != remaining_init - consumed {
    @test.fail(
      "\{tag}: remaining \{got.remaining_bits} != \{remaining_init} - \{consumed}",
    )
  }
  if got.remaining_bits != remaining_end {
    @test.fail("\{tag}: remaining \{got.remaining_bits} != \{remaining_end}")
  }
}

///|
/// isqrt32：floor(sqrt) 的已知值与 32 位边界。输入从 1 起（0 不在
/// 解码路径上：三角 PDF 的反解形如 8*fm+1 ≥ 1）。
test "isqrt32 的已知值与 32 位边界" {
  @test.assert_eq(celt_isqrt32(1), 1)
  @test.assert_eq(celt_isqrt32(2), 1)
  @test.assert_eq(celt_isqrt32(3), 1)
  @test.assert_eq(celt_isqrt32(4), 2)
  @test.assert_eq(celt_isqrt32(8), 2)
  @test.assert_eq(celt_isqrt32(9), 3)
  @test.assert_eq(celt_isqrt32(15), 3)
  @test.assert_eq(celt_isqrt32(16), 4)
  @test.assert_eq(celt_isqrt32(26), 5)
  @test.assert_eq(celt_isqrt32(99), 9)
  @test.assert_eq(celt_isqrt32(100), 10)
  // 三角 PDF 反解的实际输入形如 8*fm+1，全是 1 mod 8
  @test.assert_eq(celt_isqrt32(8 * 45 + 1), 19)
  // 平方边界（取 30000 与 2**31-1：再大的平方会越过 Int32）
  @test.assert_eq(celt_isqrt32(30000 * 30000), 30000)
  @test.assert_eq(celt_isqrt32(30000 * 30000 + 1), 30000)
  @test.assert_eq(celt_isqrt32(0x7FFFFFFF), 46340)
}

///|
/// bitexact_cos / bitexact_log2tan 的定点锚点。期望值来自
/// tools/celt_split_ref.py 的独立定点移植（结构与 C 逐行对应但代码
/// 独立），这两个函数直接影响 delta，错一位整条位数划分都会偏。
test "bitexact 定点三角函数锚点" {
  // 格点下界 cos(64/16384·π/2) ≈ 32767
  @test.assert_eq(celt_bitexact_cos(64), 32767)
  // 45°：近似 cos 值
  @test.assert_eq(celt_bitexact_cos(8192), 23171)
  // 接近 90° 的格点
  @test.assert_eq(celt_bitexact_cos(16320), 200)
  // log2tan(isin, icos)：两参数相等时为 0（tan=1）
  let c = celt_bitexact_cos(8192)
  @test.assert_eq(celt_bitexact_log2tan(c, c), 0)
  // 深负区取样：sin 小、cos 大 → log2(tan) 明显为负
  @test.assert_eq(celt_bitexact_log2tan(131, 32766), -16292)
}

///|
/// compute_qn：极小位数归 1、结果恒为 1 或偶数、随位数单调不降。
test "compute_qn 的边界与单调性" {
  // 极小 b：qb<4 → 1
  @test.assert_eq(celt_compute_qn(6, 0, 6, 21, false), 1)
  @test.assert_eq(celt_compute_qn(6, 10, 6, 21, false), 1)
  // 大 b 触到 8<<BITRES 上限后进偶
  let qn_max = celt_compute_qn(6, 10000, 6, 21, false)
  if qn_max < 2 || qn_max > 256 || qn_max % 2 != 0 {
    @test.fail("qn_max \{qn_max} 非法")
  }
  // 单调不降：b 增大时量化阶数只增不减
  let mut prev = 0
  for b in 0..<400 {
    let qn = celt_compute_qn(6, b, 6, 21, false)
    if qn < prev {
      @test.fail("b=\{b}: qn \{qn} < \{prev}")
    }
    prev = qn
  }
  // 同一位数下偏移量不同 → 阶数不同（两相模式用 -16，普通用 -4）
  let qn_mono = celt_compute_qn(2, 100, 8, 21, false)
  let qn_st2 = celt_compute_qn(2, 100, -4, 21, true)
  if qn_mono == qn_st2 {
    @test.fail("偏移未影响 qn：\{qn_mono}")
  }
}
