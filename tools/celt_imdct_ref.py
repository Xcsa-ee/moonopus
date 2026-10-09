# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.7 IMDCT 与帧合成缓冲的独立参考端。

与 MoonBit 侧的 celt_imdct.mbt 分别依据 RFC 直接定义（IMDCT 余弦和 +
1/2 缩放）与 FFT 实现，彼此不共享代码路径——gen_imdct_goldens.py 把
两边逐项比对。

要点（与 mdct.c / celt_decoder.c 浮点路径对齐的约定）：
  - IMDCT：M 系数 -> 2M 样本，y[m] = 1/2 · sum_k X[k]·cos(pi/M·(m+1/2+M/2)·(k+1/2))；
  - 合成缓冲 raw = y[M/2 .. 3M/2)（乘 1 已含于 2×1/2——参考端直接给
    yf[M/2:3M/2] · 2）；
  - 跨帧衔接：上一帧 raw 尾部 overlap/2 个样本先置于缓冲头部，再对
    [0, overlap) 做镜像混合：
        out[i]     = old[i]·w[L-1-i] - old[L-1-i]·w[i]
        out[L-1-i] = old[i]·w[i]     + old[L-1-i]·w[L-1-i]
    其中 w[i] = sin(pi/2 · sin^2(pi/2·(i+1/2)/L))，L = overlap = 120；
  - 瞬态帧：B=8 个 120 系数块，频谱按 freq[b + B·k] 交错取块，逐块
    raw/mirror 链接（块内偏移 120·b），帧首块的 front-60 即上一帧尾；
  - 帧输出 = 缓冲 [0, N)，新 pending = 缓冲 [N, N+60)。

raw 位姿恒等式（数值钉定，gen 端复核）：raw[m] = 2·yf[m + M/2]。
"""
import math

L_N = 1920            # clt_mdct_init(2*shortMdctSize*nbShortMdcts)
OVERLAP = 120         # mode->overlap = (shortMdctSize>>2)<<2
SHORT_MDCT = 120
MAX_LM = 3


def celt_window(overlap=OVERLAP):
    """modes.c float: w[i] = sin(pi/2 · sin^2(pi/2·(i+.5)/overlap))."""
    return [
        math.sin(0.5 * math.pi * math.sin(
            0.5 * math.pi * (i + 0.5) / overlap) ** 2)
        for i in range(overlap)]


def imdct_direct(x, scale=0.5):
    """RFC §4.3.7 直接定义：M 系数 -> 2M 样本的余弦和。"""
    m_len = len(x)
    out = []
    for m in range(2 * m_len):
        acc = 0.0
        base = math.pi / m_len * (m + 0.5 + m_len / 2)
        for k in range(m_len):
            if x[k] != 0.0:
                acc += x[k] * math.cos(base * (k + 0.5))
        out.append(scale * acc)
    return out


def _gather_block(freq, b, blocks, m_len):
    """瞬态交错布局 freq[b + blocks·k] -> 第 b 块的系数序列。"""
    if blocks == 1:
        return freq[:m_len]
    return [freq[b + blocks * k] for k in range(m_len)]


def _raw_block(x):
    """单块 raw：y[M/2 .. 3M/2)（含 2×1/2 = 1）。"""
    yf = imdct_direct(x, 0.5)
    m_len = len(x)
    half = m_len // 2
    return [2.0 * v for v in yf[half: half + m_len]]


def synth_frame(freq, lm, is_transient, pending, window=None):
    """一帧 freq -> 时域帧输出与新 pending。

    pending = 上一帧 raw 尾部 overlap/2 个样本（首帧全 0）。
    返回 (out_frame[N], new_pending[overlap/2])。
    """
    if window is None:
        window = celt_window()
    ov2 = OVERLAP // 2
    n_frame = SHORT_MDCT << lm
    # 缓冲布局同 out_syn：[0, ov2) = 上一帧尾，[ov2, ov2+N) = 本帧 raw
    buf = list(pending) + [0.0] * (n_frame + OVERLAP - ov2)
    if is_transient:
        blocks = 1 << lm
        for b in range(blocks):
            base = SHORT_MDCT * b
            raw = _raw_block(_gather_block(freq, b, blocks, SHORT_MDCT))
            for s in range(SHORT_MDCT):
                buf[ov2 + base + s] = raw[s]
            _mirror(buf, base, window)
    else:
        raw = _raw_block(freq[:n_frame])
        for s in range(n_frame):
            buf[ov2 + s] = raw[s]
        _mirror(buf, 0, window)
    out = buf[:n_frame]
    new_pending = buf[n_frame: n_frame + ov2]
    return out, new_pending


def _mirror(buf, base, window):
    """对缓冲 [base, base+overlap) 就地做 TDAC 镜像混合。"""
    ov = OVERLAP
    old = buf[base: base + ov]
    for i in range(ov // 2):
        x1 = old[ov - 1 - i]
        x2 = old[i]
        buf[base + i] = x2 * window[ov - 1 - i] - x1 * window[i]
        buf[base + ov - 1 - i] = x2 * window[i] + x1 * window[ov - 1 - i]
