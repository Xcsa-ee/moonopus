# -*- coding: utf-8 -*-
"""生成 TF 变换（RFC 6716 §4.3.4.5）的 MoonBit 金标。

参考端在 tools/celt_tf_change_ref.py（矩阵连乘路径），本文件负责挑用例、
构造输入向量、生成 MoonBit 调用与断言。

落盘前先在参考端自检三件事，避免把坏掉的参考当成金标发出去：
  1. 闭式 time_divide 与照抄实现的 while 循环逐例相等（两种推法互验）；
  2. 反向链确能把前向链的结果还原回去；
  3. 用例不是平凡的——向量确实被改动了，否则金标等于没测。

用例按 (n, b, tf_change) 的**结构组合**挑，覆盖四条分支：
长块帧的时间对折（走 seqency 序重排）、瞬态帧的重排、频率重组合、
以及两个「该跳过重排」的门。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from celt_tf_change_ref import forward, inverse, layout  # noqa: E402
from _fmt import moon_fmt  # noqa: E402


def fmt(v):
    """Double → MoonBit 字面量。MoonBit 不吃 `1e-6` 这种指数写法，所以
    repr 里带指数时改用定点展开——34 位小数对 |v| ≥ 1e-16 恰好放得下
    17 位有效数字，能精确往返。"""
    v = float(v)
    s = repr(v)
    if "e" in s or "E" in s:
        s = f"{v:.34f}".rstrip("0")
        if s.endswith("."):
            s += "0"
    assert float(s) == v, f"无法往返: {s} != {v!r}"
    return s


def input_vec(n):
    """确定性输入：取值是 k/11 - 1，既有正又有负，且不会出现接近 0 的
    极小量（最小非零幅度 1/11），字面量里不会落到指数表示。"""
    return [(((i * 37 + 11) % 23) / 11.0) - 1.0 for i in range(n)]


def time_divide_by_loop(n, b, tf_change):
    """照抄实现端 while 循环的推法，用来和闭式互验。"""
    nb_start = (n // b) << (tf_change if tf_change > 0 else 0)
    nb = nb_start
    tc = tf_change
    td = 0
    while (nb & 1) == 0 and tc < 0:
        nb //= 2
        td += 1
        tc += 1
    return td


CASES = [
    # (n, b, tf_change, 是否整条链一步都不做, 标签)
    (96, 1, -1, False, "长块帧 时间对折 1 级 · seqency 重排 stride=2"),
    (96, 1, -2, False, "长块帧 时间对折 2 级 · seqency 重排 stride=4"),
    (96, 1, -3, False, "长块帧 时间对折 3 级 · seqency 重排 stride=8"),
    (24, 1, -2, False, "短带长块帧 · 时间对折 2 级"),
    (8, 1, -1, False, "最小时间对折"),
    (96, 1, 1, False, "频率重组合 1 级 · 重排被门挡住"),
    (96, 1, 3, False, "频率重组合 3 级 · 重排被门挡住"),
    (4, 1, 1, False, "极窄带频率重组合"),
    (96, 2, -1, False, "两时间块 时间对折"),
    (24, 2, -1, False, "两时间块 奇数带宽 · 时间对折跳过"),
    (96, 8, -1, False, "瞬态帧 M=8 时间对折 · 重排走恒等序"),
    (96, 8, 1, False, "瞬态帧 M=8 频率重组合 · 重排走恒等序"),
    (96, 8, 3, False, "瞬态帧 M=8 重组合 3 级 · 重排被门挡住"),
    (24, 8, 0, False, "瞬态帧 M=8 无 TF 变化 · 只重排"),
    (3, 1, -2, True, "奇数带宽 · 不进时间对折循环"),
    (96, 1, 0, True, "长块帧 无 TF 变化 · 整条链空转"),
]


def check_ref():
    for n, b, tc, noop, _ in CASES:
        lay = layout(n, b, tc)
        want = time_divide_by_loop(n, b, tc)
        assert lay["time_divide"] == want, (
            f"({n},{b},{tc}) 闭式 time_divide={lay['time_divide']} != 循环 {want}")
        x = input_vec(n)
        fwd = forward(n, b, tc, x)
        if noop:
            assert fwd == x, f"({n},{b},{tc}) 本该空转，前向却改动了向量"
            assert inverse(n, b, tc, x) == x, (
                f"({n},{b},{tc}) 本该空转，反向却改动了向量")
            continue
        y = inverse(n, b, tc, fwd)
        # 往返误差由 Haar 归一常数决定（一次往返 1 − 3.36e-9），不是数值噪声
        for a, c in zip(x, y):
            assert abs(a - c) <= 1e-6 * (1.0 + abs(a)), (
                f"({n},{b},{tc}) 参考端自身不互逆: {a} -> {c}")
        if all(abs(p - q) <= 1e-12 for p, q in zip(x, fwd)):
            raise SystemExit(
                f"({n},{b},{tc}) 前向变换没有改动向量，用例是平凡的")


def fmt_vec(vals):
    return "[" + ", ".join(fmt(v) for v in vals) + "]"


def main():
    check_ref()
    lines = [
        "\n".join([
            "// 由 tools/gen_tf_change_goldens.py 生成，请勿手改。",
            "//",
            "// TF 变换（§4.3.4.5）金标：输入向量与期望输出由本脚本里的独立",
            "// 参考端算出——它把整条链合成一个变换矩阵再一次性乘到向量上，",
            "// 与实现端的就地逐对扫描是两条不同代码路径；时间分辨率级数也走",
            "// 闭式而非循环。",
            "//",
            "// 每例同时比前向与反向两条链。",
            "",
            "///|",
            "",
        ]),
    ]
    for k, (n, b, tc, _noop, label) in enumerate(CASES):
        x = input_vec(n)
        fwd = forward(n, b, tc, x)
        inv = inverse(n, b, tc, x)
        lines.append("\n".join([
            "",
            "///|",
            f"fn tfc_in{k}() -> Array[Double] {{",
            f"  {fmt_vec(x)}",
            "}",
            "",
            "///|",
            f"let tfc_f{k} : Array[Double] = {fmt_vec(fwd)}",
            "",
            "///|",
            f"let tfc_i{k} : Array[Double] = {fmt_vec(inv)}",
            "",
            "///|",
            f'test "金标：TF 变换 · {label}" {{',
            f"  let x = tfc_in{k}()",
            f"  celt_tf_forward(x, {n}, {b}, {tc})",
            f'  expect_tfc_close(x, tfc_f{k}, "tfc{k}/fwd", 0.000000001)',
            f"  let y = tfc_in{k}()",
            f"  celt_tf_inverse(y, {n}, {b}, {tc})",
            f'  expect_tfc_close(y, tfc_i{k}, "tfc{k}/inv", 0.000000001)',
            "}",
            "",
        ]))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "tf_change_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    print(f"[ok] {len(CASES)} cases -> tf_change_goldens_wbtest.mbt")
    moon_fmt()


if __name__ == "__main__":
    main()
