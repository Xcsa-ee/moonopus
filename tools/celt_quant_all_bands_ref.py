# -*- coding: utf-8 -*-
"""quant_all_bands 主循环（RFC 6716 §4.3.4 Shape Decoding）的独立参考端。

与 MoonBit 侧的 celt_quant_all_bands.mbt 分别依据 celt_bands.c 的
quant_all_bands 解码侧实现，彼此不共享代码路径——
gen_quant_all_bands_goldens.py 把两边逐项比对。

单声道解码主循环的账目与折叠链（逐行对应参考实现）：
  - 每带 b = clamp(remaining+1, pulses[i]+curr_balance)，curr_balance =
    sudiv(balance, min(3, codedBands-i))，balance 每带先减 tell 再加
    pulses[i]+tell（净增 pulses[i]，但 curr 用的是减 tell 后的中间值）；
  - 折叠源 norm 缓冲按 2*nbEBands-1 带容量维护，各带经 lowband_out
    写入 ×√N0 的预缩放谱；lowband_offset 在满足深度条件时推进；
  - 保守 cm 估计：折叠源覆盖的各带 collapse mask 按位或作为 fill
    （源不可用/激进扩展短块时取 (1<<B)-1）；有效源 ≥0 时把源带切片
    交给 quant_band（其内部先做前向 TF 变换），返回后把变换写回 norm
    ——与参考实现对 norm 的就地修改副作用一致；
  - 每带结束后 balance += pulses[i]，update_lowband = b > N<<BITRES。
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from celt_alloc_ref import T  # noqa: E402
from celt_quant_band_ref import quant_band  # noqa: E402

NB_EBANDS = 21
BITRES = 3
SPREAD_AGGRESSIVE = 3


def eband(i, m):
    return T["eband5ms"][i] * m


def band_bins(i, m):
    return (T["eband5ms"][i + 1] - T["eband5ms"][i]) * m


def sudiv(n, d):
    """向零截断（celt_sudiv）。"""
    q = abs(n) // d
    return q if n >= 0 else -q


def special_hybrid_folding(norm, start, m):
    """CELT-only 起始对等宽时长度为 0 的首二带折叠补拷（draft 更新）。"""
    n1 = band_bins(start, m)
    n2 = band_bins(start + 1, m)
    ln = n2 - n1
    if ln > 0:
        norm[n1:n1 + ln] = norm[2 * n1 - n2:2 * n1 - n2 + ln]


def quant_all_bands(dec, x, start, end, lm, short_blocks, pulses, tf_res,
                    coded_bands, total_bits, balance, spread, seed, masks,
                    diag):
    """单声道主循环。x 原地读写（长度 m*120），masks[0:end] 写入。

    返回推进后的 seed。
    """
    m = 1 << lm
    blocks = m if short_blocks else 1
    norm_offset = eband(start, m)
    norm = [0.0] * (eband(NB_EBANDS - 1, m) - norm_offset)
    lowband_offset = 0
    update_lowband = True
    bal = balance
    seed_ = seed
    for i in range(start, end):
        last = i == end - 1
        n = band_bins(i, m)
        tell = dec.tell_frac()
        if i != start:
            bal -= tell
        remaining_bits = total_bits - tell - 1
        if i <= coded_bands - 1:
            curr = sudiv(bal, min(3, coded_bands - i))
            b = max(0, min(16383, min(remaining_bits + 1,
                                      pulses[i] + curr)))
            if b == 0:
                diag["a_clamp"] = diag.get("a_clamp", 0) + 1
        else:
            b = 0
            diag["a_b_zero"] = diag.get("a_b_zero", 0) + 1
        # 草案更新的折叠位置推进（解码恒 resynth）
        cond1 = eband(i, m) - n >= eband(start, m) or i == start + 1
        if cond1 and (update_lowband or lowband_offset == 0):
            lowband_offset = i
        else:
            if i != start:
                diag["a_no_update"] = diag.get("a_no_update", 0) + 1
        if i == start + 1:
            special_hybrid_folding(norm, start, m)
        tf_change = tf_res[i]
        # 保守 cm 估计（折叠源覆盖带的 mask 按位或）
        effective = -1
        if lowband_offset != 0 and (
                spread != SPREAD_AGGRESSIVE or blocks > 1 or tf_change < 0):
            effective = max(0, eband(lowband_offset, m) - norm_offset - n)
            t_lo = effective + norm_offset
            fold_start = lowband_offset - 1
            while eband(fold_start, m) > t_lo:
                fold_start -= 1
            fold_end = lowband_offset - 1
            while fold_end + 1 < i and eband(fold_end + 1, m) < t_lo + n:
                fold_end += 1
            x_cm = 0
            # C 的 do-while(++fold_i<fold_end)：覆盖 [fold_start, fold_end)
            for f in range(fold_start, fold_end):
                x_cm |= masks[f]
            diag["a_fold"] = diag.get("a_fold", 0) + 1
        else:
            x_cm = (1 << blocks) - 1
            diag["a_nofold"] = diag.get("a_nofold", 0) + 1
        # 带内数组：频谱、折叠源切片、折叠预缩放输出
        x_off = eband(i, m)
        x_band = x[x_off:x_off + n]
        lb = None
        if effective >= 0:
            lb = norm[effective:effective + n]
        lo_out = [0.0] * n if not last else None
        cm, seed_, _rem = quant_band(
            dec, x_band, lb, i, lm, n, b, blocks, tf_change, x_cm, 1.0,
            spread, seed_, remaining_bits, lo_out, diag)
        x[x_off:x_off + n] = x_band
        if lb is not None:
            # 镜像参考实现对 norm 的就地前向变换副作用
            norm[effective:effective + n] = lb
        if lo_out is not None:
            norm[eband(i, m) - norm_offset:eband(i, m) - norm_offset + n] = \
                lo_out
        masks[i] = cm
        bal += pulses[i] + tell
        update_lowband = b > (n << BITRES)
        if cm == 0:
            diag["a_cm0"] = diag.get("a_cm0", 0) + 1
        elif cm != (1 << blocks) - 1:
            diag["a_cm_partial"] = diag.get("a_cm_partial", 0) + 1
    return seed_
