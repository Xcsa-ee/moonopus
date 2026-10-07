# -*- coding: utf-8 -*-
"""对 TF 变换做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess

MUT = [
    ("celt_tf_change.mbt",
     "      x[ib] = t1 - t2",
     "      x[ib] = t2 - t1",
     "haar1 符号翻转"),
    ("celt_tf_change.mbt",
     "    let src = if hadamard { cel_orderery[stride - 2 + i] } else { i }",
     "    let src = i",
     "反向重排忽略 seqency 序"),
    ("celt_tf_change.mbt",
     "    let dst = if hadamard { cel_orderery[stride - 2 + i] } else { i }",
     "    let dst = i",
     "前向重排忽略 seqency 序"),
    ("celt_tf_change.mbt",
     "  while (nb & 1) == 0 && tc < 0 {",
     "  while tc < 0 {",
     "时间对折的偶数门被去掉"),
    ("celt_tf_change.mbt",
     "  let long_blocks = b == 1",
     "  let long_blocks = b != 1",
     "长块帧判定翻转"),
    ("celt_tf_change.mbt",
     "  let recombine = if tf_change > 0 { tf_change } else { 0 }",
     "  let recombine = if tf_change > 0 { tf_change + 1 } else { 0 }",
     "频率重组合级数 +1（只应被金标抓住）"),
    ("celt_tf_change.mbt",
     "    celt_haar1(x, n >> k, 1 << k)",
     "    celt_haar1(x, n >> k, 1 << (k + 1))",
     "前向重组合的步长错位"),
    ("celt_tf_change.mbt",
     "  let do_deint = b_end > 1",
     "  let do_deint = b_end > 0",
     "重排的门放宽到 b_end > 0"),
]


def run_test():
    r = subprocess.run(
        ["moon", "test"], capture_output=True, text=True, encoding="utf-8",
        errors="replace")
    out = (r.stdout or "") + (r.stderr or "")
    return out


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
