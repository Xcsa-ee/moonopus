# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.2 能量解码的独立 Python 参考端。

它与 MoonBit 侧的 celt_energy.mbt 分别依据 RFC 正文和 libopus 参考源实现，
彼此不共享任何代码路径——gen_energy_goldens.py 把两边的结果逐项比对，任
一侧理解有偏差都会立刻暴露。范围解码端复用 gen_range_goldens.RangeDecoder。

本模块只放参考实现和它要用的表；用例构造与 MoonBit 调用行的生成在
gen_energy_goldens.py。

刻意保持独立的地方：
  - e_prob_model 用一条简单正则从 celt_quant_bands.c 抽取，与
    gen_celt_tables.py 的配平式提取互为交叉；
  - 预测系数按 C 源里的分数字面量（k/32768.）录入，与生成器输出的十进制
    值互为交叉。
"""
import os
import re

SRC = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "..", "_research", "libopus",
)

# 预测系数：按 quant_bands.c 浮点分支的分数字面量录入（Q15）
PRED_COEF = [29440 / 32768., 26112 / 32768., 21248 / 32768., 16384 / 32768.]
BETA_COEF = [30147 / 32768., 22282 / 32768., 12124 / 32768., 6554 / 32768.]
BETA_INTRA = 4915 / 32768.
SMALL_ICDF = [2, 1, 0]
MAX_FINE_BITS = 8
LAPLACE_MINP = 1
LAPLACE_LOG_MINP = 0
LAPLACE_NMIN = 16
NB_EBANDS = 21


def load_e_prob():
    """从 celt_quant_bands.c 抽 e_prob_model 的 336 个字节。

    与 gen_celt_tables.py 的提取路径不同（这里只做注释剥离 + 数字抓取），
    两条路径必须给出相同的数据，否则 MoonBit 侧金标比对会失败。
    """
    path = os.path.join(SRC, "celt_quant_bands.c")
    with open(path, encoding="utf-8", errors="replace") as f:
        text = f.read()
    m = re.search(r"e_prob_model\[4\]\[2\]\[42\]\s*=\s*\{(.*?)\n\};", text, re.S)
    if not m:
        raise SystemExit("e_prob_model not found")
    body = re.sub(r"/\*.*?\*/", " ", m.group(1), flags=re.S)
    vals = [int(x) for x in re.findall(r"\d+", body)]
    if len(vals) != 336:
        raise SystemExit(f"e_prob_model {len(vals)} != 336")
    # 参考实现注释：decay 上限 11456（= 179<<6），超过说明抽错了组
    assert max(vals[1::2]) << 6 <= 11456, max(vals[1::2]) << 6
    return vals


E_PROB = load_e_prob()


# ---------------------------------------------------------------- 参考端

def laplace_get_freq1(fs0, decay):
    """§4.3.2.1 pdf 中幅度 1 的频率（libopus laplace.c 同名函数）。"""
    ft = 32768 - LAPLACE_MINP * (2 * LAPLACE_NMIN) - fs0
    return (ft * (16384 - decay)) >> 15


def laplace_decode(dec, fs, decay, diag):
    """解一个 Laplace 符号，并在 diag 里记下走过的分支。"""
    fm = dec.decode_bin_fs(15)
    fl = 0
    val = 0
    if fm < fs:
        key = "lap_zero"
    else:
        val += 1
        fl = fs
        fs = laplace_get_freq1(fs, decay) + LAPLACE_MINP
        tail = False
        while fs > LAPLACE_MINP and fm >= fl + 2 * fs:
            fs *= 2
            fl += fs
            fs = ((fs - 2 * LAPLACE_MINP) * decay) >> 15
            fs += LAPLACE_MINP
            val += 1
        if fs <= LAPLACE_MINP:
            tail = True
            di = (fm - fl) >> (LAPLACE_LOG_MINP + 1)
            val += di
            fl += 2 * di * LAPLACE_MINP
        if fm < fl + fs:
            val = -val
        else:
            fl += fs
        key = "lap_tail" if tail else "lap_chain"
    diag[key] = diag.get(key, 0) + 1
    dec._update(fl, min(fl + fs, 32768), 32768)
    return val


def coarse_energy(dec, old_e, start, end, intra, lm, diag):
    """§4.3.2.1 粗能量解码。预算取解码器自身的载荷长度（同参考实现）。"""
    model = (lm * 2 + (1 if intra else 0)) * 42
    if intra:
        coef, beta = 0.0, BETA_INTRA
    else:
        coef, beta = PRED_COEF[lm], BETA_COEF[lm]
    budget = dec.len * 8
    prev = 0.0
    for i in range(start, end):
        tell = dec.tell()
        if budget - tell >= 15:
            pi = 2 * min(i, 20)
            qi = laplace_decode(
                dec, E_PROB[model + pi] << 7, E_PROB[model + pi + 1] << 6, diag)
            branch = "laplace"
        elif budget - tell >= 2:
            v = dec.decode_icdf(SMALL_ICDF, 2)
            qi = (v >> 1) ^ -(v & 1)
            branch = "icdf"
        elif budget - tell >= 1:
            qi = -dec.decode_bit_logp(1)
            branch = "bit"
        else:
            qi = -1
            branch = "none"
        diag["c_" + branch] = diag.get("c_" + branch, 0) + 1

        q = float(qi)
        pred_src = old_e[i] if old_e[i] >= -9.0 else -9.0
        tmp = coef * pred_src + prev + q
        old_e[i] = tmp
        prev = prev + q - beta * q


def fine_energy(dec, old_e, start, end, extra_quant, diag):
    """§4.3.2.2 细能量解码。"""
    for i in range(start, end):
        extra = extra_quant[i]
        if extra <= 0:
            diag["f_zero"] = diag.get("f_zero", 0) + 1
            continue
        if dec.tell() + extra > dec.len * 8:
            diag["f_budget"] = diag.get("f_budget", 0) + 1
            continue
        f = dec.dec_bits(extra)
        offset = (f + 0.5) / float(1 << extra) - 0.5
        old_e[i] = old_e[i] + offset
        diag["f_applied"] = diag.get("f_applied", 0) + 1


def energy_finalise(dec, old_e, start, end, fine_quant, fine_priority,
                    bits_left, diag):
    """§4.3.2.2 收尾。"""
    left = bits_left
    for prio in range(2):
        i = start
        while i < end and left >= 1:
            if fine_quant[i] >= MAX_FINE_BITS or fine_priority[i] != prio:
                key = ("z_max" if fine_quant[i] >= MAX_FINE_BITS else "z_prio")
                diag[key] = diag.get(key, 0) + 1
                i += 1
                continue
            q2 = dec.dec_bits(1)
            offset = (q2 - 0.5) / float(1 << (fine_quant[i] + 1))
            old_e[i] = old_e[i] + offset
            left -= 1
            i += 1
    if left > 0:
        diag["z_left"] = diag.get("z_left", 0) + 1


def init_e(n=NB_EBANDS):
    """统一初始能量：含低于 -9 的值，用于验证粗能量解码前的下限钳位。"""
    return [-12.0 if i % 3 == 0 else (0.75 if i % 3 == 1 else -3.5)
            for i in range(n)]
