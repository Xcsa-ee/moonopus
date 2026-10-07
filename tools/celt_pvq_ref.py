# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.4.2 PVQ 脉冲解码的独立 Python 参考端。

与 MoonBit 侧的 celt_pvq.mbt 分别依据 RFC 正文实现，彼此不共享代码路径。
刻意保持独立的地方：V(N,K) 在这里用**带缓存的递归**求值（规范原文说
"one line (or column) at a time... along with an alternate, univariate
recurrence... All of these methods are equivalent"），MoonBit 端用动态规划
逐行填表——两条不同的求值路径，任何一边的边界处理写错都会让结果分叉。

另外 MoonBit 的下标解码必须用 64 位（码本按 32 bits 设计），而 Python 的
int 无限精度，天然覆盖到 ft > 2**31 的那段——这正是金标要盯住的地方。
"""
import os
import sys
from functools import lru_cache

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: F402


@lru_cache(maxsize=None)
def pvq_v(n, k):
    """V(N,K)：K 个脉冲在 N 维的码字数（§4.3.4.2 的递归）。"""
    if n < 0 or k < 0:
        return 0
    if k == 0:
        return 1
    if n == 0:
        return 0
    return pvq_v(n - 1, k) + pvq_v(n, k - 1) + pvq_v(n - 1, k - 1)


def pvq_unindex(n, k, idx):
    """§4.3.4.2 的五步迭代：码字下标 → 脉冲向量。"""
    if n <= 0 or k <= 0:
        return [0] * max(n, 0)
    x = [0] * n
    kk = k
    for j in range(n):
        p0 = pvq_v(n - j - 1, kk)
        p = (p0 + pvq_v(n - j, kk)) // 2
        sgn = 1
        if idx >= p:
            sgn = -1
            idx -= p
        k0 = kk
        p -= p0
        while p > idx and kk > 0:
            kk -= 1
            p -= pvq_v(n - j - 1, kk)
        x[j] = sgn * (k0 - kk)
        idx -= p
    return x


def decode_pulses(dec, n, k, diag):
    """解一个 PVQ 脉冲向量。"""
    if n <= 0:
        return []
    if k <= 0:
        diag["p_k_zero"] = diag.get("p_k_zero", 0) + 1
        return [0] * n
    ft = pvq_v(n, k)
    if ft > 0x7FFFFFFF:
        diag["p_ft_32bit"] = diag.get("p_ft_32bit", 0) + 1
    if ft > 0xFFFFFFFF:
        diag["p_ft_over32"] = diag.get("p_ft_over32", 0) + 1
    idx = dec.decode_uint(ft)
    diag["p_calls"] = diag.get("p_calls", 0) + 1
    return pvq_unindex(n, k, idx)
