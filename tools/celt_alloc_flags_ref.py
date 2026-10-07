# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.3 band boost（dynalloc）与 allocation trim 的独立参考端。

与 MoonBit 侧的 celt_alloc_flags.mbt 分别依据 RFC 正文和 libopus 参考源
实现，彼此不共享代码路径——gen_alloc_flags_goldens.py 把两边逐项比对。

刻意保持独立的地方：MoonBit 端的 trim icdf 由 RFC Table 58 的 PDF 累积
取补得到，本文件则直接从 celt_celt.h 抽 trim_icdf——两条来源在
gen_celt_tables.py 里已断言逐项相等，这里再各用一次等于双重落点。
"""
import os
import re

from celt_alloc_ref import NB_EBANDS, T, eband  # noqa: F401

SRC = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "..", "_research", "libopus",
)
BITRES = 3


def load_trim_icdf():
    with open(os.path.join(SRC, "celt_celt.h"), encoding="utf-8",
              errors="replace") as f:
        text = f.read()
    m = re.search(r"trim_icdf\s*\[[^\]]*\]\s*=\s*\{([^}]*)\}", text)
    if not m:
        raise SystemExit("trim_icdf not found")
    vals = [int(x) for x in re.findall(r"\d+", m.group(1))]
    if len(vals) != 11:
        raise SystemExit(f"trim_icdf {len(vals)} != 11")
    return vals


TRIM_ICDF = load_trim_icdf()


def decode_alloc_flags(dec, start, end, cap, frame_bytes, lm, diag):
    """§4.3.3 的 band boost 与 allocation trim（单声道解码）。"""
    offsets = [0] * NB_EBANDS
    total_bits = frame_bytes * 8 * (1 << BITRES)
    tell = dec.tell_frac()
    dynalloc_logp = 6

    for i in range(start, end):
        width = (T["eband5ms"][i + 1] - T["eband5ms"][i]) << lm
        quanta = min(width << BITRES, max(48, width))
        loop_logp = dynalloc_logp
        boost = 0
        again = True
        while (again and tell + (loop_logp << BITRES) < total_bits
               and boost < cap[i]):
            flag = dec.decode_bit_logp(loop_logp)
            tell = dec.tell_frac()
            if flag == 0:
                again = False
                diag["f_stop_zero"] = diag.get("f_stop_zero", 0) + 1
            else:
                boost += quanta
                total_bits -= quanta
                loop_logp = 1
                diag["f_boost"] = diag.get("f_boost", 0) + 1
                if loop_logp == 1 and boost > quanta:
                    diag["f_multi"] = diag.get("f_multi", 0) + 1
        if again:
            # 循环不是被 flag==0 打断的，说明预算或 cap 用尽
            if tell + (loop_logp << BITRES) >= total_bits:
                diag["f_budget_out"] = diag.get("f_budget_out", 0) + 1
            else:
                diag["f_cap_out"] = diag.get("f_cap_out", 0) + 1
        offsets[i] = boost
        if boost > 0:
            diag["f_any_boost"] = diag.get("f_any_boost", 0) + 1
            if dynalloc_logp > 2:
                dynalloc_logp -= 1
                diag["f_logp_down"] = diag.get("f_logp_down", 0) + 1
        if dynalloc_logp <= 2:
            diag["f_logp_floor"] = diag.get("f_logp_floor", 0) + 1

    alloc_trim = 5
    if tell + (6 << BITRES) <= total_bits:
        alloc_trim = dec.decode_icdf(TRIM_ICDF, 7)
        diag["f_trim_read"] = diag.get("f_trim_read", 0) + 1
        if alloc_trim != 5:
            diag["f_trim_nondefault"] = diag.get("f_trim_nondefault", 0) + 1
    else:
        diag["f_trim_gated"] = diag.get("f_trim_gated", 0) + 1
    return offsets, alloc_trim
