# -*- coding: utf-8 -*-
"""对时域合成链（§4.3.7/§4.3.7.1/§4.3.7.2 接线）做变异验证：
注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。

等效侧备注（刻意不列为变异）：
  - CEL_SYNTH_HIST 1088→1024：comb 最远回读恰为 1024，历史内容与
    连续时间轴一致，读取范围内逐位等价；
  - 首段 n 的 CEL_SHORT_MDCT→CEL_OVERLAP：同为 120；
  - 丢掉 pf_period_old 的钳制：轮换恒从 st 重新搬值，且 comb 内部
    还有一层钳制，旧槽位的钳后值不可观测。
"""
import io
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

MUT = [
    ("celt_synthesis.mbt",
     "if state.pf_period < CEL_COMB_MINPERIOD {",
     "if state.pf_period < 0 {",
     "st 周期钳制基线改 0"),
    ("celt_synthesis.mbt",
     "    state.pf_period_old,\n    state.pf_period,\n    CEL_SHORT_MDCT,",
     "    state.pf_period,\n    state.pf_period_old,\n    CEL_SHORT_MDCT,",
     "首段 t0/t1 互换"),
    ("celt_synthesis.mbt",
     "    state.pf_gain_old,\n    state.pf_gain,\n    state.pf_tapset_old,",
     "    state.pf_gain,\n    state.pf_gain_old,\n    state.pf_tapset_old,",
     "首段 g0/g1 互换"),
    ("celt_synthesis.mbt",
     "    state.pf_tapset_old,\n    state.pf_tapset,\n    win,",
     "    state.pf_tapset,\n    state.pf_tapset_old,\n    win,",
     "首段 ts0/ts1 互换"),
    ("celt_synthesis.mbt",
     "  if lm != 0 {\n    // 第二段",
     "  if lm == 0 {\n    // 第二段",
     "第二段判据取反"),
    ("celt_synthesis.mbt",
     "      h + CEL_SHORT_MDCT,\n      state.pf_period,",
     "      h + (CEL_OVERLAP >> 1),\n      state.pf_period,",
     "第二段基准改 ov/2"),
    ("celt_synthesis.mbt",
     "      state.pf_period,\n      pf_pitch,\n      n - CEL_SHORT_MDCT,",
     "      state.pf_period,\n      state.pf_period,\n      n - CEL_SHORT_MDCT,",
     "第二段 t1 误用 st->period"),
    ("celt_synthesis.mbt",
     "      state.pf_gain,\n      pf_gain,\n      state.pf_tapset,",
     "      state.pf_gain,\n      state.pf_gain,\n      state.pf_tapset,",
     "第二段 g1 误用 st->gain"),
    ("celt_synthesis.mbt",
     "      state.pf_tapset,\n      pf_tapset,\n      win,",
     "      state.pf_tapset,\n      state.pf_tapset,\n      win,",
     "第二段 ts1 误用 st->tapset"),
    ("celt_synthesis.mbt",
     "  if lm != 0 {\n    // LM≠0：old 同步成本帧参数（1582–1584 行）",
     "  if lm == 0 {\n    // LM≠0：old 同步成本帧参数（1582–1584 行）",
     "轮换同步块判据取反"),
    ("celt_synthesis.mbt",
     "  state.pf_period_old = state.pf_period\n"
     "  state.pf_gain_old = state.pf_gain\n"
     "  state.pf_tapset_old = state.pf_tapset\n"
     "  state.pf_period = pf_pitch\n"
     "  state.pf_gain = pf_gain\n"
     "  state.pf_tapset = pf_tapset\n",
     "  state.pf_period = pf_pitch\n"
     "  state.pf_gain = pf_gain\n"
     "  state.pf_tapset = pf_tapset\n"
     "  state.pf_period_old = state.pf_period\n"
     "  state.pf_gain_old = state.pf_gain\n"
     "  state.pf_tapset_old = state.pf_tapset\n",
     "轮换先写 st 后搬 old"),
    ("celt_synthesis.mbt",
     "    state.hist[k] = work[n + k]",
     "    state.hist[k] = work[k]",
     "历史滚动不丢最旧 n"),
    ("celt_synthesis.mbt",
     "    state.hist[k] = work[n + k]",
     "    state.hist[k] = work[n + k + 1]",
     "历史滚动差一"),
    ("celt_synthesis.mbt",
     "  state.deemph_mem = celt_deemphasis(x, pcm, state.deemph_mem)",
     "  state.deemph_mem = celt_deemphasis(x, pcm, 0.0)",
     "deemph 状态不跨帧"),
    ("celt_synthesis.mbt",
     "    x[j] = work[h + j]",
     "    x[j] = work[j]",
     "deemph 输入误取历史头"),
    ("celt_synthesis.mbt",
     "  state.pending = new_pending\n  pcm",
     "  let _pn = new_pending\n"
     "  state.pending = Array::make(CEL_OVERLAP >> 1, 0.0)\n  pcm",
     "pending 清零不承接"),
    ("celt_synthesis.mbt",
     "    r.freq,\n    lm,",
     "    r.spectrum,\n    lm,",
     "wrapper 误传归一化谱"),
    ("celt_synthesis.mbt",
     "    r.header.is_transient,\n    r.header.postfilter_pitch,",
     "    false,\n    r.header.postfilter_pitch,",
     "wrapper 瞬态标志写死 false"),
    ("celt_synthesis.mbt",
     "    r.header.postfilter_pitch,\n    r.header.postfilter_gain,\n"
     "    r.header.postfilter_tapset,",
     "    r.header.postfilter_tapset,\n    r.header.postfilter_gain,\n"
     "    r.header.postfilter_pitch,",
     "wrapper pitch/tapset 互换"),
    ("celt_synthesis.mbt",
     "    r.freq,\n    lm,",
     "    r.freq,\n    3 - lm,",
     "wrapper lm 接成 3-lm"),
]


def run_test():
    p = subprocess.run(["moon", "test"], capture_output=True,
                       encoding="utf-8", errors="replace")
    return (p.stdout or "") + (p.stderr or "")


def main():
    results = []
    for path, old, new, desc in MUT:
        src = io.open(path, encoding="utf-8", newline="").read()
        if src.count(old) != 1:
            results.append(("ANCHOR", desc,
                            f"锚点出现 {src.count(old)} 次，需唯一"))
            continue
        try:
            io.open(path, "w", encoding="utf-8", newline="").write(
                src.replace(old, new, 1))
            out = run_test()
        finally:
            io.open(path, "w", encoding="utf-8", newline="").write(src)
        line = ""
        for l in out.splitlines():
            if "Total tests" in l:
                line = l.strip()
        if "failed: 0" in out and "Total tests" in out:
            results.append(("GREEN", desc, line))
        elif "Total tests" in out:
            results.append(("RED  ", desc, line))
        else:
            results.append(("COMPILE", desc, out.strip().splitlines()[-1][:110]
                            if out.strip() else ""))
    width = max(len(d) for _, d, _ in results)
    for status, desc, info in results:
        print(f"{status:8} {desc:<{width}}  {info}")
    bad = [d for s, d, _ in results if s in ("GREEN", "ANCHOR")]
    if bad:
        print("\n未被抓住/锚点失效的变异：", bad)
        raise SystemExit(1)
    print("\n全部变异均被测试捕获。")


if __name__ == "__main__":
    main()
