# -*- coding: utf-8 -*-
"""生成反塌缩（RFC 6716 §4.3.5）的 MoonBit 金标。

参考端在 tools/celt_anti_collapse_ref.py（独立实现），本文件负责：
  - 用例构造与覆盖搜索（随机频谱/位图/能量，结构性键定向配置）；
  - 反塌缩预留位公式与标志位 raw bit 解码的金标（含解码器状态）；
  - lcg 序列金标；
  - MoonBit 调用行、输入字面量与 test 块的生成。

用法：python tools/gen_anti_collapse_goldens.py
输出：anti_collapse_goldens_wbtest.mbt
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_anti_collapse_ref import (  # noqa: E402
    anti_collapse,
    anti_collapse_rsv,
    lcg_rand,
)
from celt_alloc_ref import NB_EBANDS  # noqa: E402
from _fmt import moon_fmt  # noqa: E402

NEED = [
    "a_lm3", "a_depth0", "a_quirk", "a_ediff_clamp", "a_thresh_cap",
    "a_no_fill_band", "a_full_fill_band", "a_fill",
]


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def fmt_arr(vals):
    return "[" + ", ".join(str(v) for v in vals) + "]"


def fmt_f(vals):
    return "[" + ", ".join(repr(float(v)) for v in vals) + "]"


class AntiCase:
    """反塌缩重放用例：随机造输入，参考端跑出期望频谱与覆盖键。"""

    def __init__(self, name, label, lm, start, end, seed, cfg=None):
        self.name = name
        self.label = label
        self.lm = lm
        self.start = start
        self.end = end
        rs = random.Random(seed)
        m = 1 << lm
        n = 120 * m
        self.x = [rs.uniform(-1.0, 1.0) for _ in range(n)]
        self.masks = [rs.randrange(256) for _ in range(NB_EBANDS)]
        self.loge = [rs.uniform(-30.0, 30.0) for _ in range(2 * NB_EBANDS)]
        self.prev1 = [rs.uniform(-30.0, 30.0) for _ in range(2 * NB_EBANDS)]
        self.prev2 = [rs.uniform(-30.0, 30.0) for _ in range(2 * NB_EBANDS)]
        self.pulses = [rs.randrange(160) for _ in range(NB_EBANDS)]
        self.seed = rs.randrange(2 ** 32)
        if cfg:
            cfg(self, rs)
        self.diag = {}

    def run(self):
        ref_x = list(self.x)
        anti_collapse(ref_x, self.masks, self.lm, self.start, self.end,
                      self.loge, self.prev1, self.prev2, self.pulses,
                      self.seed, self.diag)
        self.want = ref_x


class FlagCase:
    """反塌缩标志位解码用例（raw bit + 解码器状态对拍）。"""

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
    """结构性键定向配置；状态键靠随机分布 + 缺啥补啥的搜索。"""
    cases = []
    diag = {}
    seq = 0

    def merge(d, src):
        for k, v in src.items():
            d[k] = d.get(k, 0) + v

    def add(label, lm, start, end, seed, cfg=None):
        nonlocal seq
        c = AntiCase("ac%d" % seq, label, lm, start, end, seed, cfg)
        c.run()
        merge(diag, c.diag)
        cases.append(c)
        seq += 1
        return c

    def cfg_full_fill(c, rs):
        # 全带塌缩：位图全 0 → 每带整段注入并 renorm
        for i in range(NB_EBANDS):
            c.masks[i] = 0x00

    def cfg_no_fill(c, rs):
        # 全带不塌缩：位图全 1 → 输出恒等（renorm 一次都不触发）
        for i in range(NB_EBANDS):
            c.masks[i] = 0xFF

    def cfg_thresh_cap(c, rs):
        # loge == prev → Ediff = 0 → r = 2 > thresh，必然封顶
        for i in range(2 * NB_EBANDS):
            c.loge[i] = 10.0
            c.prev1[i] = 10.0
            c.prev2[i] = 10.0

    def cfg_clamp(c, rs):
        # loge ≪ prev → Ediff 为负走下限 0
        for i in range(2 * NB_EBANDS):
            c.loge[i] = -50.0
            c.prev1[i] = 5.0
            c.prev2[i] = 5.0

    def cfg_quirk(c, rs):
        # 声道 1 槽位（第二半）抬高 prev → C==1 的 max 分支生效
        for i in range(NB_EBANDS):
            c.prev1[NB_EBANDS + i] = 50.0
            c.prev2[NB_EBANDS + i] = 40.0

    def cfg_depth0(c, rs):
        # pulses=0 且 lm≥1 → depth = (1+0)>>lm = 0
        for i in range(NB_EBANDS):
            c.pulses[i] = 0

    def cfg_mixed(c, rs):
        for i in range(0, NB_EBANDS, 3):
            c.masks[i] = 0x00
        for i in range(1, NB_EBANDS, 3):
            c.masks[i] = 0xFF

    add("lm=0 随机全带", 0, 0, NB_EBANDS, 1000)
    add("lm=3 随机全带", 3, 0, NB_EBANDS, 1001)
    add("lm=1 全带塌缩（Ediff=0 封顶）", 1, 0, NB_EBANDS, 1002,
        cfg_full_fill)
    add("lm=2 全带不塌缩（输出恒等）", 2, 0, NB_EBANDS, 1003, cfg_no_fill)
    add("lm=1 Ediff 下限与 thresh 封顶", 1, 0, NB_EBANDS, 1004,
        lambda c, rs: (cfg_thresh_cap(c, rs), cfg_clamp(c, rs)))
    add("lm=1 声道1槽位抬高 prev", 1, 5, 17, 1005, cfg_quirk)
    add("lm=1 depth=0 与混合位图", 1, 0, NB_EBANDS, 1006,
        lambda c, rs: (cfg_depth0(c, rs), cfg_mixed(c, rs)))

    # 缺啥补啥：随机改位图/能量再跑
    need = [k for k in NEED if k not in diag]
    seed = 1100
    while need and seed < 60000:
        c = AntiCase("ag%d" % seed, f"覆盖搜索 {seed}",
                     seed % 4, 0, NB_EBANDS, seed)
        c.run()
        new = [k for k in c.diag if k in need]
        if new:
            merge(diag, c.diag)
            c.name = "ac%d" % seq
            cases.append(c)
            seq += 1
            need = [k for k in NEED if k not in diag]
        seed += 1
    if missing := [k for k in NEED if k not in diag]:
        raise SystemExit(f"anti-collapse coverage incomplete: {missing}")
    return cases, diag


def build_flag_cases():
    specs = [
        ("acflag0", "标志位=0 的载荷", 64, 2000, 8),
        ("acflag1", "标志位=1 的载荷", 64, 2001, 8),
        ("acflag2", "无预留（不读位）", 64, 2002, 0),
    ]
    cases = []
    for name, label, nbytes, seed, rsv in specs:
        c = FlagCase(name, label, rand_bytes(nbytes, seed), rsv)
        c.run()
        cases.append(c)
    return cases


def emit_anti_case(case):
    out = ["", "///|",
           f"fn play_split_ac_{case.name}() -> Unit raise {{"]
    out.append("  // 输入与期望值由 tools/gen_anti_collapse_goldens.py 的")
    out.append("  // 独立参考端算出，重放同一输入后按相对容差比对整段频谱。")
    out.append(f"  let x : Array[Double] = {fmt_f(case.x)}")
    out.append(f"  let masks : Array[Int] = {fmt_arr(case.masks)}")
    out.append(f"  let loge : Array[Double] = {fmt_f(case.loge)}")
    out.append(f"  let prev1 : Array[Double] = {fmt_f(case.prev1)}")
    out.append(f"  let prev2 : Array[Double] = {fmt_f(case.prev2)}")
    out.append(f"  let pulses : Array[Int] = {fmt_arr(case.pulses)}")
    out.append(f"  let want : Array[Double] = {fmt_f(case.want)}")
    out.append(
        f"  celt_anti_collapse(x, masks, {case.lm}, {case.start}, "
        f"{case.end}, loge, prev1, prev2, pulses, {case.seed}L)")
    out.append(
        f'  expect_dn_close(x, want, "{case.name}", 0.000000000001)')
    out.append("}")
    out.append("")
    return "\n".join(out)


def emit_flag_case(case):
    rng, val, tell, tf = case.state
    out = ["", "///|",
           f"fn play_{case.name}(dec : RangeDecoder) -> Unit raise {{"]
    out.append(f"  // 载荷见 ANTI_{case.name.upper()}_BITS；期望值由")
    out.append("  // tools/gen_anti_collapse_goldens.py 的独立参考端算出。")
    out.append(f"  let got = celt_decode_anti_collapse_flag(dec, {case.rsv})")
    out.append(f'  if got != {case.want} {{')
    out.append(f'    @test.fail("{case.name}: flag got \\{{got}} != {case.want}")')
    out.append("  }")
    out.append(
        f'  expect_dec_state(dec, "{case.name}", {rng}L, {val}L, '
        f"{tell}, {tf})")
    out.append("}")
    out.append("")
    return "\n".join(out)


def main():
    cases, diag = build_cases()
    flags = build_flag_cases()
    lines = ["\n".join([
        "// 由 tools/gen_anti_collapse_goldens.py 生成，请勿手改。",
        "//",
        "// 反塌缩（RFC 6716 §4.3.5）金标：输入频谱、位图、能量与期望输出",
        "// 全部由本脚本内的独立 Python 参考端算出（浮点路径逐行对应",
        "// celt_bands.c 的 anti_collapse 与 celt_vq.c 的 renormalise_vector），",
        "// MoonBit 端重放同一输入后按相对容差比对整段频谱；标志位用例另带",
        "// 范围解码器状态对拍。",
        "",
        "///|",
        "",
    ])]
    for case in cases:
        lines.append(emit_anti_case(case))
        lines.append("\n".join([
            "",
            "///|",
            f'test "金标：anti-collapse · {case.label}" {{',
            f"  play_split_ac_{case.name}()",
            "}",
            "",
        ]))
    for case in flags:
        hexlit = 'b"' + "".join("\\x%02x" % b for b in case.data) + '"'
        lines.append("\n".join([
            "",
            "///|",
            f"const ANTI_{case.name.upper()}_BITS : Bytes = {hexlit}",
            "",
        ]))
        lines.append(emit_flag_case(case))
        lines.append("\n".join([
            "",
            "///|",
            f'test "金标：anti-collapse 标志位 · {case.label}" {{',
            f"  let dec = RangeDecoder::new(ANTI_{case.name.upper()}_BITS)",
            f"  play_{case.name}(dec)",
            "}",
            "",
        ]))
    # lcg 序列：seed=0 起 10 步（首项 1013904223 即 C 常量加数）
    seq = []
    s = 0
    for _ in range(10):
        s = lcg_rand(s)
        seq.append(s)
    lines.append("\n".join([
        "",
        "///|",
        "/// celt_lcg_rand 从 0 起的 10 步序列（首项即 LCG 常量 1013904223）。",
        "let ac_lcg_seq : Array[Int64] = [",
        "  " + ", ".join(f"{v}L" for v in seq),
        "]",
        "",
    ]))
    # 预留位公式的双向网格：[is_transient, lm, bits, want] 平铺
    rsv_rows = []
    for transient in (False, True):
        for lm in (0, 1, 2, 3):
            for bits in (0, 4, 31, 32, 33, 39, 40, 41, 100):
                rsv_rows += [int(transient), lm, bits,
                             anti_collapse_rsv(transient, lm, bits)]
    lines.append("\n".join([
        "",
        "///|",
        "/// 预留位公式的网格金标：每 4 项一组 [瞬态, lm, 预算, 期望]。",
        "let ac_rsv_grid : Array[Int] = [",
        "  " + ", ".join(str(v) for v in rsv_rows),
        "]",
        "",
        "///|",
        "test \"金标：anti-collapse 预留位公式\" {",
        "  for i in 0..<(ac_rsv_grid.length() / 4) {",
        "    let base = i * 4",
        "    let got = celt_anti_collapse_rsv(",
        "      ac_rsv_grid[base] != 0, ac_rsv_grid[base + 1],",
        "      ac_rsv_grid[base + 2],",
        "    )",
        "    if got != ac_rsv_grid[base + 3] {",
        "      @test.fail(",
        "        \"rsv 网格行 \\{i} 期望 \\{ac_rsv_grid[base + 3]} 实得 \\{got}\",",
        "      )",
        "    }",
        "  }",
        "}",
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
