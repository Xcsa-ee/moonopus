# -*- coding: utf-8 -*-
"""对展宽旋转做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess

MUT = [
    ("celt_exp_rotation.mbt",
     "if spread == 0 || 2 * k >= n {",
     "if 2 * k >= n {",
     "spread=0 的早退被去掉"),
    ("celt_exp_rotation.mbt",
     "if spread == 0 || 2 * k >= n {",
     "if spread == 0 {",
     "2k≥n 的早退被去掉"),
    ("celt_exp_rotation.mbt",
     "if spread == 0 || 2 * k >= n {",
     "if spread == 0 || 2 * k > n {",
     "早退边界从 ≥ 放宽到 >（2k=n 不再跳过）"),
    ("celt_exp_rotation.mbt",
     "if spread >= 3 { 5 } else if spread >= 2 { 10 } else { 15 }",
     "if spread >= 3 { 15 } else if spread >= 2 { 10 } else { 5 }",
     "f_r 档位 15 与 5 对调"),
    ("celt_exp_rotation.mbt",
     "let g = n.to_double() / (n + factor * k).to_double()",
     "let g = n.to_double() / (n + factor).to_double()",
     "增益分母丢掉 k"),
    ("celt_exp_rotation.mbt",
     "let theta = @math.PI * g * g / 4.0",
     "let theta = @math.PI * g * g / 2.0",
     "θ 的系数 4 改 2（角度翻倍）"),
    ("celt_exp_rotation.mbt",
     "if n >= 8 * b {",
     "if n >= 4 * b {",
     "交错相位阈值 8 放宽到 4"),
    ("celt_exp_rotation.mbt",
     "rot_pairs(x, base, block, stride2, s, c)",
     "rot_pairs(x, base, block, stride2, c, s)",
     "交错相位系数没换成 (s,c)"),
    ("celt_exp_rotation.mbt",
     "rot_pairs(x, base, block, 1, c, s)",
     "rot_pairs(x, base, block, 1, s, c)",
     "主相位系数被换成 (s,c)"),
    ("celt_exp_rotation.mbt",
     "    if stride2 > 0 {\n"
     "      rot_pairs(x, base, block, stride2, s, c)\n"
     "    }\n"
     "    rot_pairs(x, base, block, 1, c, s)",
     "    rot_pairs(x, base, block, 1, c, s)\n"
     "    if stride2 > 0 {\n"
     "      rot_pairs(x, base, block, stride2, s, c)\n"
     "    }",
     "两个相位的先后顺序颠倒"),
    ("celt_exp_rotation.mbt",
     "for blk in 0..<b {",
     "for blk in 0..<1 {",
     "时间块循环退化成只做第一块"),
    ("celt_exp_rotation.mbt",
     "while i < len - stride {",
     "while i < len - 2 * stride {",
     "前向扫描范围收窄"),
    ("celt_exp_rotation.mbt",
     "let mut j = len - 2 * stride - 1",
     "let mut j = len - stride - 1",
     "回扫起点放宽（多回扫一对）"),
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
