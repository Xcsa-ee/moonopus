# -*- coding: utf-8 -*-
"""band 级量化解码（RFC 6716 §4.3.4 Shape Decoding）的独立参考端。

与 MoonBit 侧的 celt_quant_band.mbt / celt_partition.mbt 分别依据
celt_bands.c 的 quant_band + quant_partition 解码侧实现，彼此不共享
代码路径——gen_quant_band_goldens.py 把两边逐项比对。

四段结构（与 C 相同的先后）：
  1. n==1：预算够读 1 个 raw bit 作符号，输出 ±1；
  2. 前段：fill 位图做 TF 变换、折叠源做前向 TF 变换；
  3. 中段：递归分割 + 叶上谱应用（gain/√Σy² 归一化、展宽旋转、
     q==0 的噪声/折叠填充与重归一化、lcg seed 消费、cm 累积）；
  4. 后段：tf_inverse 还原频序、cm 反变换掩蔽、可选 lowband_out。
复用：compute_theta（celt_split_ref）、PVQ 解码（celt_pvq_ref）、
旋转（celt_rotation_ref）、归一化与 lcg（celt_anti_collapse_ref）。
"""
import math
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_celt_tables import read_src  # noqa: E402
from gen_pulse_cache_goldens import (  # noqa: E402
    bits2pulses_binary,
    get_pulses,
    pbits,
)
from celt_split_ref import compute_theta, load_cache, sudiv  # noqa: E402
from celt_pvq_ref import decode_pulses  # noqa: E402
from celt_rotation_ref import rotation  # noqa: E402
from celt_anti_collapse_ref import (  # noqa: E402
    lcg_rand,
    renormalise_vector,
)

BITRES = 3
NB_EBANDS = 21
# celt_bands.c 的两张 4 bit 表（字面量转写，生成器断言与实现侧一致）
BIT_INTERLEAVE = [0, 1, 1, 1, 2, 3, 3, 3, 2, 3, 3, 3, 2, 3, 3, 3]
BIT_DEINTERLEAVE = [
    0x00, 0x03, 0x0C, 0x0F, 0x30, 0x33, 0x3C, 0x3F,
    0xC0, 0xC3, 0xCC, 0xCF, 0xF0, 0xF3, 0xFC, 0xFF,
]


def load_ordery():
    """从 celt_bands.c 解析 ordery_table（N=2,4,8,16 四行共 30 项）。"""
    text = read_src("celt_bands.c")
    m = re.search(r"ordery_table\[\]\s*=\s*\{([^}]*)\}", text)
    if not m:
        raise SystemExit("ordery_table not found in celt_bands.c")
    vals = [int(x) for x in re.findall(r"\d+", m.group(1))]
    if len(vals) != 30:
        raise SystemExit(f"ordery_table {len(vals)} != 30")
    return vals


ORDERY = load_ordery()


def haar1(x, n0, stride):
    """celt_bands.c 的 haar1（float 路径，归一常数 0.70710678 字面量）。"""
    n0 >>= 1
    c = 0.70710678
    for i in range(stride):
        for j in range(n0):
            a = i + stride * 2 * j
            b = i + stride * (2 * j + 1)
            t1 = c * x[a]
            t2 = c * x[b]
            x[a] = t1 + t2
            x[b] = t1 - t2


def deinterleave(x, n0, stride, hadamard):
    """celt_bands.c 的 deinterleave_hadamard。"""
    total = n0 * stride
    tmp = [0.0] * total
    if hadamard:
        ordery = ORDERY[stride - 2:]
        for i in range(stride):
            for j in range(n0):
                tmp[ordery[i] * n0 + j] = x[j * stride + i]
    else:
        for i in range(stride):
            for j in range(n0):
                tmp[i * n0 + j] = x[j * stride + i]
    x[:total] = tmp


def interleave(x, n0, stride, hadamard):
    """celt_bands.c 的 interleave_hadamard（deinterleave 的逆）。"""
    total = n0 * stride
    tmp = [0.0] * total
    if hadamard:
        ordery = ORDERY[stride - 2:]
        for i in range(stride):
            for j in range(n0):
                tmp[j * stride + i] = x[ordery[i] * n0 + j]
    else:
        for i in range(stride):
            for j in range(n0):
                tmp[j * stride + i] = x[i * n0 + j]
    x[:total] = tmp


def tf_layout(n, b, tf_change):
    """TF 链结构（对应实现侧 celt_tf_layout，由 (n, b, tf_change) 定）。"""
    recombine = tf_change if tf_change > 0 else 0
    b_start = b // (1 << recombine)
    nb_start = n // b * (1 << recombine)
    bb, nb, tc, td = b_start, nb_start, tf_change, 0
    while (nb & 1) == 0 and tc < 0:
        bb *= 2
        nb //= 2
        td += 1
        tc += 1
    do_deint = bb > 1
    return {
        "recombine": recombine,
        "time_divide": td,
        "b_start": b_start,
        "nb_start": nb_start,
        "b_end": bb,
        "nb_end": nb,
        "deint_n0": nb // (1 << recombine) if do_deint else 0,
        "deint_stride": bb << recombine if do_deint else 0,
        "long_blocks": b == 1,
    }


def tf_forward(x, n, b, tf_change):
    """解码前对折叠源的前向变换（C 前段对 lowband 的那组操作）。"""
    lay = tf_layout(n, b, tf_change)
    for k in range(lay["recombine"]):
        haar1(x, n >> k, 1 << k)
    bb, nb, td = lay["b_start"], lay["nb_start"], 0
    while td < lay["time_divide"]:
        haar1(x, nb, bb)
        bb *= 2
        nb //= 2
        td += 1
    if lay["deint_stride"] > 0:
        deinterleave(x, lay["deint_n0"], lay["deint_stride"],
                     lay["long_blocks"])


def tf_inverse(x, n, b, tf_change):
    """解码后把量化域向量还原到频序（C resynth 段的 X 变换）。"""
    lay = tf_layout(n, b, tf_change)
    if lay["deint_stride"] > 0:
        interleave(x, lay["deint_n0"], lay["deint_stride"],
                   lay["long_blocks"])
    bb, nb, td = lay["b_end"], lay["nb_end"], 0
    while td < lay["time_divide"]:
        bb //= 2
        nb *= 2
        haar1(x, nb, bb)
        td += 1
    for k in range(lay["recombine"]):
        haar1(x, n >> k, 1 << k)


def fill_transform(fill, lay):
    """带级 fill 位图的 TF 变换（C 前段循环的 fill 部分）。"""
    f = fill
    for _ in range(lay["recombine"]):
        f = BIT_INTERLEAVE[f & 0xF] | (BIT_INTERLEAVE[f >> 4] << 2)
    bb = lay["b_start"]
    for _ in range(lay["time_divide"]):
        f = f | (f << bb)
        bb = bb << 1
    return f


def cm_transform(cm, lay):
    """cm 的反向 TF 变换（C resynth 段的 cm 部分）。"""
    c = cm
    bb = lay["b_end"]
    for _ in range(lay["time_divide"]):
        bb = bb >> 1
        c = c | (c >> bb)
    for _ in range(lay["recombine"]):
        c = BIT_DEINTERLEAVE[c]
    bb = bb << lay["recombine"]
    return c & ((1 << bb) - 1)


def extract_collapse_mask(y, n, blocks):
    """celt_vq.c 的 extract_collapse_mask。"""
    if blocks <= 1:
        return 1
    n0 = n // blocks
    mask = 0
    for i in range(blocks):
        t = 0
        for j in range(n0):
            t |= y[i * n0 + j]
        if t != 0:
            mask |= 1 << i
    return mask


def fill_sample(seed):
    """噪声填充样本：u32 按 int32 重解释后算术右移 20 位。"""
    sv = seed & 0xFFFFFFFF
    iv = sv - 0x100000000 if sv >= 0x80000000 else sv
    return float(iv >> 20)


def quant_band(dec, x, lowband, band, lm, n, b, blocks, tf_change, fill,
               gain, spread, seed, remaining, lowband_out, diag):
    """band 级解码。x/lowband/lowband_out 均为长度 n 的带内数组。

    lowband / lowband_out 传 None 表示无折叠源 / 不写折叠预缩放。
    返回 (cm, seed, remaining)。
    """
    if n == 1:
        rem = remaining
        sign = 0
        if rem >= (1 << BITRES):
            sign = dec.dec_bits(1)
            rem -= 1 << BITRES
        x[0] = -1.0 if sign != 0 else 1.0
        if lowband_out is not None:
            lowband_out[0] = x[0]
        diag["q_n1"] = diag.get("q_n1", 0) + 1
        return 1, seed, rem
    lay = tf_layout(n, blocks, tf_change)
    if lay["recombine"]:
        diag["q_recombine"] = diag.get("q_recombine", 0) + 1
    if lay["time_divide"]:
        diag["q_time"] = diag.get("q_time", 0) + 1
    if lay["deint_stride"]:
        diag["q_deint"] = diag.get("q_deint", 0) + 1
    fill_t = fill_transform(fill, lay)
    if lowband is not None:
        diag["q_lowband"] = diag.get("q_lowband", 0) + 1
        tf_forward(lowband, n, blocks, tf_change)
    index, bits = load_cache()
    state = {"seed": seed}

    def rec(lm, n, b, blocks, fill, remaining, x_off, lb_off, gain):
        blocks0 = blocks
        off = index[(lm + 1) * NB_EBANDS + band]
        kmax = bits[off]
        if lm != -1 and b > bits[off + kmax] + 12 and n > 2:
            diag["q_split"] = diag.get("q_split", 0) + 1
            n2 = n >> 1
            fill_mid = fill
            if blocks == 1:
                fill_mid = (fill & 1) | (fill << 1)
            blocks_half = (blocks + 1) >> 1
            sctx, b_mid, fill_theta = compute_theta(
                dec, band, lm - 1, n2, b, blocks_half, blocks0, False, 0,
                remaining, False, fill_mid, diag)
            remaining_after = remaining - sctx["qalloc"]
            delta = sctx["delta"]
            itheta = sctx["itheta"]
            if blocks0 > 1 and (itheta & 0x3FFF):
                if itheta > 8192:
                    delta = delta - (delta >> (4 - (lm - 1)))
                else:
                    t = delta + ((n2 << BITRES) >> (5 - (lm - 1)))
                    delta = t if t < 0 else 0
            mbits = max(0, min(b_mid, sudiv(b_mid - delta, 2)))
            sbits = b_mid - mbits
            rebalance0 = remaining_after
            g_mid = gain * (sctx["imid"] / 32768.0)
            g_side = gain * (sctx["iside"] / 32768.0)
            if mbits >= sbits:
                remaining_after, cm_mid = rec(
                    lm - 1, n2, mbits, blocks_half, fill_theta,
                    remaining_after, x_off, lb_off, g_mid)
                rebalance = mbits - (rebalance0 - remaining_after)
                sbits_r = sbits
                if rebalance > (3 << BITRES) and itheta != 0:
                    sbits_r += rebalance - (3 << BITRES)
                remaining_after, cm_side = rec(
                    lm - 1, n2, sbits_r, blocks_half,
                    fill_theta >> blocks_half, remaining_after,
                    x_off + n2, lb_off + n2, g_side)
            else:
                remaining_after, cm_side = rec(
                    lm - 1, n2, sbits, blocks_half,
                    fill_theta >> blocks_half, remaining_after,
                    x_off + n2, lb_off + n2, g_side)
                rebalance = sbits - (rebalance0 - remaining_after)
                mbits_r = mbits
                if rebalance > (3 << BITRES) and itheta != 16384:
                    mbits_r += rebalance - (3 << BITRES)
                remaining_after, cm_mid = rec(
                    lm - 1, n2, mbits_r, blocks_half, fill_theta,
                    remaining_after, x_off, lb_off, g_mid)
            return remaining_after, cm_mid | (cm_side << (blocks >> 1))
        # ---- 叶 ----
        q = bits2pulses_binary(index, bits, band, lm, b)
        curr = pbits(index, bits, band, lm, q)
        rem = remaining - curr
        while rem < 0 and q > 0:
            diag["q_budget"] = diag.get("q_budget", 0) + 1
            rem += curr
            q -= 1
            curr = pbits(index, bits, band, lm, q)
            rem -= curr
        leaf_cm = 0
        if q != 0:
            k = get_pulses(q)
            y = decode_pulses(dec, n, k, diag)
            leaf_cm = extract_collapse_mask(y, n, blocks)
            diag["q_leaf_pos"] = diag.get("q_leaf_pos", 0) + 1
            yy = 0
            for v in y:
                yy += v * v
            g = gain / math.pow(float(yy), 0.5)
            for j in range(n):
                x[x_off + j] = y[j] * g
            if spread != 0 and 2 * k < n:
                diag["q_rot"] = diag.get("q_rot", 0) + 1
                sub = x[x_off:x_off + n]
                sub = rotation(sub, blocks, k, spread)
                x[x_off:x_off + n] = sub
        else:
            mask = (1 << blocks) - 1
            f = fill & mask
            if f == 0:
                diag["q_clear"] = diag.get("q_clear", 0) + 1
                for j in range(n):
                    x[x_off + j] = 0.0
            elif lowband is not None:
                diag["q_fold"] = diag.get("q_fold", 0) + 1
                leaf_cm = f
                for j in range(n):
                    state["seed"] = lcg_rand(state["seed"])
                    s = (0.00390625
                         if state["seed"] & 0x8000 else -0.00390625)
                    x[x_off + j] = lowband[lb_off + j] + s
                renormalise_vector(x, x_off, n, gain)
            else:
                diag["q_noise"] = diag.get("q_noise", 0) + 1
                leaf_cm = mask
                for j in range(n):
                    state["seed"] = lcg_rand(state["seed"])
                    x[x_off + j] = fill_sample(state["seed"])
                renormalise_vector(x, x_off, n, gain)
        return rem, leaf_cm

    remaining2, cm_raw = rec(lm, n, b, lay["b_end"], fill_t, remaining,
                             0, 0, gain)
    tf_inverse(x, n, blocks, tf_change)
    cm = cm_transform(cm_raw, lay)
    if lowband_out is not None:
        diag["q_lowband_out"] = diag.get("q_lowband_out", 0) + 1
        s = math.pow(float(n), 0.5)
        for j in range(n):
            lowband_out[j] = s * x[j]
    if cm != 0:
        diag["q_cm_nz"] = diag.get("q_cm_nz", 0) + 1
    return cm, state["seed"], remaining2
