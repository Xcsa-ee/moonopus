# -*- coding: utf-8 -*-
"""时域合成链参考端（RFC 6716 §4.3.7 / §4.3.7.1 / §4.3.7.2）。

与 MoonBit 端（celt_synthesis.mbt）刻意走不同结构：
  - IMDCT 复用 celt_imdct_ref.synth_frame（RFC 余弦和直算，另一条数值路径）；
  - comb 用 celt_postfilter_ref.comb_filter（逐点直读，无滑动状态）；
  - 历史 = Python 列表整体拼接与切片（无环形索引算术）；
  - 去重 emphasis 逐点直接递推。

语义逐行对应参考实现 celt_celt_decoder.c 正常帧路径：
  1508（OPUS_MOVE，等价拆为 pending/hist 两个缓冲）、1559（合成）、
  1563–1564（周期就地钳制）、1565–1571（两段 comb）、1574–1579（轮换）、
  1582–1584（LM≠0 时 old 同步）、1623（deemphasis）。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import celt_imdct_ref as imdct  # noqa: E402
import celt_postfilter_ref as spf  # noqa: E402

HIST = 1088  # 参考实现 DECODE_BUFFER_SIZE(2048) - 最大帧长(960)
DEEMPH_COEF = 0.8500061035  # 48 kHz alpha_p


def new_state():
    """全零初始状态（对应参考实现的 memset 清零）。"""
    return {
        "pending": [0.0] * (imdct.OVERLAP // 2),
        "hist": [0.0] * HIST,
        "pf_period_old": 0,
        "pf_gain_old": 0.0,
        "pf_tapset_old": 0,
        "pf_period": 0,
        "pf_gain": 0.0,
        "pf_tapset": 0,
        "deemph_mem": 0.0,
    }


def synth_frame(freq, lm, is_transient, pf_pitch, pf_gain, pf_tapset, st):
    """一帧 freq + 帧头后滤波参数 -> PCM；状态就地更新，返回 list[float]。"""
    n = imdct.SHORT_MDCT << lm
    out, new_pending = imdct.synth_frame(freq, lm, is_transient, st["pending"])
    work = st["hist"] + out
    h = len(st["hist"])
    # 周期就地钳制（轮换搬的是钳后值）
    st["pf_period"] = max(st["pf_period"], spf.MINPERIOD)
    st["pf_period_old"] = max(st["pf_period_old"], spf.MINPERIOD)
    win = imdct.celt_window()
    # 首段 [0,120)：旧 -> st->（LM=0 时即整帧）
    spf.comb_filter(work, h, st["pf_period_old"], st["pf_period"],
                    imdct.SHORT_MDCT, st["pf_gain_old"], st["pf_gain"],
                    st["pf_tapset_old"], st["pf_tapset"], win)
    if lm != 0:
        # 第二段 [120,N)：st-> -> 本帧帧头参数
        spf.comb_filter(work, h + imdct.SHORT_MDCT, st["pf_period"], pf_pitch,
                        n - imdct.SHORT_MDCT, st["pf_gain"], pf_gain,
                        st["pf_tapset"], pf_tapset, win)
    # 参数轮换（1574-1579）
    st["pf_period_old"] = st["pf_period"]
    st["pf_gain_old"] = st["pf_gain"]
    st["pf_tapset_old"] = st["pf_tapset"]
    st["pf_period"] = pf_pitch
    st["pf_gain"] = pf_gain
    st["pf_tapset"] = pf_tapset
    if lm != 0:
        # LM!=0：old 同步成本帧参数（1582-1584）
        st["pf_period_old"] = st["pf_period"]
        st["pf_gain_old"] = st["pf_gain"]
        st["pf_tapset_old"] = st["pf_tapset"]
    # 去重 emphasis：输入 = comb 后的本帧段
    m = st["deemph_mem"]
    pcm = [0.0] * n
    for j in range(n):
        tmp = work[h + j] + m
        pcm[j] = tmp
        m = DEEMPH_COEF * tmp
    st["deemph_mem"] = m
    # 历史滚动：丢最旧 n 个、保留其后 h 个
    st["hist"] = work[n:]
    st["pending"] = new_pending
    return pcm
