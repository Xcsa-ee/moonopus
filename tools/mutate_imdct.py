# -*- coding: utf-8 -*-
"""对 IMDCT 与帧合成（§4.3.7）做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

MUT = [
    ("celt_imdct.mbt",
     "let a = two_pi * (i.to_double() + 0.125) / nd",
     "let a = two_pi * (i.to_double() + 0.375) / nd",
     "预旋转 trig 相位偏移 1/8 改 3/8"),
    ("celt_imdct.mbt",
     "t[2 * i] = 0.0 - @math.sin(a)",
     "t[2 * i] = @math.sin(a)",
     "trig −sin 号丢失"),
    ("celt_imdct.mbt",
     "let x1 = x[2 * i]",
     "let x1 = x[i]",
     "预旋转 x1 步长接错"),
    ("celt_imdct.mbt",
     "let x2 = x[n2 - 1 - 2 * i]",
     "let x2 = x[n2 - 1 - i]",
     "预旋转 x2 反向配对步长接错"),
    ("celt_imdct.mbt",
     "let yr = x2 * c + x1 * s",
     "let yr = x2 * c - x1 * s",
     "预旋转 yr 交叉项符号"),
    ("celt_imdct.mbt",
     "let yi = x1 * c - x2 * s",
     "let yi = x1 * c + x2 * s",
     "预旋转 yi 交叉项符号"),
    ("celt_imdct.mbt",
     "z[2 * i] = yi\n    z[2 * i + 1] = yr",
     "z[2 * i] = yr\n    z[2 * i + 1] = yi",
     "预旋转实虚槽交换"),
    ("celt_imdct.mbt",
     "tw[2 * m + 1] = 0.0 - @math.sin(a)",
     "tw[2 * m + 1] = @math.sin(a)",
     "DFT 指数符号反转"),
    ("celt_imdct.mbt",
     "let m = j * k % n4",
     "let m = (j + k) % n4",
     "DFT 旋转指数改 (j+k)"),
    ("celt_imdct.mbt",
     "let re = buf[yp0 + 1]\n    let im = buf[yp0]",
     "let re = buf[yp0]\n    let im = buf[yp0 + 1]",
     "后旋转首对实虚读反"),
    ("celt_imdct.mbt",
     "let u = n4 - i - 1",
     "let u = i",
     "后旋转第二对配对下标接错"),
    ("celt_imdct.mbt",
     "buf[yp1] = re2 * u1 + im2 * u0",
     "buf[yp1] = re2 * u0 + im2 * u1",
     "后旋转第二对 twiddle 接错"),
    ("celt_imdct.mbt",
     "let yp = base + (CEL_OVERLAP >> 1)",
     "let yp = base",
     "raw 起点丢掉 ov/2 偏移"),
    ("celt_imdct.mbt",
     "buf[base + i] = x2 * w2 - x1 * w1",
     "buf[base + i] = x2 * w2 + x1 * w1",
     "镜像首式符号"),
    ("celt_imdct.mbt",
     "buf[base + i] = x2 * w2 - x1 * w1",
     "buf[base + i] = x2 * w1 - x1 * w2",
     "镜像首式窗索引接反"),
    ("celt_imdct.mbt",
     "buf[base + ov - 1 - i] = x2 * w1 + x1 * w2",
     "buf[base + ov - 1 - i] = x2 * w1 - x1 * w2",
     "镜像次式符号"),
    ("celt_imdct.mbt",
     "x[k] = freq[b + blocks * k]",
     "x[k] = freq[blocks * b + k]",
     "瞬态交错取块接错"),
    ("celt_imdct.mbt",
     "let blocks = 1 << lm",
     "let blocks = 1",
     "瞬态按单块处理"),
    ("celt_imdct.mbt",
     "imdct_write_block(buf, CEL_SHORT_MDCT * b, x, 3, win)",
     "imdct_write_block(buf, CEL_SHORT_MDCT * b + 1, x, 3, win)",
     "瞬态块基准错位 1"),
    ("celt_imdct.mbt",
     "imdct_write_block(buf, 0, x, 3 - lm, win)",
     "imdct_write_block(buf, 0, x, 3, win)",
     "长块 shift 恒取 maxLM"),
    ("celt_imdct.mbt",
     "buf[i] = pending[i]",
     "buf[i] = pending[ov2 - 1 - i]",
     "上一帧尾反序"),
    ("celt_imdct.mbt",
     "new_pending[i] = buf[n_frame + i]",
     "new_pending[i] = buf[n_frame + CEL_OVERLAP / 2 + i]",
     "pending 尾巴取错区间（全 0）"),
    ("celt_imdct.mbt",
     "out[i] = buf[i]",
     "out[i] = buf[ov2 + i]",
     "帧输出丢掉头部混合区"),
    ("celt_mode.mbt",
     "half_pi * (i.to_double() + 0.5) / overlap.to_double()",
     "half_pi * i.to_double() / overlap.to_double()",
     "窗相位丢 +1/2（自互补破坏）"),
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
