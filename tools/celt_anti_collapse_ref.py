# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.5 Anti-collapse 的独立参考端。

与 MoonBit 侧的 celt_anti_collapse.mbt 分别依据 celt_bands.c 的
anti_collapse 与 celt_vq.c 的 renormalise_vector（浮点构建路径）实现，
彼此不共享代码路径——gen_anti_collapse_goldens.py 把两边逐项比对。

要点（浮点构建，单位与 §4.3.2 能量状态一致的 log2 幅度域）：
  - depth = (1+pulses)/N0 >> LM（1/8 bit 每 bin），
    thresh = 0.5 * 2^(-depth/8)；
  - Ediff = logE - min(prev1, prev2)，下限 0；单声道解码时 prev 再与
    2*nbEBands 布局中本带的第二半（声道 1 槽位）取 max——照搬参考实现
    的 `!encode && C==1` 分支；
  - 塌缩带注入幅度 r = min(thresh, 2*2^(-Ediff) * [LM=3 时 x sqrt2])
    / sqrt(N0<<LM)，符号来自 celt_lcg_rand 的 bit15（uint32 环绕）；
  - 注入后对该带区间做 gain=1 的 renormalise（EPSILON 防零除）。
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from celt_alloc_ref import NB_EBANDS, T  # noqa: E402

# celt_exp2 的常量（celt_mathops.h：exp(0.6931471805599453094 * x)）
LN2 = 0.6931471805599453094
EPSILON = 1e-15
LCG_A = 1664525
LCG_C = 1013904223


def celt_exp2(x):
    return math.exp(LN2 * x)


def lcg_rand(seed):
    """celt_lcg_rand：uint32 环绕的线性同余。"""
    return (LCG_A * seed + LCG_C) & 0xFFFFFFFF


def renormalise_vector(x, off, n, gain):
    """renormalise_vector 的浮点路径：x *= gain/sqrt(EPSILON+sum(x^2))。"""
    e = EPSILON
    for j in range(n):
        v = x[off + j]
        e += v * v
    g = (1.0 / math.pow(e, 0.5)) * gain
    for j in range(n):
        x[off + j] = g * x[off + j]


def anti_collapse(x, collapse_masks, lm, start, end,
                  loge, prev1loge, prev2loge, pulses, seed, diag):
    """原地解 §4.3.5 的反塌缩（单声道解码路径），diag 记录覆盖键。

    seed 按值传入（参考实现里 st->rng 是拷贝，反塌缩不改解码器状态），
    这里推进到函数末的值仅供测试观察。
    """
    m = 1 << lm
    nb = NB_EBANDS
    eb = T["eband5ms"]
    if lm == 3:
        diag["a_lm3"] = diag.get("a_lm3", 0) + 1
    for i in range(start, end):
        n0 = eb[i + 1] - eb[i]
        depth = ((1 + pulses[i]) // n0) >> lm
        if depth == 0:
            diag["a_depth0"] = diag.get("a_depth0", 0) + 1
        thresh = 0.5 * celt_exp2(-0.125 * depth)
        sqrt_1 = 1.0 / math.pow(n0 << lm, 0.5)
        prev1 = prev1loge[i]
        prev2 = prev2loge[i]
        # 参考实现的 `!encode && C==1` 分支：与 2*nbEBands 布局的
        # 声道 1 槽位取 max（该槽位对单声道是未参与的占位值）
        if prev1loge[nb + i] > prev1 or prev2loge[nb + i] > prev2:
            diag["a_quirk"] = diag.get("a_quirk", 0) + 1
        prev1 = max(prev1, prev1loge[nb + i])
        prev2 = max(prev2, prev2loge[nb + i])
        ediff = loge[i] - min(prev1, prev2)
        if ediff < 0:
            diag["a_ediff_clamp"] = diag.get("a_ediff_clamp", 0) + 1
            ediff = 0
        r = 2.0 * celt_exp2(-ediff)
        if lm == 3:
            r *= 1.41421356
        if r > thresh:
            diag["a_thresh_cap"] = diag.get("a_thresh_cap", 0) + 1
        r = min(thresh, r)
        r = r * sqrt_1
        base = eb[i] * m
        renormalize = False
        full = (1 << m) - 1
        if (collapse_masks[i] & full) == full:
            diag["a_no_fill_band"] = diag.get("a_no_fill_band", 0) + 1
        elif (collapse_masks[i] & full) == 0:
            diag["a_full_fill_band"] = diag.get("a_full_fill_band", 0) + 1
        for k in range(m):
            if ((collapse_masks[i] >> k) & 1) == 0:
                diag["a_fill"] = diag.get("a_fill", 0) + 1
                for j in range(n0):
                    seed = lcg_rand(seed)
                    x[base + (j << lm) + k] = r if (seed & 0x8000) else -r
                renormalize = True
        if renormalize:
            renormalise_vector(x, base, n0 << lm, 1.0)


def anti_collapse_rsv(is_transient, lm, bits):
    """anti_collapse_rsv（celt_decoder.c）：瞬态且 LM≥2 且预算够才预留。"""
    if is_transient and lm >= 2 and bits >= ((lm + 2) << 3):
        return 1 << 3
    return 0
