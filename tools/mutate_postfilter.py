# -*- coding: utf-8 -*-
"""对后滤波（§4.3.7.1）做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

MUT = [
    ("celt_postfilter.mbt",
     "0.2170410156,",
     "0.2180410156,",
     "tapset0 g1 表值写错"),
    ("celt_postfilter.mbt",
     "let g01 = g0 * cel_tap_gains[3 * ts0 + 1]",
     "let g01 = g0 * cel_tap_gains[3 * ts0 + 2]",
     "g0 邻项抽头接错"),
    ("celt_postfilter.mbt",
     "let g10 = g1 * cel_tap_gains[3 * ts1]",
     "let g10 = g1 * cel_tap_gains[3 * ts1 + 1]",
     "g1 DC 抽头接错"),
    ("celt_postfilter.mbt",
     "let tp0 = if t0 < CEL_COMB_MINPERIOD { CEL_COMB_MINPERIOD } else { t0 }",
     "let tp0 = if t0 < 0 { CEL_COMB_MINPERIOD } else { t0 }",
     "t0 丢周期钳制"),
    ("celt_postfilter.mbt",
     "let tp1 = if t1 < CEL_COMB_MINPERIOD { CEL_COMB_MINPERIOD } else { t1 }",
     "let tp1 = if t1 < 0 { CEL_COMB_MINPERIOD } else { t1 }",
     "t1 丢周期钳制"),
    ("celt_postfilter.mbt",
     "pub const CEL_COMB_MINPERIOD : Int = 15",
     "pub const CEL_COMB_MINPERIOD : Int = 16",
     "最小周期基准改 16"),
    ("celt_postfilter.mbt",
     "if g0 == g1 && tp0 == tp1 && ts0 == ts1 {",
     "if g0 == g1 {",
     "过渡段捷径判据过宽"),
    ("celt_postfilter.mbt",
     "let f = w * w",
     "let f = w",
     "窗平方丢一次方"),
    ("celt_postfilter.mbt",
     "acc = acc + omf * g00 * buf[base + i - tp0]",
     "acc = acc + g00 * buf[base + i - tp0]",
     "(1-f) 权重丢失"),
    ("celt_postfilter.mbt",
     "acc = acc + omf * g00 * buf[base + i - tp0]",
     "acc = acc + f * g00 * buf[base + i - tp0]",
     "旧参数误用 f 加权"),
    ("celt_postfilter.mbt",
     "acc = acc + f * g10 * x2",
     "acc = acc + f * g10 * x0",
     "新参数 DC 项取错滑动样本"),
    ("celt_postfilter.mbt",
     "acc = acc + f * g10 * x2",
     "acc = acc + omf * g10 * x2",
     "新参数误用 (1-f) 加权"),
    ("celt_postfilter.mbt",
     "acc = acc + omf * g02 * (buf[base + i - tp0 + 2] + buf[base + i - tp0 - 2])",
     "acc = acc + omf * g02 * (buf[base + i - tp0 + 3] + buf[base + i - tp0 - 3])",
     "T0 邻域 ±2 改 ±3"),
    ("celt_postfilter.mbt",
     "acc = acc + omf * g01 * (buf[base + i - tp0 + 1] + buf[base + i - tp0 - 1])",
     "acc = acc + omf * g01 * (buf[base + i - tp0 + 1] - buf[base + i - tp0 - 1])",
     "T0 -1 邻项符号"),
    ("celt_postfilter.mbt",
     "let mut x1 = buf[base - tp1 + 1]",
     "let mut x1 = buf[base - tp0 + 1]",
     "f 分支历史取 T0"),
    ("celt_postfilter.mbt",
     "acc = acc + g10 * buf[base + i - tp1]",
     "acc = acc + g10 * buf[base + i - tp0]",
     "常数段误用 T0"),
    ("celt_postfilter.mbt",
     "if g1 == 0.0 {",
     "if g0 == 0.0 {",
     "零增益分支判据接错"),
    ("celt_postfilter.mbt",
     "let w = win[i]",
     "let w = win[CEL_OVERLAP - 1 - i]",
     "过渡窗索引取反"),
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
