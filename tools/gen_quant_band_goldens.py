# -*- coding: utf-8 -*-
"""生成 band 级量化解码（RFC 6716 §4.3.4）的 MoonBit 金标。

参考端在 tools/celt_quant_band_ref.py（独立实现），本文件负责：
  - 用例构造与覆盖搜索（随机载荷 + 定向参数覆盖结构键）；
  - MoonBit 调用行、载荷/折叠源/期望频谱字面量与 test 块的生成。
期望 = 整段带内频谱（相对容差比对）+ cm/seed/剩余预算（精确），
另带范围解码器状态对拍。

用法：python tools/gen_quant_band_goldens.py
输出：quant_band_goldens_wbtest.mbt
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_quant_band_ref import quant_band  # noqa: E402
from celt_alloc_ref import T  # noqa: E402
from _fmt import moon_fmt  # noqa: E402

NEED = [
    "q_n1", "q_recombine", "q_time", "q_deint", "q_lowband", "q_fold",
    "q_noise", "q_clear", "q_leaf_pos", "q_rot", "q_lowband_out",
    "q_cm_nz", "q_split", "q_budget",
]


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def band_n(band, lm):
    eb = T["eband5ms"]
    return (eb[band + 1] - eb[band]) << lm


def fmt_f(vals):
    return "[" + ", ".join(repr(float(v)) for v in vals) + "]"


class BandCase:
    """band 级重放用例。"""

    def __init__(self, name, label, data, band, lm, b, blocks, tf_change,
                 fill, gain, spread, seed, remaining, has_lowband,
                 want_lowband_out):
        self.name = name
        self.label = label
        self.data = data
        self.band = band
        self.lm = lm
        self.n = band_n(band, lm)
        self.b = b
        self.blocks = blocks
        self.tf_change = tf_change
        self.fill = fill
        self.gain = gain
        self.spread = spread
        self.seed = seed
        self.remaining = remaining
        self.has_lowband = has_lowband
        self.want_lowband_out = want_lowband_out
        rs = random.Random(seed ^ 0x5A5A)
        self.lowband = ([rs.uniform(-1.0, 1.0)
                         for _ in range(self.n)] if has_lowband else [])
        self.x = [0.0] * self.n
        self.diag = {}

    def run(self):
        self.dec = RangeDecoder(self.data)
        x = list(self.x)
        lowband = list(self.lowband) if self.has_lowband else None
        lo_out = [0.0] * self.n if self.want_lowband_out else None
        cm, seed2, rem = quant_band(
            self.dec, x, lowband, self.band, self.lm, self.n, self.b,
            self.blocks, self.tf_change, self.fill, self.gain, self.spread,
            self.seed, self.remaining, lo_out, self.diag)
        self.want_x = x
        self.want_cm = cm
        self.want_seed = seed2
        self.want_rem = rem
        self.want_lo = lo_out if lo_out is not None else []
        self.state = (self.dec.rng, self.dec.val, self.dec.tell(),
                      self.dec.tell_frac())


def build_cases():
    cases = []
    diag = {}
    seq = 0

    def add(label, nbytes, seed, band, lm, b, blocks, tf_change, fill, gain,
            spread, rseed, remaining, has_lowband, want_lo):
        nonlocal seq
        c = BandCase("qb%d" % seq, label, rand_bytes(nbytes, seed), band, lm,
                     b, blocks, tf_change, fill, gain, spread, rseed,
                     remaining, has_lowband, want_lo)
        c.run()
        for k, v in c.diag.items():
            diag[k] = diag.get(k, 0) + v
        cases.append(c)
        seq += 1
        return c

    # 结构键定向：n=1、TF 三型、折叠/噪声/清零、旋转、预算、深分割
    add("n=1 符号位（预算充足）", 32, 3000, 0, 0, 8, 1, 0, 15, 1.0, 0,
        424242, 100, False, False)
    add("n=1 符号位（预算不足不读）", 32, 3001, 0, 0, 8, 1, 0, 15, 1.0, 0,
        424243, 3, False, False)
    add("recombine 变换（tf=+1, B=4）", 128, 3002, 15, 2, 60, 4, 1, 15, 0.5,
        0, 424244, 800, False, False)
    add("时间升频与重排（tf=-1, B=8）", 128, 3003, 15, 3, 200, 8, -1, 15,
        1.0, 0, 424245, 3000, False, False)
    add("仅重排（B=2, tf=0）", 64, 3004, 15, 1, 40, 2, 0, 15, 1.0, 1,
        424246, 800, False, False)
    # blocks=2 + fill=1：使 leaf 的 f=fill&mask 与 mask 不等（cm 区分）
    add("折叠填充与 lowband_out", 64, 3005, 8, 1, 8, 2, 0, 1, 1.0, 0,
        424247, 500, True, True)
    add("折叠源 × TF 前向变换（tf=-1）", 64, 3012, 15, 3, 8, 1, -1, 15, 1.0,
        0, 424254, 500, True, False)
    add("噪声填充（无折叠源）", 64, 3006, 8, 1, 8, 1, 0, 15, 1.0, 0,
        424248, 500, False, False)
    add("fill=0 清零", 32, 3007, 8, 1, 8, 1, 0, 0, 1.0, 0, 424249, 500,
        True, False)
    add("展宽旋转（spread=3, 长块）", 64, 3008, 19, 0, 30, 1, 0, 0, 1.0, 3,
        424250, 800, False, False)
    add("预算逼退脉冲", 64, 3009, 15, 0, 40, 1, 0, 15, 1.0, 0, 424251, 6,
        False, False)
    add("深分割 + 紧预算", 256, 3010, 15, 3, 1200, 1, 0, 15, 0.25, 2,
        424252, 60, False, False)
    add("大带纯叶（q>0, cm 非零）", 64, 3011, 20, 0, 200, 1, 0, 0, 1.0, 0,
        424253, 3000, False, False)

    need = [k for k in NEED if k not in diag]
    rs = random.Random(20261011)
    tries = 0
    while need and tries < 60000:
        tries += 1
        band = rs.choice([0, 4, 8, 12, 15, 17, 19, 20])
        lm = rs.choice([0, 1, 2, 3])
        blocks = rs.choice([1, 1 << lm])
        c = BandCase(
            "qbx%d" % tries, f"覆盖搜索 {tries}",
            rand_bytes(rs.choice([8, 32, 128, 512]), 3100 + tries),
            band, lm,
            rs.choice([8, 20, 40, 60, 120, 300, 800, 1200]),
            blocks,
            rs.choice([-3, -2, -1, 0, 1, 2, 3]),
            rs.choice([0, 1, 5, 15]),
            rs.choice([0.25, 0.5, 1.0, 2.0]),
            rs.choice([0, 1, 2, 3]),
            rs.randrange(1 << 32),
            rs.choice([4, 6, 10, 50, 300, 4000, 64000]),
            rs.random() < 0.4,
            rs.random() < 0.3)
        c.run()
        new = [k for k in c.diag if k in need]
        if new:
            for k, v in c.diag.items():
                diag[k] = diag.get(k, 0) + v
            c.name = "qb%d" % seq
            cases.append(c)
            seq += 1
            need = [k for k in NEED if k not in diag]
        tries += 1
    if need:
        raise SystemExit(f"quant_band coverage incomplete: {need} "
                         f"(tries={tries})")
    return cases, diag


def emit_case(c):
    rng, val, tell, tf = c.state
    lowband_lit = fmt_f(c.lowband) if c.has_lowband else "[]"
    lo_out_init = f"Array::make({c.n}, 0.0)" if c.want_lowband_out else "[]"
    lo_out_arg = "lo_out"
    lo_want = fmt_f(c.want_lo) if c.want_lo else "[]"
    out = ["", "///|",
           f"fn play_{c.name}(dec : RangeDecoder) -> Unit raise {{"]
    out.append("  // 载荷与期望值由 tools/gen_quant_band_goldens.py 的独立")
    out.append("  // Python 参考端算出，重放同一载荷后整带比对。")
    out.append(f"  let x : Array[Double] = Array::make({c.n}, 0.0)")
    out.append(f"  let lowband : Array[Double] = {lowband_lit}")
    out.append(f"  let lo_out : Array[Double] = {lo_out_init}")
    out.append(f"  let want_lo : Array[Double] = {lo_want}")
    out.append(f"  let want_x : Array[Double] = {fmt_f(c.want_x)}")
    out.append("  let (cm, seed2, rem) = celt_quant_band(")
    out.append(
        f"    dec, x, lowband, {c.band}, {c.lm}, {c.n}, {c.b}, "
        f"{c.blocks}, {c.tf_change}, {c.fill}, {c.gain!r}, {c.spread}, "
        f"{c.seed}L, {c.remaining}, {lo_out_arg},")
    out.append("  )")
    out.append("  expect_band(")
    out.append(
        f"    x, want_x, lo_out, want_lo, cm, {c.want_cm}, seed2, "
        f"{c.want_seed}L, rem, {c.want_rem},")
    out.append(f'    "{c.name}",')
    out.append("  )")
    out.append(
        f'  expect_dec_state(dec, "{c.name}", {rng}L, {val}L, '
        f"{tell}, {tf})")
    out.append("}")
    out.append("")
    return "\n".join(out)


def emit_test(c):
    return "\n".join([
        "",
        "///|",
        f'test "金标：quant_band · {c.label}" {{',
        f"  let dec = RangeDecoder::new(QB_{c.name.upper()}_BITS)",
        f"  play_{c.name}(dec)",
        "}",
        "",
    ])


def main():
    cases, diag = build_cases()
    lines = ["\n".join([
        "// 由 tools/gen_quant_band_goldens.py 生成，请勿手改。",
        "//",
        "// band 级量化解码（RFC 6716 §4.3.4）金标：载荷、折叠源与期望频谱",
        "// 由本脚本内的独立 Python 参考端算出（四段结构：n=1 符号、TF 前段、",
        "// 递归分割 + 叶上谱应用、频序还原与 cm 变换），MoonBit 端重放同一",
        "// 载荷后整带按相对容差比对，cm/seed/剩余预算与解码器状态精确比对。",
        "",
        "///|",
        "",
    ])]
    for c in cases:
        hexlit = 'b"' + "".join("\\x%02x" % b for b in c.data) + '"'
        lines.append("\n".join([
            "",
            "///|",
            f"const QB_{c.name.upper()}_BITS : Bytes = {hexlit}",
            "",
        ]))
        lines.append(emit_case(c))
        lines.append(emit_test(c))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "quant_band_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    keys = " ".join(f"{k}={v}" for k, v in sorted(diag.items()))
    print(f"[ok] {len(cases)} cases -> quant_band_goldens_wbtest.mbt")
    print(f"[cov] {keys}")
    moon_fmt()


if __name__ == "__main__":
    main()
