# -*- coding: utf-8 -*-
"""对位数↔脉冲换算做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess

MUT = [
    ("celt_pulse_cache.mbt",
     "cel_cache_index50[(lm + 1) * CEL_NB_EBANDS + band]\n  let mut lo = 0",
     "cel_cache_index50[lm * CEL_NB_EBANDS + band]\n  let mut lo = 0",
     "bits2pulses 查表行丢掉 LM+1 偏移"),
    ("celt_pulse_cache.mbt",
     "cel_cache_index50[(lm + 1) * CEL_NB_EBANDS + band]\n  if pulses == 0 {",
     "cel_cache_index50[lm * CEL_NB_EBANDS + band]\n  if pulses == 0 {",
     "pulses2bits 查表行丢掉 LM+1 偏移"),
    ("celt_pulse_cache.mbt",
     "cel_cache_bits50[off + mid].to_int() >= b",
     "cel_cache_bits50[off + mid].to_int() > b",
     "二分比较从 >= 收紧到 >"),
    ("celt_pulse_cache.mbt",
     "for _ in 0..<CEL_LOG_MAX_PSEUDO {",
     "for _ in 0..<(CEL_LOG_MAX_PSEUDO - 1) {",
     "定次二分从 6 轮减到 5 轮"),
    ("celt_pulse_cache.mbt",
     "if b - clo <= cel_cache_bits50[off + hi].to_int() - b {",
     "if b - clo < cel_cache_bits50[off + hi].to_int() - b {",
     "tie-break 从 <= 放宽到 <"),
    ("celt_pulse_cache.mbt",
     "let clo = if lo == 0 { -1 } else {",
     "let clo = if lo == 0 { 0 } else {",
     "lo==0 的 -1 特判被改成 0"),
    ("celt_pulse_cache.mbt",
     "let mid = (lo + hi + 1) >> 1",
     "let mid = (lo + hi) >> 1",
     "二分中点丢掉 +1 上取整"),
    ("celt_pulse_cache.mbt",
     "let b = bits - 1",
     "let b = bits",
     "输入位数的 -1 对齐被去掉"),
    ("celt_pulse_cache.mbt",
     "cel_cache_bits50[off + pulses].to_int() + 1",
     "cel_cache_bits50[off + pulses].to_int()",
     "pulses2bits 的 +1 被去掉"),
    ("celt_pulse_cache.mbt",
     "if pulses == 0 {\n    0\n  } else {",
     "if pulses < 0 {\n    0\n  } else {",
     "pulses2bits 的 0 特判失效"),
    ("celt_pulse_cache.mbt",
     "(8 + (i & 7)) << ((i >> 3) - 1)",
     "(8 + (i & 7)) << (i >> 3)",
     "get_pulses 左移量多 1 档"),
    ("celt_pulse_cache.mbt",
     "if i < 8 {",
     "if i < 7 {",
     "get_pulses 线性段边界 8 收到 7"),
    ("celt_tables.mbt",
     "222, 0, 0, 0, 0, 0, 0, 0, 0, 41",
     "222, 1, 0, 0, 0, 0, 0, 0, 0, 41",
     "index 表 band0/lm0 的条目偏移被篡改"),
    ("celt_tables.mbt",
     "40, 7, 7, 7, 7,",
     "40, 8, 7, 7, 7,",
     "bits 表首个位数槽被篡改"),
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
