# -*- coding: utf-8 -*-
"""对反归一化做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess

MUT = [
    ("celt_denormalise.mbt",
     "let lg = band_log_e[i] + cel_e_means[i]",
     "let lg = band_log_e[i] - cel_e_means[i]",
     "eMeans 符号翻转（量纲错）"),
    ("celt_denormalise.mbt",
     "let lg = band_log_e[i] + cel_e_means[i]",
     "let lg = band_log_e[i] + cel_e_means[i + 1]",
     "eMeans 下标错位到相邻带"),
    ("celt_denormalise.mbt",
     "let g = @math.pow(2.0, if lg > 32.0 { 32.0 } else { lg })",
     "let g = @math.pow(2.0, lg)",
     "32 的上界截断被去掉"),
    ("celt_denormalise.mbt",
     "let g = @math.pow(2.0, if lg > 32.0 { 32.0 } else { lg })",
     "let g = @math.pow(2.0, (if lg > 32.0 { 32.0 } else { lg }) / 2.0)",
     "指数减半（幅度当成了能量）"),
    ("celt_denormalise.mbt",
     "let band_end = celt_eband(i + 1, m)",
     "let band_end = celt_eband(i + 1, m) - 1",
     "带的上界差一 bin"),
    ("celt_denormalise.mbt",
     "for i in start..<end {",
     "for i in 0..<CEL_NB_EBANDS {",
     "[start,end) 窗口被放宽到全带"),
    ("celt_denormalise.mbt",
     "if !silence {",
     "if true {",
     "静音守卫被去掉"),
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
