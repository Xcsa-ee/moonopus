# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.1 TF 调整与频谱扩展决策的独立 Python 参考端。

与 MoonBit 侧的 celt_tf_spread.mbt 分别依据 RFC 正文和 libopus 参考源实现，
彼此不共享代码路径——gen_tf_goldens.py 把两边逐项比对。

刻意保持独立的地方：表来源与 MoonBit 端正好相反。本文件的 tf_select_table
从 libopus 的 celt_celt.c 抽、spread_icdf 从 celt_celt.h 抽；MoonBit 端用的
cel_tf_select_table 由 gen_celt_tables.py 从 RFC Table 60-63 转置得到、
cel_spread_icdf 由 RFC Table 56 的 PDF 累积取补得到。四张表两两交叉。
"""
import os
import re

SRC = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "..", "_research", "libopus",
)


def _strip_comments(body):
    body = re.sub(r"/\*.*?\*/", " ", body, flags=re.S)
    return re.sub(r"//[^\n]*", " ", body)


def load_tf_select_table():
    """tf_select_table[4][8]，按 LM 主序展平。"""
    with open(os.path.join(SRC, "celt_celt.c"), encoding="utf-8",
              errors="replace") as f:
        text = f.read()
    m = re.search(
        r"tf_select_table\s*\[[^\]]*\]\s*\[[^\]]*\]\s*=\s*\{(.*?)\n\};",
        text, re.S)
    if not m:
        raise SystemExit("tf_select_table not found")
    vals = [int(x) for x in re.findall(r"-?\d+", _strip_comments(m.group(1)))]
    if len(vals) != 32:
        raise SystemExit(f"tf_select_table {len(vals)} != 32")
    return vals


def load_spread_icdf():
    with open(os.path.join(SRC, "celt_celt.h"), encoding="utf-8",
              errors="replace") as f:
        text = f.read()
    m = re.search(r"spread_icdf\s*\[[^\]]*\]\s*=\s*\{([^}]*)\}", text)
    if not m:
        raise SystemExit("spread_icdf not found")
    vals = [int(x) for x in re.findall(r"\d+", m.group(1))]
    if len(vals) != 4:
        raise SystemExit(f"spread_icdf {len(vals)} != 4")
    return vals


TF_SELECT_TABLE = load_tf_select_table()
SPREAD_ICDF = load_spread_icdf()

# celt/bands.h：门控失败时的默认值
SPREAD_NONE = 0
SPREAD_LIGHT = 1
SPREAD_NORMAL = 2
SPREAD_AGGRESSIVE = 3

NB_EBANDS = 21


def decode_tf(dec, start, end, is_transient, lm, frame_bytes, diag):
    """§4.3.1 的每带 TF 调整 + tf_select。返回长度 21 的调整值。"""
    budget = frame_bytes * 8
    is_t = 1 if is_transient else 0
    tell = dec.tell()
    logp = 2 if is_transient else 4
    tf_select_rsv = lm > 0 and tell + logp + 1 <= budget
    budget -= 1 if tf_select_rsv else 0

    tf_changed = 0
    curr = 0
    tf_res = [0] * NB_EBANDS
    for i in range(start, end):
        if tell + logp <= budget:
            curr ^= dec.decode_bit_logp(logp)
            tell = dec.tell()
            tf_changed |= curr
            diag["t_band_read"] = diag.get("t_band_read", 0) + 1
        else:
            diag["t_band_hold"] = diag.get("t_band_hold", 0) + 1
        tf_res[i] = curr
        logp = 4 if is_transient else 5

    base = lm * 8 + 4 * is_t
    tf_select = 0
    if tf_select_rsv:
        if TF_SELECT_TABLE[base + tf_changed] != TF_SELECT_TABLE[base + 2 + tf_changed]:
            tf_select = dec.decode_bit_logp(1)
            diag["t_select_read"] = diag.get("t_select_read", 0) + 1
        else:
            diag["t_select_same_col"] = diag.get("t_select_same_col", 0) + 1
    else:
        diag["t_select_rsv_off"] = diag.get("t_select_rsv_off", 0) + 1

    for i in range(start, end):
        tf_res[i] = TF_SELECT_TABLE[base + 2 * tf_select + tf_res[i]]
    if tf_changed:
        diag["t_changed"] = diag.get("t_changed", 0) + 1
    return tf_res


def decode_spread(dec, frame_bytes, diag):
    """频谱扩展决策：门控不足停在 NORMAL。"""
    if dec.tell() + 4 <= frame_bytes * 8:
        v = dec.decode_icdf(SPREAD_ICDF, 5)
        diag["s_read"] = diag.get("s_read", 0) + 1
        if v != SPREAD_NORMAL:
            diag["s_nonnormal"] = diag.get("s_nonnormal", 0) + 1
        return v
    diag["s_default"] = diag.get("s_default", 0) + 1
    return SPREAD_NORMAL
