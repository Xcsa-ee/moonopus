# -*- coding: utf-8 -*-
"""对帧级主流程（§4.3 频域段）做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

MUT = [
    ("celt_frame.mbt",
     "if state.old_e[nb + i] > state.old_e[i] {",
     "if state.old_e[nb + i] < state.old_e[i] {",
     "入口 MAXG 保护取成 min"),
    ("celt_frame.mbt",
     "cel_unquant_coarse_energy(dec, state.old_e, start, end, header.intra, lm)",
     "cel_unquant_coarse_energy(dec, state.old_e, start, end, false, lm)",
     "粗能量忽略帧内标志"),
    ("celt_frame.mbt",
     "    header.is_transient,\n    lm,\n    frame_bytes,",
     "    false,\n    lm,\n    frame_bytes,",
     "TF 解码忽略瞬态标志"),
    ("celt_frame.mbt",
     "let spread = celt_decode_spread(dec, frame_bytes)",
     "let spread = 0",
     "spread 符号不读，恒 0"),
    ("celt_frame.mbt",
     "let cap = celt_init_caps(lm, 1)",
     "let cap = celt_init_caps(lm, 2)",
     "caps 按双声道算"),
    ("celt_frame.mbt",
     "if header.is_transient && lm >= 2 && bits >= (lm + 2) << CEL_BITRES {",
     "if header.is_transient && bits >= (lm + 2) << CEL_BITRES {",
     "反塌缩预留丢掉 LM≥2 条件"),
    ("celt_frame.mbt",
     "if header.is_transient && lm >= 2 && bits >= (lm + 2) << CEL_BITRES {",
     "if lm >= 2 && bits >= (lm + 2) << CEL_BITRES {",
     "反塌缩预留丢掉瞬态条件"),
    ("celt_frame.mbt",
     "    frame_bytes * (8 << CEL_BITRES) - anti_rsv,\n    alloc.balance,",
     "    bits,\n    alloc.balance,",
     "形状解码预算误用分配剩余额"),
    ("celt_frame.mbt",
     "  if anti_rsv > 0 {\n    anti_on = celt_decode_anti_collapse_flag(dec, anti_rsv)",
     "  if anti_rsv > 8 {\n    anti_on = celt_decode_anti_collapse_flag(dec, anti_rsv)",
     "反塌缩标志位不读"),
    ("celt_frame.mbt",
     "cel_unquant_fine_energy(dec, state.old_e, start, end, alloc.ebits)",
     "cel_unquant_fine_energy(dec, state.old_e, start, end, alloc.fine_priority)",
     "细能量用错分配数组"),
    ("celt_frame.mbt",
     "    frame_bytes * 8 - dec.tell(),",
     "    frame_bytes * 8,",
     "收尾细能量丢掉已消费位数"),
    ("celt_frame.mbt",
     "  let mut anti_on = 0\n  if anti_rsv > 0 {\n    anti_on = celt_decode_anti_collapse_flag(dec, anti_rsv)\n  }\n  cel_unquant_energy_finalise(\n    dec,\n    state.old_e,\n    start,\n    end,\n    alloc.ebits,\n    alloc.fine_priority,\n    frame_bytes * 8 - dec.tell(),\n  )",
     "  let mut anti_on = 0\n  cel_unquant_energy_finalise(\n    dec,\n    state.old_e,\n    start,\n    end,\n    alloc.ebits,\n    alloc.fine_priority,\n    frame_bytes * 8 - dec.tell(),\n  )\n  if anti_rsv > 0 {\n    anti_on = celt_decode_anti_collapse_flag(dec, anti_rsv)\n  }",
     "标志位读取与收尾细能量顺序颠倒"),
    # 注：prev1/prev2 互换是可证明的等效变异——反塌缩用 min(prev1, prev2)
    # 估计历史能量（§4.3.5），min 对称，交换无可观测影响；等价地覆盖
    # 「数组接错」的变异用下面这条（prev1 误接当前帧能量）。
    ("celt_frame.mbt",
     "      state.old_e,\n      state.old_log_e,\n      state.old_log_e2,\n      alloc.pulses,",
     "      state.old_e,\n      state.old_e,\n      state.old_log_e,\n      alloc.pulses,",
     "反塌缩 prev1 误接当前帧能量"),
    ("celt_frame.mbt",
     "      alloc.pulses,\n      seed,\n    )",
     "      alloc.pulses,\n      state.rng,\n    )",
     "反塌缩种子误用帧首 rng"),
    ("celt_frame.mbt",
     "      state.old_e[i] = -28.0",
     "      state.old_e[i] = -27.0",
     "静音置位常量 -28 改 -27"),
    ("celt_frame.mbt",
     "let freq = celt_denormalise(x, state.old_e, start, end, m, header.silence)",
     "let freq = celt_denormalise(x, state.old_e, start, end, m, false)",
     "反归一化忽略静音标志"),
    ("celt_frame.mbt",
     "    state.old_e[nb + i] = state.old_e[i]",
     "    state.old_e[nb + i] = 0.0",
     "帧末后半拷贝写零"),
    ("celt_frame.mbt",
     "  if !header.is_transient {",
     "  if header.is_transient {",
     "轮换分支条件取反"),
    ("celt_frame.mbt",
     "      state.old_log_e2[i] = state.old_log_e[i]\n      state.old_log_e[i] = state.old_e[i]",
     "      state.old_log_e[i] = state.old_e[i]\n      state.old_log_e2[i] = state.old_log_e[i]",
     "两代能量下移顺序颠倒"),
    ("celt_frame.mbt",
     "      if state.old_log_e[i] > state.old_e[i] {",
     "      if state.old_log_e[i] < state.old_e[i] {",
     "瞬态能量取 min 改取 max"),
    ("celt_frame.mbt",
     "  state.rng = dec.rng",
     "  state.rng = seed",
     "帧末 rng 误存 LCG 线程值"),
    ("celt_frame.mbt",
     "    state.rng,\n    masks,",
     "    0L,\n    masks,",
     "形状解码种子不接跨帧状态"),
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
