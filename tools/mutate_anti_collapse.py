# -*- coding: utf-8 -*-
"""对反塌缩做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess

MUT = [
    ("celt_anti_collapse.mbt",
     "(seed * 1664525L + 1013904223L) & 0xFFFFFFFFL",
     "(seed * 1664525L + 1013904224L) & 0xFFFFFFFFL",
     "lcg 乘数常量加 1"),
    ("celt_anti_collapse.mbt",
     "(seed * 1664525L + 1013904223L) & 0xFFFFFFFFL",
     "(seed * 1664525L + 1013904223L) & 0x7FFFFFFFL",
     "lcg 的 32 位回绕掩码丢掉最高位"),
    ("celt_anti_collapse.mbt",
     "let g = 1.0 / @math.pow(e, 0.5) * gain",
     "let g = 1.0 / @math.pow(e, 0.5)",
     "renorm 丢掉 gain 因子"),
    ("celt_anti_collapse.mbt",
     "let depth = celt_udiv(1 + pulses[i], n0) >> lm",
     "let depth = celt_udiv(pulses[i], n0) >> lm",
     "depth 的 1+pulses 丢掉 +1"),
    ("celt_anti_collapse.mbt",
     "let depth = celt_udiv(1 + pulses[i], n0) >> lm",
     "let depth = celt_udiv(1 + pulses[i], n0) >> (lm + 1)",
     "depth 的 >>LM 多移 1 位"),
    ("celt_anti_collapse.mbt",
     "let thresh = 0.5 *",
     "let thresh = 1.0 *",
     "thresh 的 0.5 系数改成 1"),
    ("celt_anti_collapse.mbt",
     "0.6931471805599453094 * (-0.125 * depth.to_double())",
     "0.6931471805599453094 * (-0.25 * depth.to_double())",
     "thresh 指数的 1/8 改成 1/4"),
    ("celt_anti_collapse.mbt",
     "let sqrt_1 = 1.0 / @math.pow((n0 << lm).to_double(), 0.5)",
     "let sqrt_1 = 1.0 / @math.pow(n0.to_double(), 0.5)",
     "sqrt_1 丢掉 <<LM 的短块缩放"),
    ("celt_anti_collapse.mbt",
     "if prev1_log_e[nb + i] > prev1 {",
     "if prev1_log_e[nb + i] < prev1 {",
     "C==1 的 prev1 max 分支改成 min"),
    ("celt_anti_collapse.mbt",
     "if thresh < r {\n      r = thresh\n    }",
     "if thresh > r {\n      r = thresh\n    }",
     "min(thresh, r) 反向成 max"),
    ("celt_anti_collapse.mbt",
     "r = r * 1.41421356",
     "r = r * 1.0",
     "LM=3 的 sqrt2 因子被去掉"),
    ("celt_anti_collapse.mbt",
     "if ((collapse_masks[i] >> k) & 1) == 0 {",
     "if ((collapse_masks[i] >> k) & 1) != 0 {",
     "塌缩位判定取反"),
    ("celt_anti_collapse.mbt",
     "if (rng & 0x8000L) != 0L { r } else { -r }",
     "if (rng & 0x4000L) != 0L { r } else { -r }",
     "噪声符号取 bit14 而非 bit15"),
    ("celt_anti_collapse.mbt",
     "x[base + (j << lm) + k] =",
     "x[base + j + k] =",
     "带内下标丢掉 j 的 <<LM 步长"),
    ("celt_anti_collapse.mbt",
     "if renormalize {\n      celt_renormalise_vector(x, base, n0 << lm, 1.0)",
     "if false {\n      celt_renormalise_vector(x, base, n0 << lm, 1.0)",
     "注入后的重新归一化被跳过"),
    ("celt_anti_collapse.mbt",
     "if is_transient && lm >= 2 && bits >= (lm + 2) << CEL_BITRES {",
     "if is_transient && lm >= 1 && bits >= (lm + 2) << CEL_BITRES {",
     "rsv 的 LM≥2 放宽到 LM≥1"),
    ("celt_anti_collapse.mbt",
     "bits >= (lm + 2) << CEL_BITRES {",
     "bits > (lm + 2) << CEL_BITRES {",
     "rsv 的预算条件从 >= 收到 >"),
    ("celt_anti_collapse.mbt",
     "  if rsv > 0 {\n    dec.dec_bits(1)",
     "  if rsv >= 0 {\n    dec.dec_bits(1)",
     "无预留时也读标志位"),
]


def run_test():
    r = subprocess.run(
        ["moon", "test"], capture_output=True, text=True, encoding="utf-8",
        errors="replace")
    return (r.stdout or "") + (r.stderr or "")


def main():
    results = []
    for path, old, new, desc in MUT:
        src = io.open(path, encoding="utf-8").read()
        if old not in src:
            results.append(("SKIP", desc, "锚点未找到"))
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
    bad = [d for s, d, _ in results if s in ("GREEN", "SKIP")]
    if bad:
        print("\n未被抓住的变异：", bad)
        raise SystemExit(1)
    print("\n全部变异均被测试捕获。")


if __name__ == "__main__":
    main()
