# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.3 比特分配的独立 Python 参考端（单声道解码路径）。

它与 MoonBit 侧的 celt_alloc.mbt 分别依据 RFC 正文和 libopus 参考源实现，
彼此不共享任何代码路径——gen_alloc_goldens.py 把两边的结果逐项比对。
范围解码端复用 gen_range_goldens.RangeDecoder。

刻意保持独立的地方：
  - band_allocation / logN400 / eband5ms / cache_caps50 都在本文件里用简单
    正则从 libopus 源码抽取，与 gen_celt_tables.py 的配平式提取互为交叉；
  - 整数语义（无符号除法、负数右移按 floor）在本文件里显式表达，不依赖
    Python 与 C 的默认行为差异。

本模块只放参考实现与它要用的表；用例构造与 MoonBit 调用行的生成在
gen_alloc_goldens.py。
"""
import os
import re

SRC = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "..", "_research", "libopus",
)

BITRES = 3
ALLOC_STEPS = 6
FINE_OFFSET = 21
MAX_FINE_BITS = 8
NB_EBANDS = 21
NB_ALLOC_VECTORS = 11


def _table(text, name, count):
    """从 C 源里抓一维数组的全部数字（先剥注释，避免注释里的数字混入）。"""
    m = re.search(re.escape(name) + r"\s*\[[^\]]*\]\s*=\s*\{(.*?)\}", text, re.S)
    if not m:
        raise SystemExit(f"{name} not found")
    body = re.sub(r"/\*.*?\*/", " ", m.group(1), flags=re.S)
    body = re.sub(r"//[^\n]*", " ", body)
    vals = [int(x) for x in re.findall(r"-?\d+", body)]
    if len(vals) != count:
        raise SystemExit(f"{name}: got {len(vals)}, want {count}")
    return vals


def load_tables():
    """抽取 band_allocation / logN400 / eband5ms / cache_caps50。"""
    with open(os.path.join(SRC, "celt_modes.c"), encoding="utf-8",
              errors="replace") as f:
        modes = f.read()
    with open(os.path.join(SRC, "celt_static_modes_float.h"), encoding="utf-8",
              errors="replace") as f:
        smf = f.read()
    return {
        # q 主序 × 21 带
        "alloc": _table(modes, "band_allocation", 11 * 21),
        "log_n": _table(smf, "logN400", 21),
        "eband5ms": _table(modes, "eband5ms", 22),
        "caps": _table(smf, "cache_caps50", 168),
    }


T = load_tables()


def eband(i, m):
    """频带起始 bin（eband5ms × M，M = 2**LM）。"""
    return T["eband5ms"][i] * m


def init_caps(lm, channels):
    """§4.3.3 的 cap[]：(cache+64)*C*N>>2。"""
    out = []
    base = NB_EBANDS * (2 * lm + channels - 1)
    for i in range(NB_EBANDS):
        n = (T["eband5ms"][i + 1] - T["eband5ms"][i]) << lm
        out.append(((T["caps"][base + i] + 64) * channels * n) >> 2)
    return out


def celt_udiv(n, d):
    """无符号 32 位除法（参考实现的 celt_udiv），结果回写成 32 位有符号。"""
    q = (n & 0xFFFFFFFF) // (d & 0xFFFFFFFF)
    q &= 0xFFFFFFFF
    return q - 0x100000000 if q >= 0x80000000 else q


def alloc_total(frame_bytes, dec):
    """本帧可分配位数，单位 1/8 bit。"""
    return frame_bytes * 8 * (1 << BITRES) - dec.tell_frac() - 1


def interp_bits2pulses(dec, start, end, skip_start, bits1, bits2, thresh,
                       cap, pulses, ebits, fine_priority, total, skip_rsv,
                       lm, diag):
    """二次二分插值 + skip 决策 + 余量分摊 + 逐带重平衡。"""
    m = 1 << lm
    alloc_floor = 1 << BITRES
    floor_gate = alloc_floor + (1 << BITRES)
    log_m = lm << BITRES

    lo, hi = 0, 1 << ALLOC_STEPS
    for _ in range(ALLOC_STEPS):
        mid = (lo + hi) >> 1
        psum, done = 0, False
        for j in range(end - 1, start - 1, -1):
            tmp = bits1[j] + ((mid * bits2[j]) >> ALLOC_STEPS)
            if tmp >= thresh[j] or done:
                done = True
                psum += min(tmp, cap[j])
            elif tmp >= alloc_floor:
                psum += alloc_floor
        if psum > total:
            hi = mid
        else:
            lo = mid

    psum, done = 0, False
    for j in range(end - 1, start - 1, -1):
        tmp = bits1[j] + ((lo * bits2[j]) >> ALLOC_STEPS)
        if tmp < thresh[j] and not done:
            tmp = alloc_floor if tmp >= alloc_floor else 0
        else:
            done = True
        tmp = min(tmp, cap[j])
        pulses[j] = tmp
        psum += tmp

    # 从尾部逐带决定跳过
    coded_bands = end
    keep = False
    while not keep and coded_bands > skip_start + 1:
        jb = coded_bands - 1
        span = eband(coded_bands, m) - eband(start, m)
        left = total - psum
        percoeff = celt_udiv(left, span)
        left -= span * percoeff
        used = eband(jb, m) - eband(start, m)
        rem = max(left - used, 0)
        band_width = eband(coded_bands, m) - eband(jb, m)
        band_bits = pulses[jb] + percoeff * band_width + rem
        gate = max(thresh[jb], floor_gate)
        if band_bits >= gate:
            if dec.decode_bit_logp(1) != 0:
                keep = True
                diag["a_keep"] = diag.get("a_keep", 0) + 1
            else:
                psum += 1 << BITRES
                band_bits -= 1 << BITRES
                diag["a_skip_flag"] = diag.get("a_skip_flag", 0) + 1
        else:
            diag["a_forced"] = diag.get("a_forced", 0) + 1
        if not keep:
            psum -= pulses[jb]
            if band_bits >= alloc_floor:
                psum += alloc_floor
                pulses[jb] = alloc_floor
            else:
                pulses[jb] = 0
            coded_bands -= 1
    if not keep:
        total += skip_rsv
        diag["a_natural_end"] = diag.get("a_natural_end", 0) + 1

    # 余量按带宽分摊
    left = total - psum
    span = eband(coded_bands, m) - eband(start, m)
    percoeff = celt_udiv(left, span)
    left -= span * percoeff
    for j in range(start, coded_bands):
        pulses[j] += percoeff * (eband(j + 1, m) - eband(j, m))
    for j in range(start, coded_bands):
        room = eband(j + 1, m) - eband(j, m)
        take = min(left, room)
        pulses[j] += take
        left -= take

    # 逐带重平衡并切出细能量位
    balance = 0
    j = start
    while j < coded_bands:
        n = (eband(j + 1, m) - eband(j, m)) << lm
        bit = pulses[j] + balance
        excess = 0
        if n > 1:
            excess = max(bit - cap[j], 0)
            pulses[j] = bit - excess
            den = n
            nclogn = den * (T["log_n"][j] + log_m)
            offset = (nclogn >> 1) - den * FINE_OFFSET
            if n == 2:
                offset += (den << BITRES) >> 2
            if pulses[j] + offset < (den * 2) << BITRES:
                offset += nclogn >> 2
                diag["a_fine_low"] = diag.get("a_fine_low", 0) + 1
            elif pulses[j] + offset < (den * 3) << BITRES:
                offset += nclogn >> 3
            fine = max(pulses[j] + offset + (den << (BITRES - 1)), 0)
            fine = celt_udiv(fine, den) >> BITRES
            if fine > (pulses[j] >> BITRES):
                fine = pulses[j] >> BITRES
                diag["a_fine_bust"] = diag.get("a_fine_bust", 0) + 1
            # 参考实现此处还有 fine > MAX_FINE_BITS 的封顶。单声道解码下
            # pulses<=cap 恒成立，据此算出的 fine 最大为 8，故该分支不可达。
            ebits[j] = fine
            fine_priority[j] = 1 if fine * (den << BITRES) >= pulses[j] + offset else 0
            pulses[j] -= fine << BITRES
            diag["a_n_gt1"] = diag.get("a_n_gt1", 0) + 1
        else:
            excess = max(bit - (1 << BITRES), 0)
            pulses[j] = bit - excess
            ebits[j] = 0
            fine_priority[j] = 1
            diag["a_n_eq1"] = diag.get("a_n_eq1", 0) + 1
        if excess > 0:
            extra_fine = excess >> BITRES
            extra_fine = min(extra_fine, MAX_FINE_BITS - ebits[j])
            ebits[j] += extra_fine
            extra_bits = extra_fine << BITRES
            fine_priority[j] = 1 if extra_bits >= excess - balance else 0
            excess -= extra_bits
            diag["a_excess"] = diag.get("a_excess", 0) + 1
        balance = excess
        j += 1

    while j < end:
        ebits[j] = pulses[j] >> BITRES
        pulses[j] = 0
        fine_priority[j] = 1 if ebits[j] < 1 else 0
        diag["a_tail"] = diag.get("a_tail", 0) + 1
        j += 1
    return coded_bands, balance


def compute_allocation(dec, start, end, offsets, cap, alloc_trim, total, lm,
                       diag):
    """§4.3.3 比特分配（单声道解码）。"""
    m = 1 << lm
    length = NB_EBANDS
    pulses = [0] * length
    ebits = [0] * length
    fine_priority = [0] * length
    thresh = [0] * length
    trim_offset = [0] * length
    bits1 = [0] * length
    bits2 = [0] * length

    total = max(total, 0)
    skip_start = start
    skip_rsv = (1 << BITRES) if total >= (1 << BITRES) else 0
    total -= skip_rsv
    if skip_rsv:
        diag["a_skip_rsv"] = diag.get("a_skip_rsv", 0) + 1

    for j in range(start, end):
        n0 = eband(j + 1, m) - eband(j, m)
        thresh[j] = max(1 << BITRES, ((3 * n0) << lm << BITRES) >> 4)
        trim_offset[j] = (n0 * (alloc_trim - 5 - lm) * (end - j - 1)
                          * (1 << (lm + BITRES))) >> 6
        if (n0 << lm) == 1:
            trim_offset[j] -= 1 << BITRES
        if trim_offset[j] < 0:
            diag["a_trim_neg"] = diag.get("a_trim_neg", 0) + 1

    # do-while：先算后判
    lo, hi = 1, NB_ALLOC_VECTORS - 1
    cont = True
    while cont:
        mid = (lo + hi) >> 1
        psum, done = 0, False
        for j in range(end - 1, start - 1, -1):
            n0 = eband(j + 1, m) - eband(j, m)
            bitsj = (n0 * T["alloc"][mid * length + j]) << lm >> 2
            if bitsj > 0:
                bitsj = max(bitsj + trim_offset[j], 0)
            bitsj += offsets[j]
            if bitsj >= thresh[j] or done:
                done = True
                psum += min(bitsj, cap[j])
            elif bitsj >= (1 << BITRES):
                psum += 1 << BITRES
        if psum > total:
            hi = mid - 1
        else:
            lo = mid + 1
        cont = lo <= hi
    lo_edge, hi_edge = lo - 1, lo
    if hi_edge >= NB_ALLOC_VECTORS:
        diag["a_hi_over"] = diag.get("a_hi_over", 0) + 1
    if lo_edge <= 0:
        diag["a_lo_zero"] = diag.get("a_lo_zero", 0) + 1

    for j in range(start, end):
        n0 = eband(j + 1, m) - eband(j, m)
        b1 = (n0 * T["alloc"][lo_edge * length + j]) << lm >> 2
        b2 = (cap[j] if hi_edge >= NB_ALLOC_VECTORS else
              (n0 * T["alloc"][hi_edge * length + j]) << lm >> 2)
        if b1 > 0:
            b1 = max(b1 + trim_offset[j], 0)
        if b2 > 0:
            b2 = max(b2 + trim_offset[j], 0)
        if lo_edge > 0:
            b1 += offsets[j]
        b2 += offsets[j]
        if offsets[j] > 0:
            skip_start = j
        b2 = max(b2 - b1, 0)
        bits1[j] = b1
        bits2[j] = b2
    if skip_start != start:
        diag["a_skip_start_moved"] = diag.get("a_skip_start_moved", 0) + 1

    coded_bands, balance = interp_bits2pulses(
        dec, start, end, skip_start, bits1, bits2, thresh, cap, pulses,
        ebits, fine_priority, total, skip_rsv, lm, diag)
    return {
        "pulses": pulses,
        "ebits": ebits,
        "fine_priority": fine_priority,
        "coded_bands": coded_bands,
        "balance": balance,
    }
