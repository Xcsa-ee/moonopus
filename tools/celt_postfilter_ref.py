# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.7.1 后滤波 comb_filter 的独立参考端。

与 MoonBit 侧的 celt_postfilter.mbt 分别依据 celt_celt.c 的
comb_filter / comb_filter_const（浮点路径）实现，彼此不共享代码路径
——gen_postfilter_goldens.py 把两边逐项比对。

结构差异（双独立的落点）：参考端过渡段也用**逐点直读**（每个 i 直接
按下标读历史与已插值的 y），MoonBit 端保持参考实现的**滑动状态**
（x1..x4 逐次平移）。两者数值等价：周期 t ≥ 15 保证每个读取位点都
在当前写入位点之前，原值/插值后值一致。

要点（浮点构建，QCONST16/MULT_COEF 全部恒等为普通乘加）：
  - 全零捷径：g0==g1==0 直接返回（就地即恒等）；
  - 周期钳到 ≥15，比较与取用都在钳制之后；
  - 过渡段 f = w[i]²：(1-f) 加权旧参数、f 加权新参数，逐点回读 y；
  - 参数全等（含 tapset）跳过过渡段；
  - 新增益 0 → 后段原样保留；否则常数段直接递推。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

MINPERIOD = 15

# RFC §4.3.7.1 的三组 tapset 系数（float 构建 QCONST16 恒等）
TAP_GAINS = [
    [0.306640625, 0.2170410156, 0.1296386719],
    [0.4638671875, 0.2680664062, 0.0],
    [0.7998046875, 0.1000976562, 0.0],
]


def comb_filter(buf, base, t0, t1, n, g0, g1, ts0, ts1, window):
    """就地滤波 buf[base, base+n)；window 长度即 overlap。"""
    if g0 == 0 and g1 == 0:
        return
    tp0 = t0 if t0 >= MINPERIOD else MINPERIOD
    tp1 = t1 if t1 >= MINPERIOD else MINPERIOD
    g00 = g0 * TAP_GAINS[ts0][0]
    g01 = g0 * TAP_GAINS[ts0][1]
    g02 = g0 * TAP_GAINS[ts0][2]
    g10 = g1 * TAP_GAINS[ts1][0]
    g11 = g1 * TAP_GAINS[ts1][1]
    g12 = g1 * TAP_GAINS[ts1][2]
    overlap = len(window)
    if g0 == g1 and tp0 == tp1 and ts0 == ts1:
        overlap = 0
    for i in range(overlap):
        f = window[i] * window[i]
        omf = 1.0 - f
        # 逐点直读：t≥15 保证所有读取位点先于当前写入位点，
        # 历史位点读原值、已插值位点读回写后的 y——与 C 的滑动状态等价
        v = buf[base + i]
        v = v + omf * g00 * buf[base + i - tp0]
        v = v + omf * g01 * (buf[base + i - tp0 + 1] +
                             buf[base + i - tp0 - 1])
        v = v + omf * g02 * (buf[base + i - tp0 + 2] +
                             buf[base + i - tp0 - 2])
        v = v + f * g10 * buf[base + i - tp1]
        v = v + f * g11 * (buf[base + i - tp1 + 1] +
                           buf[base + i - tp1 - 1])
        v = v + f * g12 * (buf[base + i - tp1 + 2] +
                           buf[base + i - tp1 - 2])
        buf[base + i] = v
    if g1 == 0:
        return
    for i in range(overlap, n):
        v = buf[base + i]
        v = v + g10 * buf[base + i - tp1]
        v = v + g11 * (buf[base + i - tp1 + 1] + buf[base + i - tp1 - 1])
        v = v + g12 * (buf[base + i - tp1 + 2] + buf[base + i - tp1 - 2])
        buf[base + i] = v
