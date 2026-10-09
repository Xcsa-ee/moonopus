# -*- coding: utf-8 -*-
"""CELT 帧级解码主流程（RFC 6716 §4.3 频域段）的独立参考端。

与 MoonBit 侧的 celt_frame.mbt 分别依据 celt_celt_decoder.c 的
celt_decode_frame 解码主路径实现，彼此不共享编排代码——
gen_frame_goldens.py 把两边逐项比对。

范围与参考实现一致：CELT-only、单声道、无损路径（无丢包安全衰减、
无 backgroundLogE、effEnd==end）。部件函数复用各子步已通过金标
交叉验证的参考端；本文件独立实现的是顺序、门控与帧间状态轮换：

  1. 入口 MAXG 保护（前半 ← max(前半, 上一帧拷贝)）；
  2. 帧首四符号 → 粗能量 → TF → spread → boost/trim →
     反塌缩预留（1/8 bit）→ 比特分配 → 细能量；
  3. 形状解码（预算 = 整帧 1/8 bit − 预留，seed 来自跨帧 st->rng）；
  4. 反塌缩标志位 → 收尾细能量 → 反塌缩 → 静音置 -28 → 反归一化；
  5. 状态轮换：后半拷贝、长块整体下移一代 / 瞬态取历史最小
     （均 42 项）、st->rng = dec->rng。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_frame_header_ref import decode_frame_header  # noqa: E402
from celt_energy_ref import (  # noqa: E402
    coarse_energy, fine_energy, energy_finalise,
)
from celt_tf_ref import decode_tf, decode_spread  # noqa: E402
from celt_alloc_flags_ref import decode_alloc_flags  # noqa: E402
from celt_alloc_ref import init_caps, alloc_total, compute_allocation  # noqa: E402
from celt_quant_all_bands_ref import quant_all_bands  # noqa: E402
from celt_anti_collapse_ref import anti_collapse, anti_collapse_rsv  # noqa: E402
from celt_denorm_ref import denormalise  # noqa: E402

NB_EBANDS = 21
BITRES = 3


class FrameState:
    """跨帧状态（oldBandE/oldLogE/oldLogE2 各 42 项 + st->rng）。"""

    def __init__(self):
        self.old_e = [0.0] * 42
        self.old_log_e = [0.0] * 42
        self.old_log_e2 = [0.0] * 42
        self.rng = 0


def decode_frame(dec, frame_bytes, start, end, lm, state, diag):
    """解一帧的频域部分，返回帧结果字典并就地更新 state。"""
    m = 1 << lm
    nb = NB_EBANDS

    # 参考实现解码入口的 MAXG 保护（C==1）
    for i in range(nb):
        if state.old_e[nb + i] > state.old_e[i]:
            state.old_e[i] = state.old_e[nb + i]

    header = decode_frame_header(dec, frame_bytes, start, lm, diag)

    coarse_energy(dec, state.old_e, start, end, header["intra"], lm, diag)
    tf_res = decode_tf(
        dec, start, end, header["is_transient"], lm, frame_bytes, diag)
    spread = decode_spread(dec, frame_bytes, diag)

    cap = init_caps(lm, 1)
    offsets, alloc_trim = decode_alloc_flags(
        dec, start, end, cap, frame_bytes, lm, diag)

    bits = alloc_total(frame_bytes, dec)
    rsv = anti_collapse_rsv(header["is_transient"], lm, bits)
    if rsv:
        diag["r_frsv"] = diag.get("r_frsv", 0) + 1
    bits -= rsv

    alloc = compute_allocation(
        dec, start, end, offsets, cap, alloc_trim, bits, lm, diag)
    fine_energy(dec, state.old_e, start, end, alloc["ebits"], diag)

    x = [0.0] * (120 * m)
    masks = [0] * nb
    seed = quant_all_bands(
        dec, x, start, end, lm, header["is_transient"], alloc["pulses"],
        tf_res, alloc["coded_bands"],
        frame_bytes * (8 << BITRES) - rsv, alloc["balance"], spread,
        state.rng, masks, diag)

    anti_on = 0
    if rsv:
        anti_on = dec.dec_bits(1)
        diag["r_anti_on" if anti_on else "r_anti_off"] = \
            diag.get("r_anti_on" if anti_on else "r_anti_off", 0) + 1
    energy_finalise(
        dec, state.old_e, start, end, alloc["ebits"],
        alloc["fine_priority"], frame_bytes * 8 - dec.tell(), diag)
    if anti_on:
        anti_collapse(
            x, masks, lm, start, end, state.old_e, state.old_log_e,
            state.old_log_e2, alloc["pulses"], seed, diag)

    if header["silence"]:
        for i in range(nb):
            state.old_e[i] = -28.0
        diag["r_silence"] = diag.get("r_silence", 0) + 1

    freq = denormalise(x, state.old_e, start, end, m, header["silence"])

    # ---- 帧间状态轮换 ----
    for i in range(nb):
        state.old_e[nb + i] = state.old_e[i]
    if not header["is_transient"]:
        for i in range(42):
            state.old_log_e2[i] = state.old_log_e[i]
            state.old_log_e[i] = state.old_e[i]
    else:
        for i in range(42):
            if state.old_log_e[i] > state.old_e[i]:
                state.old_log_e[i] = state.old_e[i]
    state.rng = dec.rng

    return {
        "header": header,
        "spectrum": x,
        "freq": freq,
        "masks": masks,
        "seed": seed,
    }
