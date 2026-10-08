# -*- coding: utf-8 -*-
"""脉冲缓存金标（§4.3.4.4）：独立重建 bits2pulses/pulses2bits 的查表数据。

三条独立路径交叉：
  1. 实现侧（celt_tables.mbt 的 cel_cache_index50/cel_cache_bits50）=
     从 libopus static_modes_float.h 解析的 dump_modes 静态产物；
  2. 本脚本按 celt/rate.c 的 compute_pulse_cache 算法从头重建：
     RFC 6716 Table 55 的带宽 → fits_in32 截断 → V(N,K) 闭式
     （C 端是 U 表递推）→ 结构与数值逐项对拍；log2_frac 因 RFC 未规定、
     语义以 libopus 为准，与 C 同算法（逐行移植，保守性另有精确值断言）；
  3. bits2pulses 的语义 = C 的定次二分 + tie-break（解码须与 libopus 逐位
     一致），本脚本另写一份移植作金标；暴力 argmin 只作下界校验——二分
     结果必须落在 argmin 集合内（距离 = 全局最小），但平台段（如 N=1）
     上平局端点由 tie-break 决定，二者不逐值相等。

产出 pulse_cache_goldens_wbtest.mbt：重建全表、bits2pulses 采样金标
（含表特征点与 tie-break 平局点）、get_pulses 全表。

用法：python tools/gen_pulse_cache_goldens.py
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gen_celt_tables import (  # noqa: E402
    extract_array,
    parse_rfc_tables,
    read_rfc,
    read_src,
)
from _fmt import moon_fmt  # noqa: E402

MAX_PSEUDO = 40
LOG_MAX_PSEUDO = 6
BITRES = 3
NB_BANDS = 21
MAX_LM = 3

# fits_in32 的截断表（celt/rate.c）：V(N,K) 是否装得下 32 位无符号。
MAX_N = [
    32767, 32767, 32767, 1476, 283, 109, 60, 40,
    29, 24, 20, 18, 16, 14, 13,
]
MAX_K = [
    32767, 32767, 32767, 32767, 1172, 238, 95, 53,
    36, 27, 22, 18, 16, 15, 13,
]


def fits_in32(n, k):
    if n >= 14:
        if k >= 14:
            return False
        return n <= MAX_N[k]
    return k <= MAX_K[n]


def get_pulses(i):
    """伪脉冲索引 → 实际脉冲数（rate.h）。"""
    return i if i < 8 else (8 + (i & 7)) << ((i >> 3) - 1)


def v_count(n, k):
    """V(N,K) = #{x ∈ Z^N : ‖x‖₁ = K} 的闭式。

    选 j 个非零位 C(N,j)、把 K 拆成 j 个正部 C(K-1,j-1)、符号 2^j。
    与 C 端的 U 表递推是完全不同的路径，已抽验 V(1,1)=2、V(2,2)=8、
    V(3,3)=38、V(4,4)=192 与 CELT_PVQ_U_DATA 组合值一致。
    """
    if k <= 0:
        return 0
    total = 0
    for j in range(1, min(n, k) + 1):
        total += math.comb(n, j) * math.comb(k - 1, j - 1) * (1 << j)
    return total


def log2_frac(val, frac=BITRES):
    """log2(val)×2^frac 的保守上估——libopus celt_cwrs.c 同名函数逐行移植。

    RFC 6716 未规定此函数（它是 dump_modes 静态表的生成细节），位数表语义
    以 libopus 实现为准，故这里必须与 C 同算法；独立性保留在 V(N,K) 用闭式
    而非 U 表递推。返回值 ≥ 精确 ceil、至多多 1 个 1/2^frac 单元——下方断言
    把这层保守性钉在精确值上，移植写错（多/少进位）都会在重建对拍暴露。
    C 端为 opus_uint32 运算，平方处会回绕，这里逐运算取模保持同余。
    """
    exact = math.ceil(math.log2(val) * (1 << frac) - 1e-9)
    l = val.bit_length()
    if val & (val - 1):
        if l > 16:
            val = ((val - 1) >> (l - 16)) + 1
        else:
            val <<= 16 - l
        l = (l - 1) << frac
        while True:
            b = val >> 16
            l += b << frac
            val = (val + b) >> b
            val = ((val * val & 0xFFFFFFFF) + 0x7FFF & 0xFFFFFFFF) >> 15
            frac -= 1
            if frac < 0:
                break
        res = l + (1 if val > 0x8000 else 0)
    else:
        res = (l - 1) << frac
    assert exact <= res <= exact + 1, (
        f"log2_frac 保守性越界: val={val} exact={exact} res={res}")
    return res


def rebuild(band_bins):
    """按 compute_pulse_cache 的语义从带宽重建 index/bits 两张表。

    band_bins[j] 是带 j 的 MDCT bin 数（2.5ms 列，来源 RFC Table 55）。
    """
    index = [-1] * (NB_BANDS * (MAX_LM + 2))
    entries = []
    slot = 0
    for i in range(MAX_LM + 2):
        for j in range(NB_BANDS):
            n = (band_bins[j] << i) >> 1
            # 跨 (i,j) 找同尺寸的先前条目；k==i 时只允许 n<j，避免自指
            shared = -1
            for k in range(i + 1):
                lim = j if k == i else NB_BANDS
                for nj in range(lim):
                    if n != (band_bins[nj] << k) >> 1:
                        continue
                    if index[k * NB_BANDS + nj] != -1:
                        shared = index[k * NB_BANDS + nj]
                    break
                if shared != -1:
                    break
            if shared != -1:
                index[i * NB_BANDS + j] = shared
            elif n != 0:
                kmax = 0
                while fits_in32(n, get_pulses(kmax + 1)) and kmax < MAX_PSEUDO:
                    kmax += 1
                index[i * NB_BANDS + j] = slot
                entries.append((n, kmax))
                slot += kmax + 1
    bits = [0] * slot
    # entries 顺序即 slot 分配顺序，按序回填
    slot = 0
    for n, kmax in entries:
        bits[slot] = kmax
        for j in range(1, kmax + 1):
            bits[slot + j] = log2_frac(v_count(n, get_pulses(j))) - 1
        slot += kmax + 1
    return index, bits


def bits2pulses_binary(index, bits, band, lm, b):
    """C 语义的定次二分（rate.h bits2pulses，将逐行移植进 MoonBit）。"""
    off = index[(lm + 1) * NB_BANDS + band]
    lo, hi = 0, bits[off]
    b -= 1
    for _ in range(LOG_MAX_PSEUDO):
        mid = (lo + hi + 1) >> 1
        if bits[off + mid] >= b:
            hi = mid
        else:
            lo = mid
    clo = -1 if lo == 0 else bits[off + lo]
    return lo if b - clo <= bits[off + hi] - b else hi


def bits2pulses_argmin(index, bits, band, lm, b):
    """暴力最近元：位数曲线上的 |位数(q)-b| 最小者，平局取小 q。

    不是解码语义（平局端由 C 二分的 tie-break 决定），只作独立下界：
    二分结果的距离必须等于这里的最小距离。
    """
    off = index[(lm + 1) * NB_BANDS + band]
    kmax = bits[off]
    best_q, best_d = 0, None
    for q in range(kmax + 1):
        pq = 0 if q == 0 else bits[off + q] + 1
        d = abs(pq - b)
        if best_d is None or d < best_d:
            best_q, best_d = q, d
    return best_q


def pbits(index, bits, band, lm, q):
    """pulses2bits：位数（1/8 bit），q=0 恒为 0。"""
    off = index[(lm + 1) * NB_BANDS + band]
    return 0 if q == 0 else bits[off + q] + 1


def tie_break_variant(index, bits, band, lm, b):
    """tie-break 从 `<=` 放宽到 `<` 后的返回值（用于搜平局点）。"""
    off = index[(lm + 1) * NB_BANDS + band]
    lo, hi = 0, bits[off]
    b -= 1
    for _ in range(LOG_MAX_PSEUDO):
        mid = (lo + hi + 1) >> 1
        if bits[off + mid] >= b:
            hi = mid
        else:
            lo = mid
    clo = -1 if lo == 0 else bits[off + lo]
    return lo if b - clo < bits[off + hi] - b else hi


def clo_zero_variant(index, bits, band, lm, b):
    """lo==0 特判从 -1 改成 0 后的返回值（用于搜差异点）。

    只在收敛后 lo==0 且 cache[hi]==2*(b-1) 时翻转（两侧距离各差 1 的
    临界点），这类 b 很稀疏，必须专门搜进金标否则变异会漏网。
    """
    off = index[(lm + 1) * NB_BANDS + band]
    lo, hi = 0, bits[off]
    b -= 1
    for _ in range(LOG_MAX_PSEUDO):
        mid = (lo + hi + 1) >> 1
        if bits[off + mid] >= b:
            hi = mid
        else:
            lo = mid
    clo = 0 if lo == 0 else bits[off + lo]
    return lo if b - clo <= bits[off + hi] - b else hi


def main():
    smf = read_src("celt_static_modes_float.h")
    src_index = extract_array(smf, "cache_index50")
    src_bits = extract_array(smf, "cache_bits50")
    rfc = parse_rfc_tables(read_rfc())
    # 带宽来源 RFC Table 55 的 2.5ms 列——与实现侧的 libopus eband5ms
    # 分属两条来源，任一侧读错都会在重建对拍里暴露。
    band_bins = [rfc["band_bins"][j][0] for j in range(NB_BANDS)]
    assert band_bins == [
        1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 6, 6, 8, 12, 18, 22,
    ], f"Table 55 2.5ms 列异常: {band_bins}"

    index, bits = rebuild(band_bins)

    # 主对拍：重建 == dump_modes 静态产物，逐项相等
    if index != src_index:
        diff = [
            (p, a, b) for p, (a, b) in enumerate(zip(index, src_index)) if a != b
        ]
        raise SystemExit(f"index 重建不符，共 {len(diff)} 处，前 5: {diff[:5]}")
    if bits != src_bits:
        diff = [
            (p, a, b) for p, (a, b) in enumerate(zip(bits, src_bits)) if a != b
        ]
        raise SystemExit(f"bits 重建不符，共 {len(diff)} 处，前 5: {diff[:5]}")
    assert max(bits) <= 255, f"bits 超出 uchar 值域: {max(bits)}"

    # pulses2bits 的单调性将在 wbtest 断言，先保证静态表本身满足
    # （log2_frac 是保守近似，单调性是性质不是定理，此处先钉死）。
    pos = 0
    while pos < len(bits):
        kmax = bits[pos]
        for j in range(1, kmax):
            assert bits[pos + j] <= bits[pos + j + 1], (
                f"位数表非单调: slot {pos + j}: "
                f"{bits[pos + j]} > {bits[pos + j + 1]}")
        pos += kmax + 1

    # 二分 vs 暴力下界：对全 (lm, band, b) 扫描，二分结果的 |位数-b|
    # 必须等于 argmin 的最小距离（平台段端点可不同，见 bits2pulses_argmin）
    b_max = max(bits) + 8
    for lm in range(MAX_LM + 1):
        for band in range(NB_BANDS):
            off = index[(lm + 1) * NB_BANDS + band]
            assert off >= 0, f"(lm={lm}, band={band}) 索引无效"
            for b in range(b_max + 1):
                q1 = bits2pulses_binary(index, bits, band, lm, b)
                q2 = bits2pulses_argmin(index, bits, band, lm, b)
                d1 = abs(pbits(index, bits, band, lm, q1) - b)
                dmin = abs(pbits(index, bits, band, lm, q2) - b)
                if d1 != dmin:
                    raise SystemExit(
                        f"二分偏离 argmin 下界 lm={lm} band={band} b={b}: "
                        f"{d1} != {dmin}")

    # 变体翻转点：`<=`→`<` 的平局点，以及 lo==0 特判 -1→0 的临界点
    # （后者只在 cache[hi]==2*(b-1) 时翻转，很稀疏）。每 (lm,band)
    # tie 点收前 3 个、clo 点收前 1 个，都进金标否则对应变异漏网。
    ties = []
    clo_ties = []
    for lm in range(MAX_LM + 1):
        for band in range(NB_BANDS):
            n_tie = 0
            for b in range(b_max + 1):
                q1 = bits2pulses_binary(index, bits, band, lm, b)
                if n_tie < 3 and tie_break_variant(index, bits, band, lm, b) != q1:
                    ties.append((lm, band, b))
                    n_tie += 1
                if clo_zero_variant(index, bits, band, lm, b) != q1:
                    clo_ties.append((lm, band, b))
    assert ties, "未找到 tie-break 平局点——金标点集覆盖不到 tie 分支"
    assert clo_ties, "未找到 lo==0 特判差异点——金标点集覆盖不到该分支"
    ties.extend(clo_ties)

    # 采样金标：每 (lm, band) 固定 21 个 b 点（15 个公共 + 6 个表特征点），
    # 严格等长才能用统一步长展平；tie 点另走平行数组。
    fixed = [0, 1, 2, 3, 4, 5, 6, 7, 8, 16, 32, 64, 128, 200, 255]
    bp_b, bp_q = [], []
    for lm in range(MAX_LM + 1):
        for band in range(NB_BANDS):
            off = index[(lm + 1) * NB_BANDS + band]
            kmax = bits[off]
            pts = fixed + [
                pbits(index, bits, band, lm, 1) - 1,
                pbits(index, bits, band, lm, 1),
                pbits(index, bits, band, lm, 1) + 1,
                pbits(index, bits, band, lm, kmax),
                pbits(index, bits, band, lm, kmax) + 1,
                16383,
            ]
            assert len(pts) == 21, f"采样点数不是 21: {len(pts)}"
            for b in pts:
                bp_b.append(b)
                bp_q.append(bits2pulses_binary(index, bits, band, lm, b))

    # pulses2bits 金标：每 (lm,band) 取 q ∈ {0, 1, 2, kmax}（kmax 随带而异，
    # 显式索引成平行数组，不依赖统一步长）。
    p2_lm, p2_band, p2_q, p2_p = [], [], [], []
    for lm in range(MAX_LM + 1):
        for band in range(NB_BANDS):
            kmax = bits[index[(lm + 1) * NB_BANDS + band]]
            for q in (0, 1, 2, kmax):
                p2_lm.append(lm)
                p2_band.append(band)
                p2_q.append(q)
                p2_p.append(pbits(index, bits, band, lm, q))

    gp = [get_pulses(i) for i in range(MAX_PSEUDO + 1)]

    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "pulse_cache_goldens_wbtest.mbt",
    )
    lines = [
        "// 由 tools/gen_pulse_cache_goldens.py 生成，请勿手改。",
        "//",
        "// 脉冲缓存金标（§4.3.4.4）：本文件的表与向量由 Python 端按",
        "// rate.c 算法独立重建（RFC Table 55 带宽 + fits_in32 + V(N,K) 闭式），",
        "// 与实现侧从 libopus static_modes_float.h 解析的 dump_modes 静态",
        "// 产物逐项对拍通过后才产出——表结构与计数公式两条路径不同，任一侧",
        "// 读错或理解偏差都会在 wbtest 里红。",
        "",
        "///|",
        "/// 重建的条目索引 [5×21]（与 cel_cache_index50 逐项比对）。",
        "let pc_index : Array[Int] = [",
        "  " + ", ".join(str(v) for v in index),
        "]",
        "",
        "///|",
        "/// 重建的位数表 [392]（与 cel_cache_bits50 逐项比对）。",
        "let pc_bits : Array[Int] = [",
        "  " + ", ".join(str(v) for v in bits),
        "]",
        "",
        "///|",
        "/// bits2pulses 采样金标：按 lm×band 主序展平，每带固定 21 个 b 点。",
        "let pc_b2p_b : Array[Int] = [",
        "  " + ", ".join(str(v) for v in bp_b),
        "]",
        "",
        "///|",
        "/// 对应的伪脉冲索引（C 二分语义，与 pc_b2p_b 对齐）。",
        "let pc_b2p_q : Array[Int] = [",
        "  " + ", ".join(str(v) for v in bp_q),
        "]",
        "",
        "///|",
        "/// tie-break 平局点：这些 b 上 `<=`/`<` 的选择会翻转结果。",
        "/// 四个平行数组等长，锁步遍历。",
        "let pc_tie_lm : Array[Int] = [",
        "  " + ", ".join(str(t[0]) for t in ties),
        "]",
        "",
        "///|",
        "/// 平局点的带号（与 pc_tie_lm 对齐）。",
        "let pc_tie_band : Array[Int] = [",
        "  " + ", ".join(str(t[1]) for t in ties),
        "]",
        "",
        "///|",
        "/// 平局点的输入位数（1/8 bit，与 pc_tie_lm 对齐）。",
        "let pc_tie_b : Array[Int] = [",
        "  " + ", ".join(str(t[2]) for t in ties),
        "]",
        "",
        "///|",
        "/// 平局点的期望伪脉冲索引（C tie-break 结果，与 pc_tie_lm 对齐）。",
        "let pc_tie_q : Array[Int] = [",
        "  " + ", ".join(
            str(bits2pulses_binary(index, bits, t[1], t[0], t[2]))
            for t in ties),
        "]",
        "",
        "///|",
        "/// pulses2bits 特征点：每 (lm,band) 取 q ∈ {0, 1, 2, Kmax}，四个",
        "/// 平行数组锁步遍历（Kmax 随带而异，不能用统一步长）。",
        "let pc_p2b_lm : Array[Int] = [",
        "  " + ", ".join(str(v) for v in p2_lm),
        "]",
        "",
        "///|",
        "/// 特征点的带号（与 pc_p2b_lm 对齐）。",
        "let pc_p2b_band : Array[Int] = [",
        "  " + ", ".join(str(v) for v in p2_band),
        "]",
        "",
        "///|",
        "/// 特征点的伪脉冲索引（与 pc_p2b_lm 对齐）。",
        "let pc_p2b_q : Array[Int] = [",
        "  " + ", ".join(str(v) for v in p2_q),
        "]",
        "",
        "///|",
        "/// 特征点的期望位数（1/8 bit，与 pc_p2b_lm 对齐）。",
        "let pc_p2b_p : Array[Int] = [",
        "  " + ", ".join(str(v) for v in p2_p),
        "]",
        "",
        "///|",
        "/// get_pulses 的全表（索引 0..40 → 实际脉冲数）。",
        "let pc_get_pulses : Array[Int] = [",
        "  " + ", ".join(str(v) for v in gp),
        "]",
        "",
        "///|",
        "/// 每带采样点数，消费方按 lm×band 主序步进。",
        f"pub const PC_B2P_STRIDE : Int = {len(bp_b) // ((MAX_LM + 1) * NB_BANDS)}",
        "",
    ]
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(
        f"[ok] rebuilt index={len(index)} bits={len(bits)} "
        f"b2p={len(bp_b)} ({len(bp_b) // ((MAX_LM + 1) * NB_BANDS)}/band) "
        f"ties={len(ties)} p2b={len(p2_q)} "
        f"-> pulse_cache_goldens_wbtest.mbt"
    )
    moon_fmt()


if __name__ == "__main__":
    main()
