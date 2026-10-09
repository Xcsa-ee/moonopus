// celt_synthesis_wbtest.mbt
//
// 时域合成链的白盒测试。不依赖参考端，靠规范与实现结构自身的性质：
//   1. 零激励全链精确零（频谱全 0、后滤波开到最大增益也不产生数值）；
//   2. 增益全零时链输出 = IMDCT + deemphasis 的独立重放（逐位一致，
//      证明 hist/参数路由/轮换没有污染样本通路，且跨帧状态取用正确）；
//   3. 轮换与钳制的直接状态断言（参考实现 1574/1582/1563 语义）：
//      LM≠0 时 old 与 st 都等于本帧参数；LM=0 时 old 停在「钳后的
//      上一帧 st」（初值 0 被钳成 15），本帧参数下一帧才生效；
//   4. deemph_mem 闭式：帧末状态 = αp × 末样本（同式同序，逐位）。

///|
test "合成链：零激励全链精确零" {
  let st = CeltSynthState::new()
  let freq = Array::make(960, 0.0)
  for k in 0..<2 {
    // 开到最大增益/最大周期/tapset 2：全链仍须逐位为 0
    let pcm = celt_synth_frame(freq, 3, false, 100, 0.75, 2, st)
    for j in 0..<pcm.length() {
      if pcm[j] != 0.0 {
        @test.fail("帧 \{k} 样本 \{j} = \{pcm[j]} != 0")
      }
    }
  }
}

///|
test "合成链：增益全零 = IMDCT+deemphasis 独立重放（逐位）" {
  let st = CeltSynthState::new()
  let freq1 = Array::make(960, 0.0)
  for i in 0..<960 {
    freq1[i] = (i * 37 % 101 - 50).to_double() * 0.7
  }
  let freq2 = Array::make(960, 0.0)
  for i in 0..<960 {
    freq2[i] = (i * 13 % 97 - 48).to_double() * 0.9
  }
  // 第一帧：全零初始 pending/mem，直接重放
  let p1 = celt_synth_frame(freq1, 3, false, 0, 0.0, 0, st)
  let (o1, _np1) = celt_imdct_frame(freq1, 3, false, Array::make(60, 0.0))
  let w1 = Array::make(960, 0.0)
  let m1 = celt_deemphasis(o1, w1, 0.0)
  for j in 0..<960 {
    if p1[j] != w1[j] {
      @test.fail("帧1 样本 \{j}：链 \{p1[j]} != 重放 \{w1[j]}")
    }
  }
  // 第二帧：先存第一帧后的 pending/mem，链跑完再用存值独立重放
  let p1save = Array::make(60, 0.0)
  for i in 0..<60 {
    p1save[i] = st.pending[i]
  }
  let m1save = st.deemph_mem
  if m1save != m1 {
    @test.fail("帧1 deemph_mem：\{m1save} != \{m1}")
  }
  let p2 = celt_synth_frame(freq2, 3, false, 0, 0.0, 0, st)
  let (o2, _np2) = celt_imdct_frame(freq2, 3, false, p1save)
  let w2 = Array::make(960, 0.0)
  let _ = celt_deemphasis(o2, w2, m1save)
  for j in 0..<960 {
    if p2[j] != w2[j] {
      @test.fail("帧2 样本 \{j}：链 \{p2[j]} != 重放 \{w2[j]}")
    }
  }
}

///|
test "合成链：轮换与钳制的直接状态断言（1574/1582/1563）" {
  // LM≠0：轮换后 old 与 st 都等于本帧参数（1582 同步块）
  let a = CeltSynthState::new()
  let f960 = Array::make(960, 0.0)
  let _ = celt_synth_frame(f960, 3, false, 100, 0.375, 1, a)
  if a.pf_period != 100 || a.pf_period_old != 100 {
    @test.fail(
      "lm3 帧1：st=\{a.pf_period} old=\{a.pf_period_old}，都应为 100",
    )
  }
  if a.pf_gain != 0.375 || a.pf_gain_old != 0.375 {
    @test.fail("lm3 帧1：gain st/old = \{a.pf_gain}/\{a.pf_gain_old}")
  }
  if a.pf_tapset != 1 || a.pf_tapset_old != 1 {
    @test.fail("lm3 帧1：tapset st/old = \{a.pf_tapset}/\{a.pf_tapset_old}")
  }
  let _ = celt_synth_frame(f960, 3, false, 60, 0.75, 2, a)
  if a.pf_period != 60 ||
    a.pf_period_old != 60 ||
    a.pf_gain != 0.75 ||
    a.pf_gain_old != 0.75 ||
    a.pf_tapset != 2 ||
    a.pf_tapset_old != 2 {
    @test.fail(
      "lm3 帧2：st = \{a.pf_period}/\{a.pf_gain}/\{a.pf_tapset}，" +
      "old = \{a.pf_period_old}/\{a.pf_gain_old}/\{a.pf_tapset_old}",
    )
  }
  // LM=0：无 1582 同步块——old 停在轮换前的 st（初值 0 被 1563 钳成 15）
  let b = CeltSynthState::new()
  let f120 = Array::make(120, 0.0)
  let _ = celt_synth_frame(f120, 0, false, 100, 0.375, 1, b)
  if b.pf_period != 100 || b.pf_period_old != 15 {
    @test.fail(
      "lm0 帧1：st=\{b.pf_period}（应 100） old=\{b.pf_period_old}（应 15）",
    )
  }
  if b.pf_gain != 0.375 || b.pf_gain_old != 0.0 {
    @test.fail(
      "lm0 帧1：gain st/old = \{b.pf_gain}/\{b.pf_gain_old}，old 应 0",
    )
  }
  let _ = celt_synth_frame(f120, 0, false, 60, 0.75, 2, b)
  if b.pf_period != 60 ||
    b.pf_period_old != 100 ||
    b.pf_gain != 0.75 ||
    b.pf_gain_old != 0.375 {
    @test.fail(
      "lm0 帧2：st = \{b.pf_period}/\{b.pf_gain}，" +
      "old = \{b.pf_period_old}/\{b.pf_gain_old}（应 100/0.375）",
    )
  }
}

///|
test "合成链：deemph_mem = αp × 末样本（逐位）" {
  let st = CeltSynthState::new()
  let freq = Array::make(480, 0.0)
  for i in 0..<480 {
    freq[i] = (i * 29 % 89 - 44).to_double() * 1.3
  }
  let pcm = celt_synth_frame(freq, 2, false, 60, 0.75, 2, st)
  let last = pcm[pcm.length() - 1]
  if st.deemph_mem != CEL_DEEMPH_COEF * last {
    @test.fail(
      "deemph_mem \{st.deemph_mem} != αp·末样本 \{CEL_DEEMPH_COEF * last}",
    )
  }
}
