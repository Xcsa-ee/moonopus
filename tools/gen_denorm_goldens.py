# -*- coding: utf-8 -*-
"""生成反归一化（RFC 6716 §4.3.6）的 MoonBit 金标。

参考端在 tools/celt_denorm_ref.py（先铺逐 bin 增益表 + math.exp2），本
文件负责挑用例、构造输入、生成 MoonBit 调用与断言。

落盘前先在参考端自检四件事，避免把坏掉的参考当成金标发出去：
  1. 带表结构对（首 0 尾 100、严格递增）；
  2. 恒等增益能把每带被编码的 bin 都覆盖到——包括 max_bin 之后那段，
     x 在那里非零，少写一段就会露出来；
  3. 上界用例确实得到 2^32，而不是 2^40；
  4. 分数指数用例不是平凡的，且相邻带的 lg 互不相同——相同的话带界错位
     也测不出来。

静音、带外置零这类「输出全 0」的断言不进金标文件，直接写在白盒测试里，
省掉整段全零数组。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _fmt import moon_fmt, moon_num  # noqa: E402
from celt_denorm_ref import (  # noqa: E402
    E_MEANS,
    NB_EBANDS,
    SHORT_MDCT,
    check_mode,
    denormalise,
    eband,
    loge_cap,
    loge_deep,
    loge_frac,
    shape,
)

IDENTITY = [-E_MEANS[i] for i in range(NB_EBANDS)]

# (m, start, end, 静音, 能量形态, 标签)
CASES = [
    (1, 0, 21, False, "frac", "2.5ms 全带"),
    (2, 0, 21, False, "frac", "5ms 全带"),
    (4, 0, 21, False, "frac", "10ms 全带"),
    (8, 0, 21, False, "frac", "20ms 全带"),
    (4, 1, 17, False, "frac", "起始带 1、终止带 17"),
    (4, 0, 9, False, "frac", "窄带宽 end=9"),
    (2, 3, 12, False, "frac", "起始带 3、终止带 12"),
    (4, 0, 21, False, "cap", "lg=40 截到上界 32"),
    (4, 0, 21, False, "deep", "lg=−20 的极低增益"),
    (1, 0, 1, False, "frac", "单带 2.5ms"),
]

LOGE = {"frac": loge_frac, "cap": loge_cap, "deep": loge_deep}


def check_ref():
    check_mode()

    # 1. 恒等增益：每个被编码的 bin 都要被写到；end 之后必须置 0
    m, n = 1, 1 * SHORT_MDCT
    x = shape(n)
    got = denormalise(x, IDENTITY, 0, NB_EBANDS, m, False)
    tail = eband(NB_EBANDS, m)
    assert got[:tail] == x[:tail], "恒等增益没有还原被编码的 bin，带有缺口"
    assert got[tail:] == [0.0] * (n - tail), "end 之后的 bin 没有置 0"
    assert any(v != 0 for v in x[tail:]), (
        "x 在 end 之后全为 0，置零这条检查是平凡的")

    # 2. 上界：lg=40 必须被截到 32（只看被编码的 bin）
    x4 = shape(4 * SHORT_MDCT)
    cap = denormalise(x4, loge_cap(), 0, NB_EBANDS, 4, False)
    t4 = eband(NB_EBANDS, 4)
    assert all(g == v * 4294967296.0
               for g, v in zip(cap[:t4], x4[:t4])), (
        "lg=40 没有被截到 2^32")
    assert cap[t4:] == [0.0] * (len(x4) - t4), "end 之后的 bin 没有置 0"

    # 3. 静音整条为 0
    quiet = denormalise(x4, loge_frac(), 0, NB_EBANDS, 4, True)
    assert quiet == [0.0] * len(x4), "静音输出不全为 0"

    # 4. 分数指数用例既不平凡，相邻带的 lg 也互不相同
    frac = loge_frac()
    lg = [frac[i] + E_MEANS[i] for i in range(NB_EBANDS)]
    out = denormalise(x4, frac, 0, NB_EBANDS, 4, False)
    assert out != x4, "分数指数用例没有改动输出"
    assert any(a != b for a, b in zip(lg, lg[1:])), (
        "相邻带 lg 相同，带界错位测不出来")


def fmt_vec(vals):
    return "[" + ", ".join(moon_num(v) for v in vals) + "]"


def main():
    check_ref()
    lines = [
        "\n".join([
            "// 由 tools/gen_denorm_goldens.py 生成，请勿手改。",
            "//",
            "// 反归一化（§4.3.6）金标：输入与期望输出由",
            "// tools/celt_denorm_ref.py 算出。它先给每个 bin 铺一张增益表",
            "// 再整条向量逐点相乘，实现端则是按带循环直接写输出；增益一侧",
            "// 走 math.exp2，实现端走 @math.pow；eMeans 一边取自 Q4 整数表",
            "// ÷16，一边取自浮点表。三处分叉点各不相同。",
            "//",
            "// 期望输出是精确值还是带容差，取决于 2^lg 能否落成二进制分数：",
            "// lg 为整数时两边都精确，lg 是四分之一格时走 1e-12 相对容差。",
            "",
            "///|",
            "",
        ]),
    ]
    for k, (m, start, end, silence, kind, label) in enumerate(CASES):
        n = m * SHORT_MDCT
        x = shape(n)
        loge = LOGE[kind]()
        freq = denormalise(x, loge, start, end, m, silence)
        assert any(v != 0.0 for v in x), f"case {k} 的 x 全为 0"
        lines.append("\n".join([
            "",
            "///|",
            f"let dn{k}_x : Array[Double] = {fmt_vec(x)}",
            "",
            "///|",
            f"let dn{k}_loge : Array[Double] = {fmt_vec(loge)}",
            "",
            "///|",
            f"let dn{k}_freq : Array[Double] = {fmt_vec(freq)}",
            "",
            "///|",
            f'test "金标：反归一化 · {label}" {{',
            f"  let got = celt_denormalise(dn{k}_x, dn{k}_loge,"
            f" {start}, {end}, {m}, {str(silence).lower()})",
            f'  expect_dn_close(got, dn{k}_freq, "dn{k}", 0.000000000001)',
            "}",
            "",
        ]))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "denorm_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    print(f"[ok] {len(CASES)} cases -> denorm_goldens_wbtest.mbt")
    moon_fmt()


if __name__ == "__main__":
    main()
