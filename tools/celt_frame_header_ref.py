# -*- coding: utf-8 -*-
"""RFC 6716 帧首四符号（Table 56 前四项）的独立 Python 参考端。

与 MoonBit 侧的 celt_frame_header.mbt 分别依据 RFC 正文和 libopus 参考源
实现，彼此不共享代码路径——gen_frame_header_goldens.py 把两边逐项比对。

刻意保持独立的地方：本文件的 tapset icdf 由 **RFC Table 56 的 PDF
{2,1,1}/4** 现场累积取补得到，MoonBit 端用的 cel_tapset_icdf 则由
gen_celt_tables.py 从 libopus 的 celt_celt.h 抽取——两条来源。logp 常量
（15/1/3/3）同样照 RFC Table 56 的 PDF 抄，生成器里另有断言把它们锚在
规范正文上。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: F402

# RFC Table 56：silence {32767,1}/32768、post-filter {1,1}/2、
# transient {7,1}/8、intra {7,1}/8 —— 低概率项恒为 1，故 logp = log2(分母)
SILENCE_LOGP = 15
POSTFILTER_LOGP = 1
TRANSIENT_LOGP = 3
INTRA_LOGP = 3

TAPSET_PDF = [2, 1, 1]
TAPSET_DEN = 4


def _icdf(pdf, den):
    """由 PDF 累积取补得到 ec_dec_icdf 用的表。"""
    acc, out = 0, []
    for p in pdf:
        acc += p
        out.append(den - acc)
    return out


TAPSET_ICDF = _icdf(TAPSET_PDF, TAPSET_DEN)  # [2, 1, 0]


def decode_frame_header(dec, frame_bytes, start, lm, diag):
    """解帧首四个符号，返回各字段组成的字典。"""
    total_bits = frame_bytes * 8

    silence = False
    tell = dec.tell()
    if tell >= total_bits:
        silence = True
        diag["h_silence_noword"] = diag.get("h_silence_noword", 0) + 1
    elif tell == 1:
        silence = dec.decode_bit_logp(SILENCE_LOGP) != 0
        if silence:
            diag["h_silence_bit"] = diag.get("h_silence_bit", 0) + 1
        else:
            diag["h_silence_off"] = diag.get("h_silence_off", 0) + 1
    else:
        diag["h_silence_skip"] = diag.get("h_silence_skip", 0) + 1
    if silence:
        # 局部 tell 置为帧长，而不是 ec_tell()——后者是「帧长 − ilog(rng)」，
        # 拿它判门控会把静音帧本该跳过的符号放进来。
        tell = total_bits
        dec.skip_bits_to(total_bits)

    on = False
    pitch = 0
    gain = 0.0
    tapset = 0
    if start == 0 and tell + 16 <= total_bits:
        if dec.decode_bit_logp(POSTFILTER_LOGP) != 0:
            on = True
            octave = dec.decode_uint(6)
            pitch = (16 << octave) + dec.dec_bits(4 + octave) - 1
            qg = dec.dec_bits(3)
            gain = 3.0 * (qg + 1) / 32.0
            if dec.tell() + 2 <= total_bits:
                tapset = dec.decode_icdf(TAPSET_ICDF, 2)
                diag["h_tapset"] = diag.get("h_tapset", 0) + 1
            else:
                diag["h_tapset_gated"] = diag.get("h_tapset_gated", 0) + 1
            diag["h_pf_on"] = diag.get("h_pf_on", 0) + 1
        else:
            diag["h_pf_off"] = diag.get("h_pf_off", 0) + 1
        tell = dec.tell()
    else:
        diag["h_pf_gated"] = diag.get("h_pf_gated", 0) + 1

    is_transient = False
    if lm > 0 and tell + 3 <= total_bits:
        is_transient = dec.decode_bit_logp(TRANSIENT_LOGP) != 0
        tell = dec.tell()
        diag["h_transient_read"] = diag.get("h_transient_read", 0) + 1
    else:
        diag["h_transient_skip"] = diag.get("h_transient_skip", 0) + 1

    intra = False
    if tell + 3 <= total_bits:
        intra = dec.decode_bit_logp(INTRA_LOGP) != 0
        diag["h_intra_read"] = diag.get("h_intra_read", 0) + 1
    else:
        diag["h_intra_skip"] = diag.get("h_intra_skip", 0) + 1

    return {
        "silence": silence,
        "postfilter_on": on,
        "postfilter_pitch": pitch,
        "postfilter_gain": gain,
        "postfilter_tapset": tapset,
        "is_transient": is_transient,
        "intra": intra,
    }
