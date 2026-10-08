# -*- coding: utf-8 -*-
"""对 quant_all_bands 主循环（§4.3.4）做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

MUT = [
    ("celt_quant_all_bands.mbt",
     "    let tell = dec.tell_frac()",
     "    let tell = dec.tell()",
     "账目用 ec_tell 整位数替代 tell_frac"),
    ("celt_quant_all_bands.mbt",
     "      bal -= tell",
     "      bal -= tell + 1",
     "首带后 balance 多减 1"),
    ("celt_quant_all_bands.mbt",
     "    bal += pulses[i] + tell",
     "    bal += pulses[i]",
     "带尾 balance 少加 tell"),
    ("celt_quant_all_bands.mbt",
     "    let remaining_bits = total_bits - tell - 1",
     "    let remaining_bits = total_bits - tell",
     "剩余预算丢掉 -1 项"),
    ("celt_quant_all_bands.mbt",
     "    if i <= coded_bands - 1 {",
     "    if i <= coded_bands {",
     "coded_bands 边界多算一带"),
    ("celt_quant_all_bands.mbt",
     "let denom = if coded_bands - i < 3 { coded_bands - i } else { 3 }",
     "let denom = if coded_bands - i < 2 { coded_bands - i } else { 3 }",
     "curr_balance 除数上限 3 改 2"),
    ("celt_quant_all_bands.mbt",
     "let t2 = if remaining_bits + 1 < t1 { remaining_bits + 1 } else { t1 }",
     "let t2 = if remaining_bits < t1 { remaining_bits } else { t1 }",
     "b 夹逼丢掉 +1"),
    ("celt_quant_all_bands.mbt",
     "b = if t2 < 0 { 0 } else if t2 > 16383 { 16383 } else { t2 }",
     "b = if t2 < 0 { 0 } else if t2 > 100 { 100 } else { t2 }",
     "b 上限 16383 收到 100"),
    ("celt_quant_all_bands.mbt",
     "    if cond1 && (update_lowband || lowband_offset == 0) {",
     "    if cond1 && (update_lowband && lowband_offset == 0) {",
     "折叠源推进条件或改与"),
    ("celt_quant_all_bands.mbt",
     "          norm[n1 + j] = norm[2 * n1 - n2 + j]",
     "          norm[n1 + j] = norm[n2 - n1 + j]",
     "hybrid folding 补拷源下标写错"),
    ("celt_quant_all_bands.mbt",
     "if lowband_offset != 0 && (spread != 3 || blocks > 1 || tf_change < 0) {",
     "if lowband_offset != 0 && (spread != 3 || blocks > 1 || tf_change <= 0) {",
     "保守 cm 估计的 tf 判定 < 改 <="),
    ("celt_quant_all_bands.mbt",
     "      while celt_eband(fold_start, m) > t_lo {",
     "      while celt_eband(fold_start, m) >= t_lo {",
     "fold_start 扫描下界 > 改 >="),
    ("celt_quant_all_bands.mbt",
     "      while fold_end + 1 < i && celt_eband(fold_end + 1, m) < t_lo + n {",
     "      while fold_end + 1 < i && celt_eband(fold_end + 1, m) <= t_lo + n {",
     "fold_end 扫描上界 < 改 <="),
    ("celt_quant_all_bands.mbt",
     "      while f < fold_end {",
     "      while f <= fold_end {",
     "cm 按位或的带区间右端多含一"),
    ("celt_quant_all_bands.mbt",
     "      x_cm = (1 << blocks) - 1",
     "      x_cm = (1 << blocks)",
     "无折叠源 fill 丢掉 -1"),
    ("celt_quant_all_bands.mbt",
     "    rng = seed2",
     "    rng = seed",
     "跨带 seed 不再线程化"),
    ("celt_quant_all_bands.mbt",
     "    masks[i] = cm",
     "    masks[i] = 0",
     "collapse mask 不写回"),
    ("celt_quant_all_bands.mbt",
     "    update_lowband = b > n << CEL_BITRES",
     "    update_lowband = b < n << CEL_BITRES",
     "update_lowband 判定反转"),
    ("celt_quant_all_bands.mbt",
     "      let pos = celt_eband(i, m) - norm_offset",
     "      let pos = celt_eband(i, m) - norm_offset + 1",
     "lowband_out 写回 norm 偏移 +1"),
    ("celt_quant_all_bands.mbt",
     "    if effective >= 0 {\n      // 镜像参考实现对 norm 的就地前向变换副作用",
     "    if effective > 0 {\n      // 镜像参考实现对 norm 的就地前向变换副作用",
     "norm 就地变换写回跳过 effective==0"),
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
    bad = [d for s, d, _ in results if s == "GREEN"]
    if bad:
        print("\n未被抓住的变异：", bad)
        raise SystemExit(1)
    print("\n全部变异均被测试捕获。")


if __name__ == "__main__":
    main()
