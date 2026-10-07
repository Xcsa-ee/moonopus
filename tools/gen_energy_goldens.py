# -*- coding: utf-8 -*-
"""生成 CELT 能量解码（RFC 6716 §4.3.2）的 MoonBit 金标测试。

范围解码端复用 tools/gen_range_goldens.py 的独立参考实现；能量三步
（coarse / fine / finalise）与底层 Laplace 解码在 celt_energy_ref.py 里按
RFC 6716 与 libopus 参考源再实现一遍（保持独立的理由见该文件的说明），
算出期望的能量向量与解码器状态，交给 MoonBit 的 celt_energy.mbt 重放比对。

本文件负责用例构造与 MoonBit 调用行的生成：每条调用行与参考端的调用在
同一处成对生成，参数不会漂移。

预算恒取解码器自身的载荷长度——与参考实现「budget = ec_dec 的 storage × 8」
的语义一致，短载荷天然触发降级分支，不需要人为缩短预算。

用法：python tools/gen_energy_goldens.py
输出：energy_goldens_wbtest.mbt（载荷常量 + 重放函数）
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from _fmt import moon_fmt  # noqa: E402

from celt_energy_ref import (  # noqa: E402
    E_PROB,
    NB_EBANDS,
    coarse_energy,
    energy_finalise,
    fine_energy,
    init_e,
    laplace_decode,
)


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def merge(dst, src):
    """累加各用例的分支计数（覆盖统计要总数，不能后者覆盖前者）。"""
    for k, v in src.items():
        dst[k] = dst.get(k, 0) + v


# ------------------------------------------------------------- 用例构造

class Case:
    """一个金标用例：一边跑参考端，一边登记等价的 MoonBit 调用行。"""

    def __init__(self, name, data):
        self.name = name
        self.data = data
        self.dec = RangeDecoder(data)
        self.old_e = init_e()
        self.diag = {}
        self.calls = []
        self.locals = []     # (变量名, 值, 类型)  play 函数里的局部数组

    def _local(self, name, arr, kind):
        if not any(n == name for n, _a, _k in self.locals):
            self.locals.append((name, list(arr), kind))

    def laplace(self, pairs, rounds):
        for k in range(rounds):
            fs, decay = pairs[k % len(pairs)]
            want = laplace_decode(self.dec, fs, decay, self.diag)
            rng, val, tell, tf = self.state()
            self.calls.append(
                f"expect_laplace(dec, {fs}, {decay}, \"{self.name}#{k}\", "
                f"{want}, {rng}L, {val}L, {tell}, {tf})")

    def coarse(self, start, end, intra, lm):
        coarse_energy(self.dec, self.old_e, start, end, intra, lm, self.diag)
        self.calls.append(
            f"cel_unquant_coarse_energy(dec, old_e, {start}, {end}, "
            f"{'true' if intra else 'false'}, {lm})")

    def fine(self, start, end, extra_quant):
        self._local("extra_quant", extra_quant, "i")
        fine_energy(self.dec, self.old_e, start, end, extra_quant, self.diag)
        self.calls.append(
            f"cel_unquant_fine_energy(dec, old_e, {start}, {end}, extra_quant)")

    def finalise(self, start, end, fine_quant, fine_priority, bits_left):
        self._local("fine_quant", fine_quant, "i")
        self._local("fine_priority", fine_priority, "i")
        energy_finalise(self.dec, self.old_e, start, end, fine_quant,
                        fine_priority, bits_left, self.diag)
        self.calls.append(
            f"cel_unquant_energy_finalise(dec, old_e, {start}, {end}, "
            f"fine_quant, fine_priority, {bits_left})")

    def state(self):
        d = self.dec
        return (d.rng, d.val, d.tell(), d.tell_frac())

    @property
    def want(self):
        return list(self.old_e)

    def branches(self):
        return {k for k in self.diag if k.startswith("c_")}


def laplace_params():
    """Laplace 参数对：真实表里的 (fs, decay) 加上两端极值。"""
    pairs = []
    for lm in range(4):
        for intra in (0, 1):
            base = (lm * 2 + intra) * 42
            for band in (0, 3, 10, 20):
                pi = 2 * band
                pairs.append((E_PROB[base + pi] << 7, E_PROB[base + pi + 1] << 6))
    pairs.append((72 << 7, 1 << 6))      # 表内最小 fs 附近 + 最小 decay
    pairs.append((255 << 7, 179 << 6))   # 两者都取到上限
    pairs.append((E_PROB[1] << 7, 179 << 6))
    return pairs


def build_cases():
    cases = []
    pairs = laplace_params()
    diag = {}

    # A. Laplace 直测：参数轮转 40 个符号
    c = Case("laplace", rand_bytes(64, 11))
    c.laplace(pairs, 40)
    merge(diag, c.diag)
    cases.append(c)

    # B..F. 粗能量：不同 lm / intra / 带窗（窗口用例验证窗外频带不被改动）
    for name, nbytes, lm, intra, seed in [
        ("coarse_inter960", 64, 3, False, 21),
        ("coarse_intra960", 64, 3, True, 22),
        ("coarse_inter120", 32, 0, False, 23),
        ("coarse_intra240", 32, 1, True, 24),
        ("coarse_window", 64, 2, False, 25),
    ]:
        start, end = (5, 17) if name == "coarse_window" else (0, NB_EBANDS)
        c = Case(name, rand_bytes(nbytes, seed))
        c.coarse(start, end, intra, lm)
        merge(diag, c.diag)
        cases.append(c)

    # G. 降级分支：短载荷天然触发 icdf / bit_logp / 无比特三条路径。
    #    bit 分支要求 budget-tell 恰好等于 1，命中率低，多搜几例。
    want = {"c_laplace", "c_icdf", "c_bit", "c_none"}
    seen = set()
    bit_hits = 0
    seed = 100
    while seed < 40000:
        c = Case("coarse_short_%d" % seed, rand_bytes(1 + (seed % 6), seed))
        c.coarse(0, NB_EBANDS, False, 3)
        new = c.branches() - seen
        hit_bit = "c_bit" in c.diag
        if new or hit_bit:
            seen |= new
            bit_hits += 1 if hit_bit else 0
            cases.append(c)
            merge(diag, c.diag)
        if want <= seen and bit_hits >= 3:
            break
        seed += 1
    if not want <= seen:
        raise SystemExit(f"粗能量降级分支未全覆盖: {want - seen}")
    if bit_hits < 3:
        raise SystemExit(f"bit 分支只覆盖到 {bit_hits} 例")

    # H. 细能量与收尾
    extra_quant = [0, 1, 3, 2, 0, 8, 4, 1, 0, 5, 2, 0, 6, 3, 1, 0, 7, 2, 4, 1, 0]
    fine_quant = [0, 2, 8, 1, 0, 7, 3, 5, 0, 4, 6, 1, 2, 8, 0, 3, 1, 7, 0, 5, 2]
    fine_prio = [i % 2 for i in range(NB_EBANDS)]

    c = Case("fine", rand_bytes(64, 31))
    c.coarse(0, NB_EBANDS, False, 3)
    c.fine(0, NB_EBANDS, extra_quant)
    merge(diag, c.diag)
    cases.append(c)

    c = Case("finalise", rand_bytes(64, 32))
    c.coarse(0, NB_EBANDS, False, 3)
    c.finalise(0, NB_EBANDS, fine_quant, fine_prio, 40)
    merge(diag, c.diag)
    cases.append(c)

    c = Case("finalise_short", rand_bytes(64, 33))
    c.coarse(0, NB_EBANDS, False, 3)
    c.finalise(0, NB_EBANDS, fine_quant, fine_prio, 5)
    merge(diag, c.diag)
    cases.append(c)

    # I. 三步串成一帧的完整链路
    c = Case("chain", rand_bytes(64, 34))
    c.coarse(0, NB_EBANDS, False, 3)
    c.fine(0, NB_EBANDS, extra_quant)
    c.finalise(0, NB_EBANDS, fine_quant, fine_prio, 40)
    merge(diag, c.diag)
    cases.append(c)

    # J. 细能量因预算不足而跳过：短载荷 + 满格 extra
    seed = 700
    while seed < 40000:
        c = Case("fine_exhausted_%d" % seed,
                 rand_bytes(4 + (seed % 4), seed))
        c.coarse(0, NB_EBANDS, False, 3)
        c.fine(0, NB_EBANDS, [8] * NB_EBANDS)
        if "f_budget" in c.diag:
            cases.append(c)
            merge(diag, c.diag)
            break
        seed += 1
    else:
        raise SystemExit("细能量的预算跳过路径未覆盖")

    # K. Laplace 衰减链走到尾部（每格只剩 LAPLACE_MINP）需要 fm 落在高位，
    #    命中率低，同样多搜几例。
    tail_hits = 0
    seed = 500
    while seed < 80000:
        c = Case("laplace_tail_%d" % seed, rand_bytes(64, seed))
        c.laplace(pairs, 60)
        if "lap_tail" in c.diag:
            cases.append(c)
            merge(diag, c.diag)
            tail_hits += 1
            if tail_hits >= 3:
                break
        seed += 1
    else:
        raise SystemExit(f"Laplace 尾部路径只覆盖到 {tail_hits} 例")

    # 覆盖断言：缺哪条就说明用例集合有盲区
    need = [
        "c_laplace", "c_icdf", "c_bit", "c_none",
        "lap_zero", "lap_chain", "lap_tail",
        "f_applied", "f_zero", "f_budget",
        "z_max", "z_prio", "z_left",
    ]
    missing = [k for k in need if k not in diag]
    if missing:
        raise SystemExit(f"覆盖不全: {missing}")
    return cases, diag


# ------------------------------------------------------------- 生成

def fmt_bytes(data):
    bs = "\\"
    return 'b"' + "".join(bs + "x%02x" % b for b in data) + '"'


def fmt_arr(vals, kind):
    if kind == "f":
        return "[" + ", ".join(repr(float(v)) for v in vals) + "]"
    return "[" + ", ".join(str(int(v)) for v in vals) + "]"


def emit_case(case):
    up = case.name.upper()
    rng, val, tell, tf = case.state()
    out = ["", "///|",
           f"fn play_{case.name}(dec : RangeDecoder) -> Unit raise " + "{",
           f"  // 载荷见 ENER_{up}_BITS；期望值由 tools/gen_energy_goldens.py 的",
           "  // 独立参考端算出，本函数重放同一参数后逐项比对。"]
    out.append(f"  let old_e : Array[Double] = {fmt_arr(init_e(), 'f')}")
    for name, arr, kind in case.locals:
        t = "Array[Int]" if kind == "i" else "Array[Double]"
        out.append(f"  let {name} : {t} = {fmt_arr(arr, kind)}")
    out.extend("  " + line for line in case.calls)
    out.append(f'  expect_energy(old_e, {fmt_arr(case.want, "f")}, '
               f'"{case.name}")')
    out.append(f'  expect_dec_state(dec, "{case.name}", {rng}L, {val}L, '
               f"{tell}, {tf})")
    out.append("}")
    out.append("")
    return chr(10).join(out)


def main():
    cases, diag = build_cases()
    nl = chr(10)
    lines = [
        nl.join([
            "// 由 tools/gen_energy_goldens.py 生成，请勿手改。",
            "//",
            "// 能量解码（RFC 6716 §4.3.2）金标：载荷与期望值由本脚本内的独立",
            "// 参考端算出（不同语言、不同实现路径），MoonBit 的 celt_energy.mbt",
            "// 重放同一参数后逐项比对能量向量与范围解码器状态。",
            "//",
            "// 每个用例的 budget 都等于载荷长度，与参考实现「budget = ec_dec",
            "// 的 storage × 8」一致；降级分支由短载荷自然触发，不人为缩短预算。",
            "",
            "///|",
            "",
        ]),
    ]
    for case in cases:
        lines.append(nl.join([
            "",
            "///|",
            f"const ENER_{case.name.upper()}_BITS : Bytes = "
            f"{fmt_bytes(case.data)}",
            "",
        ]))
        lines.append(emit_case(case))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "energy_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    keys = " ".join(f"{k}={v}" for k, v in sorted(diag.items()))
    print(f"[ok] {len(cases)} cases -> energy_goldens_wbtest.mbt")
    print(f"[cov] {keys}")
    moon_fmt()


if __name__ == "__main__":
    main()
