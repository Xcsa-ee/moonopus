# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.6 反归一化的独立 Python 参考端。

与 MoonBit 侧的 celt_denormalise.mbt 走两条不同的代码路径：

  - 实现端按带循环，把该带的增益直接乘进输出的对应区间；
  - 这里先给每个 bin 单独铺一张增益表，再整条向量逐点相乘。带界算错时
    两种结构的错法不同，金标会分叉。

数值上也不同路：增益走 math.exp2（底层 exp2），实现端走 @math.pow(2.0, x)
（底层 pow）。eMeans 取的也不是 MoonBit 用的那份浮点表，而是同一文件里
FIXED_POINT 的 Q4 整数表除以 16——两份定义任何一份被读岔，金标就对不上。
"""
import math
import os
import re

SHORT_MDCT = 120
NB_EBANDS = 21

# celt/modes.c 的 eband5ms：5ms 分辨率的频带边界，22 项。这里直接写成字面量
# 而不去读实现端的表，好让「带 → bin」这段映射也有一个独立于 MoonBit 的
# 来源（边界本身的正确性另有 RFC Table 55 的逐项比对兜底）。
EBAND5MS = [
    0, 1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 14, 16, 20, 24,
    28, 34, 40, 48, 60, 78, 100,
]

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUANT_BANDS = os.path.join(
    REPO, "..", "_research", "libopus", "celt_quant_bands.c")


def _brace_body(text, open_pos):
    """从 open_pos 处的 '{' 做括号配平，返回其内部文本。"""
    depth = 0
    i = open_pos
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[open_pos + 1 : i]
        i += 1
    raise SystemExit("unbalanced braces")


def _e_means_q4():
    """eMeans 的 FIXED_POINT 定义（Q4 整数），除以 16 还原成实际均值。"""
    with open(QUANT_BANDS, encoding="utf-8", errors="replace") as f:
        text = f.read()
    m = re.search(r"\beMeans\s*\[\s*25\s*\]\s*=\s*\{", text)
    if m is None:
        raise SystemExit(f"eMeans not found in {QUANT_BANDS}")
    body = _brace_body(text, m.end() - 1)
    body = re.sub(r"/\*.*?\*/", " ", body, flags=re.S)
    body = re.sub(r"//[^\n]*", " ", body)
    # 同名的浮点定义带小数点；取到它说明匹配到了错的那一份
    if "." in body or "/" in body:
        raise SystemExit("eMeans 取到的不是 Q4 整数定义")
    vals = [int(t) for t in re.findall(r"-?\d+", body)]
    if len(vals) != 25:
        raise SystemExit(f"eMeans 有 {len(vals)} 项，应为 25")
    if not all(0 < v <= 127 for v in vals):
        raise SystemExit(f"eMeans 超出 signed char 范围: {vals}")
    return [v / 16.0 for v in vals]


E_MEANS = _e_means_q4()


def check_mode():
    """表结构自检：带界必须严格递增、首 0 尾 100，且与带数吻合。"""
    if len(EBAND5MS) != NB_EBANDS + 1:
        raise SystemExit(f"eband5ms 有 {len(EBAND5MS)} 项，应为 22")
    if EBAND5MS[0] != 0 or EBAND5MS[-1] != 100:
        raise SystemExit(f"eband5ms 首尾应为 0/100，实际 {EBAND5MS[0]}/"
                         f"{EBAND5MS[-1]}")
    if any(b <= a for a, b in zip(EBAND5MS, EBAND5MS[1:])):
        raise SystemExit(f"eband5ms 不是严格递增: {EBAND5MS}")
    if len(E_MEANS) < NB_EBANDS:
        raise SystemExit(f"eMeans 只有 {len(E_MEANS)} 项，覆盖不了 21 个带")


def eband(i, m):
    return EBAND5MS[i] * m


def denormalise(x, band_log_e, start, end, m, silence):
    """反归一化：先铺增益表，再整条向量逐点相乘。

    置零发生在两处——静音直接整条为 0；非静音时带外 bin 的增益保持初值 0。
    """
    n = m * SHORT_MDCT
    gain = [0.0] * n
    if not silence:
        for i in range(start, end):
            lg = band_log_e[i] + E_MEANS[i]
            g = math.exp2(32.0 if lg > 32.0 else lg)
            for j in range(eband(i, m), eband(i + 1, m)):
                gain[j] = g
    return [x[j] * gain[j] for j in range(n)]


def shape(n):
    """确定性形状向量：取值 ∈ [-1, 1]，是 1/8 的倍数，有正有负也有零。"""
    return [((j * 13 + 5) % 17) / 8.0 - 1.0 for j in range(n)]


def loge_frac():
    """分数指数：lg = (i*7 % 13)/4 − 2，落在 −2..1 的四分之一格上。"""
    return [
        ((i * 7) % 13) / 4.0 - 2.0 - E_MEANS[i] for i in range(NB_EBANDS)
    ]


def loge_cap():
    """lg 恒为 40，越过实现端 32 的上界。"""
    return [40.0 - E_MEANS[i] for i in range(NB_EBANDS)]


def loge_deep():
    """lg 恒为 −20，增益小到 2^-20。"""
    return [-20.0 - E_MEANS[i] for i in range(NB_EBANDS)]
