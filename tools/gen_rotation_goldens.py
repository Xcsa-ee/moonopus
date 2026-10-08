# -*- coding: utf-8 -*-
"""生成展宽旋转（RFC 6716 §4.3.4.3）的 MoonBit 金标。

参考端在 tools/celt_rotation_ref.py（residue 链分解 + 参考宏结构的 c/s），
本文件负责挑用例、构造输入、生成 MoonBit 调用与断言。

落盘前先在参考端自检，避免把坏掉的参考当成金标发出去：
  1. 每个用例都真的被转动、范数保持、逐项有限；
  2. spread=0 与 2k≥n 的早退确实原样返回；
  3. 输入非零且非回文——对称向量会掩盖回扫丢半边这类方向性错误；
  4. 用例表覆盖到：交错相位开（n≥8b）与关（n<8b）、b=1/2/4、
     spread 三档、奇数长与 n 刚过 8 的边界。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _fmt import moon_fmt, moon_num  # noqa: E402
from celt_rotation_ref import norm2, rotation  # noqa: E402

# (n, b, k, spread, 标签)
CASES = [
    (4, 1, 1, 1, "最小带 4 维 · 仅主相位 · spread=1"),
    (4, 1, 1, 3, "最小带 4 维 · spread=3"),
    (6, 1, 1, 2, "奇数长 6 · 回扫起点不对称"),
    (7, 1, 1, 2, "n=7 刚好没有交错相位"),
    (8, 1, 1, 2, "n=8 刚好启用交错相位"),
    (9, 1, 1, 2, "n=9 奇数长且有交错相位"),
    (16, 1, 1, 2, "stride 按 round(sqrt(n)) 取"),
    (16, 1, 3, 1, "多脉冲 · spread=1"),
    (48, 2, 1, 1, "双时间块 · 有交错相位"),
    (24, 4, 1, 2, "四时间块 · 每块 6 样本无交错相位"),
    (64, 2, 2, 3, "双时间块 · spread=3"),
    (128, 4, 4, 2, "大带 128 维 · 4 块"),
]


def shape(n):
    """确定性非对称输入：约 [−1, 1)，既非零也非回文。"""
    return [
        ((j * 7919 + 104729) % 1000003) / 500001.5 - 1.0
        for j in range(n)
    ]


def check_ref():
    # 1. 逐例：非平凡 + 范数保持 + 逐项有限
    for n, b, k, spread, label in CASES:
        x = shape(n)
        out = rotation(x, b, k, spread)
        assert out != x, f"{label}: 旋转没有改动输出"
        e0, e1 = norm2(x), norm2(out)
        assert abs(e1 - e0) <= 1e-12 * (1.0 + e0), f"{label}: 范数 {e0} -> {e1}"
        assert all(v == v and abs(v) != float("inf") for v in out), (
            f"{label}: 输出含 NaN/inf")

    # 2. 两个早退
    x = shape(16)
    assert rotation(x, 1, 3, 0) == x, "spread=0 早退失效"
    x = shape(8)
    assert rotation(x, 1, 4, 2) == x, "2k>=n 早退失效"

    # 3. 输入非回文（回文会掩盖回扫方向错误）
    for n, _, _, _, label in CASES:
        x = shape(n)
        assert x != x[::-1], f"{label}: 输入是回文"

    # 4. 用例表的结构覆盖
    assert any(n >= 8 * b for n, b, _, _, _ in CASES), "缺交错相位开的用例"
    assert any(n < 8 * b for n, b, _, _, _ in CASES), "缺交错相位关的用例"
    assert {b for _, b, _, _, _ in CASES} >= {1, 2, 4}, "b 档不全"
    assert {s for _, _, _, s, _ in CASES} == {1, 2, 3}, "spread 档不全"
    assert any(n % 2 == 1 for n, _, _, _, _ in CASES), "缺奇数长用例"


def fmt_vec(vals):
    return "[" + ", ".join(moon_num(v) for v in vals) + "]"


def main():
    check_ref()
    lines = [
        "\n".join([
            "// 由 tools/gen_rotation_goldens.py 生成，请勿手改。",
            "//",
            "// 展宽旋转（§4.3.4.3）金标：期望输出由",
            "// tools/celt_rotation_ref.py 算出。它按 residue 链分解做扫描、",
            "// c/s 走参考宏结构 cos(π/2·g²/2) 与 cos(π/2·(1−g²/2))、f_r 表是",
            "// 字面量；实现端是全局双向扫描、RFC 结构 cos(πg²/4) 与",
            "// sin(πg²/4)、f_r 表是档位判断。三处分叉点各不相同。",
            "// 两侧同为双精度，比对容差 1e-12 只给公式排布的舍入留余地。",
            "",
            "///|",
            "",
        ]),
    ]
    for k, (n, b, pulses, spread, label) in enumerate(CASES):
        x = shape(n)
        out = rotation(x, b, pulses, spread)
        lines.append("\n".join([
            "",
            "///|",
            f"let ro{k}_x : Array[Double] = {fmt_vec(x)}",
            "",
            "///|",
            f"let ro{k}_out : Array[Double] = {fmt_vec(out)}",
            "",
            "///|",
            f'test "金标：展宽旋转 · {label}" {{',
            f"  let v = ro{k}_x.copy()",
            f"  celt_exp_rotation(v, {b}, {pulses}, {spread})",
            f'  expect_rot_close(v, ro{k}_out, "ro{k}", 0.000000000001)',
            "}",
            "",
        ]))
    out_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "exp_rotation_goldens_wbtest.mbt",
    )
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    print(f"[ok] {len(CASES)} cases -> exp_rotation_goldens_wbtest.mbt")
    moon_fmt()


if __name__ == "__main__":
    main()
