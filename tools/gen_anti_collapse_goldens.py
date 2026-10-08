# -*- coding: utf-8 -*-
"""生成反塌缩（RFC 6716 §4.3.5）的 MoonBit 金标。

参考端在 tools/celt_anti_collapse_ref.py（独立实现），本文件负责：
  - 用例构造与覆盖搜索（随机频谱/位图/能量，定向补覆盖键）；
  - 反塌缩标志位 raw bit 解码的金标（载荷 + 范围解码器状态）；
  - lcg 序列金标（celt_lcg_rand 的定点步进）；
  - MoonBit 调用行、输入/期望字面量与 test 块的生成。

用法：python tools/gen_anti_collapse_goldens.py
输出：anti_collapse_goldens_wbtest.mbt
"""
import os
import random
import sys
from decimal import Decimal

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_anti_collapse_ref import (  # noqa: E402
    anti_collapse,
    lcg_rand,
)
from celt_alloc_ref import NB_EBANDS, T  # noqa: E402
from _fmt import moon_fmt  # noqa: E402

NEED = [
    "a_fill", "a_no_fill_band", "a_full_fill_band", "a_lm3",
    "a_ediff_clamp", "a_thresh_cap", "a_quirk", "a_depth0",
]


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def fmt_f(v):
    """Double → MoonBit 字面量：非科学计数展开，零与负零归一。"""
    if v == 0.0:
        return "0.0"
    s = repr(v)
    if "e" in s or "E" in s:
        s = str(Decimal(s))
    return s


class AntiCase:
    """反塌缩重放用例（无熵：输入全部为字面量参数）。"""

    def __init__(self, name, label, lm, start, end, diag=None):
        self.name = name
        self.label = label
        self.lm = lm
        self.start = start
        self.end = end
        m = 1 << lm
        self.x = None
        self.masks = None
        self.loge = None
        self.prev1 = None
        self.prev2 = None
        self.pulses = None
        self.seed = 0
        self.want = None
        self.diag = {}

    def fill_random(self, seed):
        rs = random.Random(seed)
        m = 1 << self.lm
        self.x = [rs.uniform(-1.0, 1.0) for _ in range(120 * m)]
        self.masks = [rs.randrange(256) for _ in range(NB_EBANDS)]
        self.loge = [rs.uniform(-20.0, 20.0) for _ in range(2 * NB_EBANDS)]
        self.prev1 = [rs.uniform(-20.0, 20.0) for _ in range(2 * NB_EBANDS)]
        self.prev2 = [rs.uniform(-20.0, 20.0) for _ in range(2 * NB_EBANDS)]
        self.pulses = [rs.randrange(200) for _ in range(NB_EBANDS)]
        self.seed = rs.randrange(1 << 32)

    def run(self):
        ref_x = list(self.x)
        anti_collapse(ref_x, self.masks, self.lm, self.start, self.end,
                      self.loge, self.prev1, self.prev2, self.pulses,
                      self.seed, self.diag)
        self.want = ref_x


class FlagCase:
    """反塌缩标志位 raw bit 解码用例。"""

    def __init__(self, name, label, data, rsv):
        self.name = name
        self.label = label
        self.data = data
        self.rsv = rsv
        self.dec = RangeDecoder(data)
        self.want = None
        self.state = None

    def run(self):
        self.want = self.dec.dec_bits(1) if self.rsv > 0 else 0
        self.state = (self.dec.rng, self.dec.val, self.dec.tell(),
                      self.dec.tell_frac())


def build_cases():
    cases = []
    diag = {}
    seq = 0

    def add(label, lm, start, end, seed, tweak=None):
        nonlocal seq
        c = AntiCase("ac%d" % seq, label, lm, start, end)
        c.fill_random(seed)
        if tweak:
            tweak(c)
        c.run()
        for k, v in c.diag.items():
            diag[k] = diag.get(k, 0) + v
        cases.append(c)
        seq += 1

    def raise_prev(c):
        for i in range(NB_EBANDS):
            c.prev1[NB_EBANDS + i] = 50.0

    def clamp_ediff(c):
        for i in range(NB_EBANDS):
            c.loge[i] = -30.0
            c.prev1[i] = 10.0
            c.prev2[i] = 10.0

    def zero_pulses(c):
        for i in range(NB_EBANDS):
            c.pulses[i] = 0

    def mask_extremes(c):
        c.masks[0] = 0x3
        c.masks[1] = 0x0

    # 结构性键定向构造，状态性键由随机分布天然覆盖
    add("2.5ms 全带随机", 0, 0, NB_EBANDS, 9400)
    add("声道1槽位抬高 prev（C==1 max 分支）", 1, 0, NB_EBANDS, 9401,
        raise_prev)
    add("Ediff 为负走下限 0", 0, 0, NB_EBANDS, 9402, clamp_ediff)
    add("LM=3 的 sqrt2 因子", 3, 0, NB_EBANDS, 9403)
    add("depth=0（pulses 全 0）", 0, 0, NB_EBANDS, 9404, zero_pulses)
    add("满掩码与零掩码各一带", 1, 0, NB_EBANDS, 9405, mask_extremes)
    add("窄窗 start=5 end=12", 2, 5, 12, 9406)

    need = [k for k in NEED if k not in diag]
    rs = random.Random(20261010)
    tries = 0
    while need and tries < 40000:
        tries += 1
        lm = rs.choice([0, 1, 2, 3])
        start = rs.choice([0, 0, 3, 5])
        end = rs.choice([21, 21, 17, 12])
        if start >= end:
            continue
        c = AntiCase("acx%d" % tries, f"覆盖搜索 {tries}", lm, start, end)
        c.fill_random(9500 + tries)
        c.run()
        new = [k for k in c.diag if k in need]
        if new:
            for k, v in c.diag.items():
                diag[k] = diag.get(k, 0) + v
            c.name = "ac%d" % seq
            cases.append(c)
            seq += 1
            need = [k for k in NEED if k not in diag]
    if need:
        raise SystemExit(f"anti-collapse coverage incomplete: {need}")
    return cases, diag


def build_flag_cases():
    cases = []
    specs = [("acflag0", "标志位=0 的载荷", 64, 9600, 8),
             ("acflag1", "标志位=1 的载荷", 64, 9601, 8),
             ("acflag2", "无预留不读位", 64, 9602, 0)]
    for name, label, nbytes, seed, rsv in specs:
        c = FlagCase(name, label, rand_bytes(nbytes, seed), rsv)
        c.run()
        cases.append(c)
    return cases


def fmt_arr_int(vals):
    return "[" + ", ".join(str(int(v)) for v in vals) + "]"


def fmt_arr_f(vals):
    return "[" + ", ".join(fmt_f(v) for v in vals) + "]"


def emit_anti_case(c):
    out = ["", "///|", f"fn play_{c.name}() -> Unit raise {{"]
    out.append("  let x : Array[Double] = " + fmt_arr_f(c.x))
    out.append("  let masks : Array[Int] = " + fmt_arr_int(c.masks))
    out.append("  let loge : Array[Double] = " + fmt_arr_f(c.loge))
    out.append("  let prev1 : Array[Double] = " + fmt_arr_f(c.prev1))
    out.append("  let prev2 : Array[Double] = " + fmt_arr_f(c.prev2))
    out.append("  let pulses : Array[Int] = " + fmt_arr_int(c.pulses))
    out.append(f"  let seed = {c.seed}L")
    out.append(
        f"  celt_anti_collapse(x, masks, {c.lm}, {c.start}, {c.end}, "
        "loge, prev1, prev2, pulses, seed)")
    out.append(
        f'  expect_dn_close(x, {c.name}_want, "ac {c.label}", '
        "0.000000000001)")
    out.append("}")
    out.append("")
    return "\n".join(out)


def emit_flag_case(c):
    rng, val, tell, tf = c.state
    out = ["", "///|",
           f"fn play_{c.name}(dec : RangeDecoder) -> Unit raise {{"]
    out.append(f"  // 载荷见 ANTI_{c.name.upper()}_BITS；期望值由")
    out.append("  // tools/gen_anti_collapse_goldens.py 的参考端算出。")
    out.append(f"  let got = celt_decode_anti_collapse_flag(dec, {c.rsv})")
    out.append(f'  if got != {c.want} {{')
    out.append(
        f'    @test.fail("{c.name}: flag \\{{got}} != {c.want}")')
    out.append("  }")
    out.append(
        f'  expect_dec_state(dec, "{c.name}", {rng}L, {val}L, {tell}, {tf})')
    out.append("}")
    out.append("")
    return "\n".join(out)


def main():
    cases, diag = build_cases()
    flags = build_flag_cases()
    lcg_seq = []
    s = 42
    for _ in range(10):
        s = lcg_rand(s)
        lcg_seq.append(s)
    lines = ["\n".join([
        "// 由 tools/gen_anti_collapse_goldens.py 生成，请勿手改。",
        "//",
        "// 反塌缩（RFC 6716 §4.3.5）金标：期望频谱由本脚本内的独立",
        "// Python 参考端算出（浮点路径：depth/thresh、Ediff 下限、",
        "// C==1 的 prev max 分支、lcg 符号流与注入后归一化），MoonBit",
        "// 端对同一输入重放后按相对容差逐项比对。",
        "",
        "///|",
        "",
    ])]
    for c in cases:
        lines.append("\n".join([
            "",
            "///|",
            f"let {c.name}_want : Array[Double] = " + fmt_arr_f(c.want),
            "",
        ]))
        lines.append(emit_anti_case(c))
        lines.append("\n".join([
            "",
            "///|",
            f'test "金标：anti-collapse · {c.label}" {{',
            f"  play_{c.name}()",
            "}",
            "",
        ]))
    for c in flags:
        hexlit = 'b"' + "".join("\\x%02x" % b for b in c.data) + '"'
        lines.append("\n".join([
            "",
            "///|",
            f"const ANTI_{c.name.upper()}_BITS : Bytes = {hexlit}",
            "",
        ]))
        lines.append(emit_flag_case(c))
        lines.append("\n".join([
            "",
            "///|",
            f'test "金标：anti-collapse 位 · {c.label}" {{',
            f"  let dec = RangeDecoder::new(ANTI_{c.name.upper()}_BITS)",
            f"  play_{c.name}(dec)",
            "}",
            "",
        ]))
    lines.append("\n".join([
        "",
        "///|",
        "/// celt_lcg_rand 的 10 步推进（seed=42 起，uint32 环绕）。",
        "let ac_lcg_seq : Array[Int64] = [",
        "  " + ", ".join(f"{v}L" for v in lcg_seq),
        "]",
        "",
    ]))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "anti_collapse_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    keys = " ".join(f"{k}={v}" for k, v in sorted(diag.items()))
    print(f"[ok] {len(cases)} anti + {len(flags)} flag cases "
          f"-> anti_collapse_goldens_wbtest.mbt")
    print(f"[cov] {keys}")
    moon_fmt()


if __name__ == "__main__":
    main()
