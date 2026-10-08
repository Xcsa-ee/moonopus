# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.4.4 Split Decoding 的独立参考端（解码路径）。

与 MoonBit 侧的 celt_theta.mbt / celt_partition.mbt 分别依据参考源
celt_bands.c 的 compute_theta / quant_partition 实现，彼此不共享代码
路径——gen_split_goldens.py 把两边逐项比对。

范围：控制与熵解码三层——
  1. compute_qn：split 增益的量化阶数（sudiv、exp2 表、进偶）；
  2. compute_theta：三种 PDF（立体声 N>2 阶梯 p0=3、B0>1 或立体声
     均匀、长块单声道三角含 isqrt32）与 imid/iside/delta 换算；
  3. quant_partition：递归分割、mid/side 位数划分与 rebalance、叶上
     bits2pulses 预算循环，叶的脉冲向量交给已验证的 PVQ 参考端。
不含谱折叠/旋转/噪声填充（alg_unquant 的谱部分与 q==0 填充路径），
它们没有熵消费，属后续帧级组装。

RFC 对 θ 的量化与 PDF 只有一句散文（§4.3.4.4），数学细节以参考实现
为准——与 caps/脉冲缓存同类；exp2 表在生成器里同时用浮点重算交叉。
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_pvq_ref import decode_pulses  # noqa: E402
from celt_alloc_ref import NB_EBANDS, T  # noqa: E402
from gen_celt_tables import extract_array, read_src  # noqa: E402
from gen_pulse_cache_goldens import (  # noqa: E402
    bits2pulses_binary,
    get_pulses,
    pbits,
)

BITRES = 3
QTHETA_OFFSET = 4
QTHETA_OFFSET_TWOPHASE = 16
MAX_PSEUDO = 40

_CACHE = None


def load_cache():
    """脉冲缓存两张表（libopus static_modes_float.h 的 dump_modes 产物）。

    表数据与实现侧同源（生成器已用 RFC Table 55 独立重建对拍过），
    换算函数 bits2pulses/pulses2bits/get_pulses 在本文件链上各自实现。
    """
    global _CACHE
    if _CACHE is None:
        smf = read_src("celt_static_modes_float.h")
        _CACHE = (
            extract_array(smf, "cache_index50"),
            extract_array(smf, "cache_bits50"),
        )
    return _CACHE


def load_logn():
    """logN[i] = log2(带宽)×8 向上取整（modes.c 的 log2_frac(bins, BITRES)）。"""
    eb = T["eband5ms"]
    return [int(math.ceil(math.log2(eb[i + 1] - eb[i]) * 8 - 1e-9))
            for i in range(NB_EBANDS)]


def exp2_table8():
    """compute_qn 的 2**(i/8)×16384 表——用浮点独立算出（floor）。"""
    return [int(16384 * (2 ** (i / 8.0))) for i in range(8)]


def s16(v):
    v &= 0xFFFF
    return v - 0x10000 if v >= 0x8000 else v


def frac_mul16(a, b):
    """celt_mathops.h 的 FRAC_MUL16：操作数按 int16 截断，结果算术右移。"""
    return (16384 + s16(a) * s16(b)) >> 15


def sudiv(n, d):
    """celt_sudiv：向零截断的有符号除法（d > 0）。"""
    q = abs(n) // d
    return q if n >= 0 else -q


def isqrt32(val):
    """mathops.c 的 isqrt32：二进制位搜索 floor(sqrt(val))。"""
    g = 0
    bshift = (val.bit_length() - 1) >> 1
    b = 1 << bshift
    while True:
        t = ((g << 1) + b) << bshift
        if t <= val:
            g += b
            val -= t
        b >>= 1
        bshift -= 1
        if bshift < 0:
            break
    return g


def bitexact_cos(x):
    """celt_bands.c 的 bitexact_cos：全平台位一致的 cos 近似。"""
    tmp = (4096 + x * x) >> 13
    x2 = tmp
    x2 = ((32767 - x2)
          + frac_mul16(x2, -7651 + frac_mul16(x2, 8277
                                               + frac_mul16(-626, x2))))
    return 1 + x2


def bitexact_log2tan(isin, icos):
    """celt_bands.c 的 bitexact_log2tan：log2(sin/cos) 的定点近似。"""
    lc = icos.bit_length()
    ls = isin.bit_length()
    icos <<= 15 - lc
    isin <<= 15 - ls
    return (((ls - lc) << 11)
            + frac_mul16(isin, frac_mul16(isin, -2597) + 7932)
            - frac_mul16(icos, frac_mul16(icos, -2597) + 7932))


LOGN = load_logn()


def compute_qn(n, b, offset, pulse_cap, stereo):
    """split 增益的量化阶数：1 或偶数，上限 256（compute_qn）。"""
    n2 = 2 * n - 1
    if stereo and n == 2:
        n2 -= 1
    qb = sudiv(b + n2 * offset, n2)
    qb = min(b - pulse_cap - (4 << BITRES), qb)
    qb = min(8 << BITRES, qb)
    if qb < (1 << BITRES >> 1):
        return 1
    qn = exp2_table8()[qb & 0x7] >> (14 - (qb >> BITRES))
    return (qn + 1) >> 1 << 1


def compute_theta(dec, band, lm, n, b, blocks, blocks0, stereo, intensity,
                  remaining, disable_inv, fill, diag):
    """解码 split 节点的增益参数（compute_theta 的解码侧）。

    返回 (sctx, b_after, fill_after)；b 减掉 qalloc，fill 按 itheta
    掩蔽。remaining 只读（qn==1 立体声 inv 判定用），扣减由调用方做。
    """
    pulse_cap = LOGN[band] + lm * (1 << BITRES)
    offset = ((pulse_cap >> 1)
              - (QTHETA_OFFSET_TWOPHASE if stereo and n == 2
                 else QTHETA_OFFSET))
    if stereo and n == 2:
        diag["t_twophase"] = diag.get("t_twophase", 0) + 1
    qn = compute_qn(n, b, offset, pulse_cap, stereo)
    if stereo and band >= intensity:
        qn = 1
        diag["t_intensity_qn1"] = diag.get("t_intensity_qn1", 0) + 1
    inv = 0
    tell = dec.tell_frac()
    if qn != 1:
        diag["t_qn_gt1"] = diag.get("t_qn_gt1", 0) + 1
        if stereo and n > 2:
            # 阶梯 pdf：0..x0 每档 p0=3，其后每档 1
            p0 = 3
            x0 = qn // 2
            ft = p0 * (x0 + 1) + x0
            fs = dec._decode(ft)
            if fs < (x0 + 1) * p0:
                x = fs // p0
                fl, fh = p0 * x, p0 * (x + 1)
            else:
                x = x0 + 1 + (fs - (x0 + 1) * p0)
                fl = (x - 1 - x0) + (x0 + 1) * p0
                fh = (x - x0) + (x0 + 1) * p0
            dec._update(fl, fh, ft)
            itheta = x
            diag["t_pdf_step"] = diag.get("t_pdf_step", 0) + 1
        elif blocks0 > 1 or stereo:
            itheta = dec.decode_uint(qn + 1)
            diag["t_pdf_uniform"] = diag.get("t_pdf_uniform", 0) + 1
        else:
            # 三角 pdf：频率 1,2,...,m+1,m,...,1（qn 恒为偶）
            m = qn >> 1
            ft = (m + 1) * (m + 1)
            fs = dec._decode(ft)
            if fs < ((m * (m + 1)) >> 1):
                itheta = (isqrt32(8 * fs + 1) - 1) >> 1
                fsym = itheta + 1
                fl = (itheta * (itheta + 1)) >> 1
                diag["t_tri_lo"] = diag.get("t_tri_lo", 0) + 1
            else:
                diag["t_tri_hi"] = diag.get("t_tri_hi", 0) + 1
                itheta = (2 * (qn + 1) - isqrt32(8 * (ft - fs - 1) + 1)) >> 1
                fsym = qn + 1 - itheta
                fl = ft - (((qn + 1 - itheta) * (qn + 2 - itheta)) >> 1)
            dec._update(fl, fl + fsym, ft)
            diag["t_pdf_tri"] = diag.get("t_pdf_tri", 0) + 1
        itheta = itheta * 16384 // qn
    else:
        diag["t_qn1"] = diag.get("t_qn1", 0) + 1
        itheta = 0
        if stereo:
            if b > (2 << BITRES) and remaining > (2 << BITRES):
                inv = dec.decode_bit_logp(2)
                diag["t_inv_read"] = diag.get("t_inv_read", 0) + 1
                if disable_inv:
                    diag["t_disable_inv"] = diag.get("t_disable_inv", 0) + 1
            else:
                diag["t_inv_skip"] = diag.get("t_inv_skip", 0) + 1
            if disable_inv:
                inv = 0
    qalloc = dec.tell_frac() - tell
    b -= qalloc
    if itheta == 0:
        imid, iside, delta = 32767, 0, -16384
        fill &= (1 << blocks) - 1
    elif itheta == 16384:
        imid, iside, delta = 0, 32767, 16384
        fill &= ((1 << blocks) - 1) << blocks
    else:
        imid = bitexact_cos(itheta)
        iside = bitexact_cos(16384 - itheta)
        delta = frac_mul16((n - 1) << 7, bitexact_log2tan(iside, imid))
    sctx = {"inv": inv, "imid": imid, "iside": iside, "delta": delta,
            "itheta": itheta, "qalloc": qalloc, "qn": qn}
    return sctx, b, fill


def decode_quant_partition(dec, band, lm, n, b, blocks, fill, remaining,
                           diag):
    """quant_partition 的解码控制流。返回 (splits, leaves, remaining)。

    splits/leaves 按前序（熵消费顺序）排列；叶只做 bits2pulses 预算
    循环与脉冲向量解码，不做谱折叠。
    """
    index, bits = load_cache()
    splits = []
    leaves = []

    def rec(lm, n, b, blocks, fill, remaining):
        blocks0 = blocks
        off = index[(lm + 1) * NB_EBANDS + band]
        kmax = bits[off]
        # 位数超过最大码本 1.5 bit 且 N>2 才分割（LM=-1 到顶）
        if lm != -1 and b > bits[off + kmax] + 12 and n > 2:
            diag["p_split"] = diag.get("p_split", 0) + 1
            n2 = n >> 1
            if blocks == 1:
                fill = (fill & 1) | (fill << 1)
            blocks = (blocks + 1) >> 1
            sctx, b, fill = compute_theta(
                dec, band, lm - 1, n2, b, blocks, blocks0, False, 0,
                remaining, False, fill, diag)
            remaining -= sctx["qalloc"]
            delta = sctx["delta"]
            itheta = sctx["itheta"]
            if blocks0 > 1 and (itheta & 0x3FFF):
                if itheta > 8192:
                    delta -= delta >> (4 - (lm - 1))
                    diag["p_delta_pos"] = diag.get("p_delta_pos", 0) + 1
                else:
                    delta = min(
                        0, delta + ((n2 << BITRES) >> (5 - (lm - 1))))
                    diag["p_delta_neg"] = diag.get("p_delta_neg", 0) + 1
            mbits = max(0, min(b, sudiv(b - delta, 2)))
            sbits = b - mbits
            lm2 = lm - 1
            splits.append(sctx)
            rebalance = remaining
            if mbits >= sbits:
                diag["p_mid_first"] = diag.get("p_mid_first", 0) + 1
                remaining = rec(lm2, n2, mbits, blocks, fill, remaining)
                rebalance = mbits - (rebalance - remaining)
                if rebalance > (3 << BITRES) and itheta != 0:
                    sbits += rebalance - (3 << BITRES)
                    diag["p_rebal_m"] = diag.get("p_rebal_m", 0) + 1
                elif (2 << BITRES) < rebalance <= (3 << BITRES)                         and itheta != 0:
                    # 门槛内侧 (16,24] 窗口：rebalance 门槛变异的定点样本
                    diag["p_rebal_edge"] = diag.get("p_rebal_edge", 0) + 1
                remaining = rec(lm2, n2, sbits, blocks, fill >> blocks,
                                remaining)
            else:
                diag["p_side_first"] = diag.get("p_side_first", 0) + 1
                remaining = rec(lm2, n2, sbits, blocks, fill >> blocks,
                                remaining)
                rebalance = sbits - (rebalance - remaining)
                if rebalance > (3 << BITRES) and itheta != 16384:
                    mbits += rebalance - (3 << BITRES)
                    diag["p_rebal_s"] = diag.get("p_rebal_s", 0) + 1
                remaining = rec(lm2, n2, mbits, blocks, fill, remaining)
            return remaining
        # 叶：bits2pulses + 预算循环
        diag["p_leaf"] = diag.get("p_leaf", 0) + 1
        q = bits2pulses_binary(index, bits, band, lm, b)
        curr = pbits(index, bits, band, lm, q)
        remaining -= curr
        while remaining < 0 and q > 0:
            diag["p_budget_loop"] = diag.get("p_budget_loop", 0) + 1
            remaining += curr
            q -= 1
            curr = pbits(index, bits, band, lm, q)
            remaining -= curr
        if q != 0:
            y = decode_pulses(dec, n, get_pulses(q), diag)
            diag["p_qpos"] = diag.get("p_qpos", 0) + 1
        else:
            y = []
            diag["p_q0"] = diag.get("p_q0", 0) + 1
        if lm == -1:
            diag["p_lm_m1"] = diag.get("p_lm_m1", 0) + 1
        if n == 1:
            diag["p_n1"] = diag.get("p_n1", 0) + 1
        leaves.append({"n": n, "blocks": blocks, "lm": lm, "b": b,
                       "q": q, "used": curr, "fill": fill, "pulses": y})
        return remaining

    remaining = rec(lm, n, b, blocks, fill, remaining)
    return splits, leaves, remaining
