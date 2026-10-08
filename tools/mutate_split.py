# -*- coding: utf-8 -*-
"""对 split 解码（θ 量化与递归分割）做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess

MUT = [
    ("celt_theta.mbt",
     "let q2 = b - pulse_cap - (4 << CEL_BITRES)",
     "let q2 = b - pulse_cap - (8 << CEL_BITRES)",
     "compute_qn 预算截断的 4 放宽到 8"),
    ("celt_theta.mbt",
     "if qb < 1 << CEL_BITRES >> 1 {",
     "if qb < 1 {",
     "qn=1 的阈值从 4 收到 1"),
    ("celt_theta.mbt",
     "cel_exp2_table8[qb & 0x7] >> (14 - (qb >> CEL_BITRES))",
     "cel_exp2_table8[qb & 0x3] >> (14 - (qb >> CEL_BITRES))",
     "exp2 表索引掩码 7 改 3"),
    ("celt_theta.mbt",
     "(qn + 1) >> 1 << 1",
     "qn >> 1 << 1",
     "qn 进偶丢掉 +1"),
    ("celt_theta.mbt",
     "if stereo && n == 2 {\n    n2 -= 1\n  }",
     "if stereo && n == 4 {\n    n2 -= 1\n  }",
     "两相模式的 N==2 条件改成 N==4"),
    ("celt_theta.mbt",
     "x = fs / p0",
     "x = fs / (p0 + 1)",
     "阶梯 PDF 除数 p0 加 1"),
    ("celt_theta.mbt",
     "} else if blocks0 > 1 || stereo {",
     "} else if blocks > 1 || stereo {",
     "均匀 PDF 判据用分割后的 B 而非 B0"),
    ("celt_theta.mbt",
     "fsym = itheta + 1",
     "fsym = itheta + 2",
     "三角 PDF 下半支的 fsym 加 1 改 2"),
    ("celt_theta.mbt",
     "fsym = qn + 1 - itheta",
     "fsym = qn - itheta",
     "三角 PDF 上半支的 fsym 丢掉 +1"),
    ("celt_theta.mbt",
     "inv = dec.decode_bit_logp(2)",
     "inv = dec.decode_bit_logp(1)",
     "inv 符号的 logp 从 2 改 1"),
    ("celt_theta.mbt",
     "delta = -16384",
     "delta = -8192",
     "itheta==0 的 delta 边界值减半"),
    ("celt_theta.mbt",
     "-7651 + celt_frac_mul16(tmp, 8277 + celt_frac_mul16(-626, tmp))",
     "-7650 + celt_frac_mul16(tmp, 8277 + celt_frac_mul16(-626, tmp))",
     "bitexact_cos 多项式常量 -7651 加 1"),
    ("celt_partition.mbt",
     "+ 12 && n > 2 {",
     "+ 12 && n > 3 {",
     "分割的 N>2 条件放宽到 N>3"),
    ("celt_partition.mbt",
     "if lm != -1 && b >",
     "if lm > 0 && b >",
     "分割的 LM 到顶判定从 -1 改 0"),
    ("celt_partition.mbt",
     "let mut mbits = celt_sudiv(b_mid - delta, 2)",
     "let mut mbits = celt_sudiv(b_mid + delta, 2)",
     "mid/side 位数划分的 delta 符号取反"),
    ("celt_partition.mbt",
     "if rebalance > 3 << CEL_BITRES && itheta != 0 {",
     "if rebalance > 2 << CEL_BITRES && itheta != 0 {",
     "rebalance 门槛从 24 收到 16"),
    ("celt_partition.mbt",
     "q -= 1",
     "q -= 2",
     "预算循环的 q 递减步长改 2"),
    ("celt_partition.mbt",
     "pulses = celt_decode_pulses(dec, n, celt_get_pulses(q))",
     "pulses = celt_decode_pulses(dec, n, celt_get_pulses(q + 1))",
     "叶解码的 K 多取一档伪脉冲"),
    ("celt_partition.mbt",
     "lm - 1,\n      n2,\n      b,",
     "lm,\n      n2,\n      b,",
     "compute_theta 收到未减 1 的 LM"),
    ("celt_partition.mbt",
     "        fill_theta >> blocks_half,",
     "        fill_theta >> (blocks_half + 1),",
     "side 子树的 fill 移位多移 1 位"),
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
    bad = [d for s, d, _ in results if s == "GREEN"]
    if bad:
        print("\n未被抓住的变异：", bad)
        raise SystemExit(1)
    print("\n全部变异均被测试捕获。")


if __name__ == "__main__":
    main()
