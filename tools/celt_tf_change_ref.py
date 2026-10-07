# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.4.5 TF 变换的独立 Python 参考端。

与 MoonBit 侧的 celt_tf_change.mbt 走两条不同的代码路径：

  - 实现端就地逐对扫描，每次直接改写向量的两个元素；
  - 这里把整条链先合成一个 N×N 变换矩阵（行追踪基向量的像），最后一次性
    乘到向量上。

结构参数也不用同一套推法：时间分辨率级数在这里按闭式

    time_divide = min(-tf_change, nb 中因子 2 的个数)

直接算，实现端用 while 循环逐级判断奇偶。任一侧算错，结果都会分叉。

反向链的 interleave 置换不是照抄索引公式，而是把 deinterleave 置换取逆
——两端如果写岔同一处，forward 金标与 inverse 金标会同时露出不一致。

Haar 归一常数取参考实现 celt/bands.c 的字面量 0.70710678（1/sqrt(2) 的
十进制近似），与实现端保持一致。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

HAAR_C = 0.70710678

# celt/bands.c 的 ordery_table；参考实现按 `ordery_table+stride-2` 取 stride 项。
ORDERERY = [
    1, 0,
    3, 0, 2, 1,
    7, 0, 4, 3, 6, 1, 5, 2,
    15, 0, 8, 7, 12, 3, 11, 4, 14, 1, 9, 6, 13, 2, 10, 5,
]


def v2(x):
    """因子 2 的个数；0 视为无穷（与实现端 `while (nb&1)==0` 的行为一致）。"""
    if x == 0:
        return 1 << 30
    t = 0
    while x % 2 == 0:
        x //= 2
        t += 1
    return t


def layout(n, b, tf_change):
    """TF 链结构。时间分辨率级数走闭式，与实现端的循环是两种推法。"""
    recombine = tf_change if tf_change > 0 else 0
    b_start = b >> recombine
    nb_start = (n // b) << recombine
    if tf_change < 0:
        time_divide = min(-tf_change, v2(nb_start))
    else:
        time_divide = 0
    b_end = b_start << time_divide
    nb_end = nb_start >> time_divide
    long_blocks = b == 1
    do_deint = b_end > 1
    n0 = nb_end >> recombine if do_deint else 0
    stride = b_end << recombine if do_deint else 0
    # 前向的时间分辨率 Haar 参数按应用次序；反向是它的逆序。
    td_fwd = [(nb_start >> i, b_start << i) for i in range(time_divide)]
    return {
        "recombine": recombine,
        "time_divide": time_divide,
        "td_fwd": td_fwd,
        "td_inv": list(reversed(td_fwd)),
        "rc": [(n >> k, 1 << k) for k in range(recombine)],
        "b_end": b_end,
        "nb_end": nb_end,
        "long_blocks": long_blocks,
        "deint": (n0, stride, long_blocks) if do_deint else None,
    }


def deinterleave_perm(n0, stride, hadamard):
    """交错序 → 分块序的置换 p：new[p 的位置 i] = old[p[i]]。"""
    total = n0 * stride
    p = [0] * total
    for i in range(stride):
        dst = ORDERERY[stride - 2 + i] if hadamard else i
        for j in range(n0):
            p[dst * n0 + j] = j * stride + i
    return p


def invert_perm(p):
    inv = [0] * len(p)
    for i, v in enumerate(p):
        inv[v] = i
    return inv


def ident(n):
    return [[1.0 if i == j else 0.0 for j in range(n)] for i in range(n)]


def compose_haar(M, n0, stride):
    """M ← E·M，E 是 (n0, stride) 的成对 Haar。E 每行至多两个非零元。"""
    half = n0 // 2
    for i in range(stride):
        for j in range(half):
            ia = stride * 2 * j + i
            ib = stride * (2 * j + 1) + i
            ra = M[ia]
            rb = M[ib]
            M[ia] = [HAAR_C * a + HAAR_C * b for a, b in zip(ra, rb)]
            M[ib] = [HAAR_C * a - HAAR_C * b for a, b in zip(ra, rb)]


def compose_perm(M, p):
    """M ← E·M，E 是置换 p 表示的行重排。只重排前 len(p) 行。"""
    L = len(p)
    M[:L] = [M[q] for q in p]


def forward_matrix(n, b, tf_change):
    lay = layout(n, b, tf_change)
    M = ident(n)
    for n0, s in lay["rc"]:
        compose_haar(M, n0, s)
    for n0, s in lay["td_fwd"]:
        compose_haar(M, n0, s)
    if lay["deint"] is not None:
        compose_perm(M, deinterleave_perm(*lay["deint"]))
    return M


def inverse_matrix(n, b, tf_change):
    lay = layout(n, b, tf_change)
    M = ident(n)
    if lay["deint"] is not None:
        compose_perm(M, invert_perm(deinterleave_perm(*lay["deint"])))
    for n0, s in lay["td_inv"]:
        compose_haar(M, n0, s)
    for n0, s in lay["rc"]:
        compose_haar(M, n0, s)
    return M


def apply_mat(M, x):
    return [sum(r[j] * x[j] for j in range(len(r))) for r in M]


def forward(n, b, tf_change, x):
    return apply_mat(forward_matrix(n, b, tf_change), x)


def inverse(n, b, tf_change, x):
    return apply_mat(inverse_matrix(n, b, tf_change), x)
