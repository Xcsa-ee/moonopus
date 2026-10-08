# -*- coding: utf-8 -*-
"""生成 quant_all_bands 主循环（RFC 6716 §4.3.4）的 MoonBit 金标。

参考端在 tools/celt_quant_all_bands_ref.py（独立实现），本文件负责：
  - 用例构造与覆盖搜索（随机分配/TF/预算 + 定向参数覆盖结构键）；
  - MoonBit 调用行、载荷与期望值（频谱、masks、seed）字面量的生成。
每用例重放整条主循环：频谱按相对容差比对，masks/seed/解码器状态精确。

用法：python tools/gen_quant_all_bands_goldens.py
输出：quant_all_bands_goldens_wbtest.mbt
"""
import io
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_quant_all_bands_ref import quant_all_bands  # noqa: E402
from celt_alloc_ref import NB_EBANDS  # noqa: E402
from _fmt import moon_fmt  # noqa: E402

REF_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                        "celt_quant_all_bands_ref.py")


def ref_variant(old, new):
    """把参考端源码就地改一处，装载为独立函数（分叉搜索用）。"""
    src = io.open(REF_PATH, encoding="utf-8", newline="").read()
    if src.count(old) != 1:
        raise SystemExit(f"ref 变体锚点出现 {src.count(old)} 次: {old!r}")
    ns = {"__file__": REF_PATH, "__name__": "ref_mut"}
    exec(compile(src.replace(old, new, 1), "ref_mut", "exec"), ns)
    return ns["quant_all_bands"]


def replay(qab, c):
    """用给定主循环函数重放用例输入，返回四元组输出。"""
    dec = RangeDecoder(c.data)
    x = [0.0] * (120 * c.m)
    masks = [0] * NB_EBANDS
    seed2 = qab(dec, x, c.start, c.end, c.lm, c.short_blocks, c.pulses,
                c.tf_res, c.coded_bands, c.total_bits, c.balance,
                c.spread, c.seed, masks, {})
    return (x, masks, seed2,
            (dec.rng, dec.val, dec.tell(), dec.tell_frac()))


# 分叉搜索的 5 处编辑（与 tools/mutate_quant_all_bands.py 中最初变绿的
# 变异一一对应）：把参考端就地改成同样语义，双路重放找可区分输入。
DIV_EDITS = [
    ("预算夹逼的 -1 项",
     "remaining_bits = total_bits - tell - 1",
     "remaining_bits = total_bits - tell"),
    ("b 夹逼的 remaining+1",
     "min(remaining_bits + 1,",
     "min(remaining_bits,"),
    ("hybrid folding 补拷源",
     "norm[n1:n1 + ln] = norm[2 * n1 - n2:2 * n1 - n2 + ln]",
     "norm[n1:n1 + ln] = norm[n2 - n1:n2 - n1 + ln]"),
    ("保守 cm 的 tf 判定",
     "or blocks > 1 or tf_change < 0",
     "or blocks > 1 or tf_change <= 0"),
    ("无折叠源 fill 全 1",
     "x_cm = (1 << blocks) - 1",
     "x_cm = (1 << blocks)"),
]


def build_div_pool():
    """分叉搜索候选池：按 5 处编辑各自的结构前提定向造参。"""
    rp = random.Random(20261014)
    pool = []

    # A 预算夹逼：小载荷 + 小 total + 正脉冲，使 remaining+1 落在
    #   pulses+curr 与 0 之间（夹逼恰好咬住、且 ±1 可能跨脉冲阈值）
    for k in range(150):
        pool.append(QabCase(
            "pa%d" % k, "pa", rand_bytes(32, 6100 + k),
            rp.choice([0, 0, 5]), 21, rp.choice([0, 0, 1]),
            rp.random() < 0.3, rp.choice([21, 17, 12]),
            rp.choice([30, 50, 80, 120, 200, 400]),
            rp.choice([-60, -20, 0, 50, 200]), rp.choice([0, 1, 2, 3]),
            rp.randrange(1 << 32), None))
    # B 无折叠源且 q==0：长块 spread=3 tf≡0（tf_select 表长块仅 {0}）、
    #   负 balance + 全零/小脉冲使各带 b=0 —— 覆盖 else 分支 fill=全1
    #   被 q==0 消费的路径（噪声填充），以及 tf<=0 误入折叠的分叉
    for k in range(150):
        c = QabCase(
            "pb%d" % k, "pb", rand_bytes(64, 6300 + k),
            0, 21, 0, False, 21,
            rp.choice([30, 60, 100, 200]), rp.choice([-60, -45, -10]),
            3, rp.randrange(1 << 32), None)
        for i in range(NB_EBANDS):
            c.pulses[i] = rp.choice([0, 0, 4, 10])
        pool.append(c)
    # C hybrid folding 真被读取：start=7（首带宽 1、次带宽 2）、带 7 有
    #   脉冲使 lo_out 非零、带 9 零脉冲且预算咬住使它折叠读回补拷区
    for k in range(150):
        c = QabCase(
            "pc%d" % k, "pc", rand_bytes(64, 6500 + k),
            7, 21, rp.choice([0, 1]), False, rp.choice([14, 17, 21]),
            rp.choice([80, 150, 400, 3000]), rp.choice([-45, -10, 30]),
            rp.choice([1, 2]), rp.randrange(1 << 32), None)
        for i in range(NB_EBANDS):
            c.pulses[i] = rp.choice([0, 4, 12])
        c.pulses[7] = rp.choice([20, 36, 80])
        c.pulses[9] = 0
        pool.append(c)
    return pool


def build_sweep():
    """固定参数扫 total_bits 的细网格：预算类 ±1 分叉要求 tell 恰好
    压过 q/update_lowband/split 阈值，随机池的 total 离散取值撞不上。"""
    out = []
    profiles = [(16, 40, 1), (8, -10, 1), (40, 100, 1), (4, -45, 0),
                (60, 200, 2)]
    for prof, (pval, bal, spread) in enumerate(profiles):
        for total in range(0, 480):
            c = QabCase(
                "sw%d_%d" % (prof, total), "sw",
                rand_bytes(32, 6700 + prof), 0, 21, 0, False, 21,
                total, bal, spread, 999000 + prof, None)
            for i in range(NB_EBANDS):
                c.pulses[i] = pval if i % 2 == 0 else max(0, pval // 2)
            out.append(c)
    return out

NEED = [
    "a_fold", "a_nofold", "a_b_zero", "a_no_update", "a_clamp", "a_cm0",
    "a_cm_partial",
]

# tf_select_table（celt_celt.c，[LM][4*transient+2*tf_select+flag]）——
# tf_decode 之后 tf_res 的合法取值集合。长块（transient=0）恒 ≤0；
# 短块 ≤LM，保证 B>>recombine ≥ 1。越界输入会让参考端与 C 端同样
# 进入 B=0 的退化路径（exp_rotation 死循环），属规范外输入。
TF_SELECT_TABLE = [
    [0, -1, 0, -1, 0, -1, 0, -1],
    [0, -1, 0, -2, 1, 0, 1, -1],
    [0, -2, 0, -3, 2, 0, 1, -1],
    [0, -2, 0, -3, 3, 0, 1, -1],
]


def allowed_tf(lm, transient):
    row = TF_SELECT_TABLE[lm]
    base = 4 if transient else 0
    return sorted(set(row[base:base + 4]))


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def fmt_f(vals):
    return "[" + ", ".join(repr(float(v)) for v in vals) + "]"


def fmt_i(vals):
    return "[" + ", ".join(str(int(v)) for v in vals) + "]"


class QabCase:
    """整循环重放用例。"""

    def __init__(self, name, label, data, start, end, lm, short_blocks,
                 coded_bands, total_bits, balance, spread, seed, cfg=None):
        self.name = name
        self.label = label
        self.data = data
        self.start = start
        self.end = end
        self.lm = lm
        self.short_blocks = short_blocks
        self.coded_bands = coded_bands
        self.total_bits = total_bits
        self.balance = balance
        self.spread = spread
        self.seed = seed
        rs = random.Random(seed ^ 0x3333)
        self.pulses = [rs.randrange(160) for _ in range(NB_EBANDS)]
        tf_opts = allowed_tf(lm, short_blocks)
        self.tf_res = [rs.choice(tf_opts) for _ in range(NB_EBANDS)]
        if cfg:
            cfg(self, rs)
        self.m = 1 << lm
        self.diag = {}

    def run(self):
        self.dec = RangeDecoder(self.data)
        x = [0.0] * (120 * self.m)
        masks = [0] * NB_EBANDS
        seed2 = quant_all_bands(
            self.dec, x, self.start, self.end, self.lm, self.short_blocks,
            self.pulses, self.tf_res, self.coded_bands, self.total_bits,
            self.balance, self.spread, self.seed, masks, self.diag)
        self.want_x = x
        self.want_masks = masks
        self.want_seed = seed2
        self.state = (self.dec.rng, self.dec.val, self.dec.tell(),
                      self.dec.tell_frac())


def build_cases():
    cases = []
    diag = {}
    seq = 0

    def add(label, nbytes, seed, start, end, lm, short_blocks, coded,
            total, bal, spread, rseed, cfg=None):
        nonlocal seq
        c = QabCase("qab%d" % seq, label, rand_bytes(nbytes, seed), start,
                    end, lm, short_blocks, coded, total, bal, spread,
                    rseed, cfg)
        c.run()
        for k, v in c.diag.items():
            diag[k] = diag.get(k, 0) + v
        cases.append(c)
        seq += 1
        return c

    def cfg_pos_tf(c, rs):
        # a_nofold 需要 spread=3 且 blocks=1 且 tf≥0 的带；长块的合法
        # 取值只有 {0}（tf_select_table 约束）
        tf_opts = [v for v in allowed_tf(c.lm, c.short_blocks) if v >= 0]
        for i in range(NB_EBANDS):
            c.tf_res[i] = rs.choice(tf_opts)

    def cfg_zero_tail(c, rs):
        # a_b_zero / a_cm0 倾向：尾部带无脉冲、预算紧
        for i in range(c.coded_bands, NB_EBANDS):
            c.pulses[i] = 0

    def cfg_bal_neg(c, rs):
        for i in range(NB_EBANDS):
            c.pulses[i] = rs.choice([0, 0, 4])

    add("长块全带 预算充足", 512, 4000, 0, NB_EBANDS, 0, False,
        NB_EBANDS, 30000, 400, 0, 555001)
    add("激进扩展无折叠源", 256, 4001, 0, NB_EBANDS, 0, False,
        NB_EBANDS, 20000, 200, 3, 555002, cfg_pos_tf)
    add("尾部带未编码（b=0）", 256, 4002, 0, NB_EBANDS, 0, False,
        17, 20000, 200, 1, 555003, cfg_zero_tail)
    add("紧预算逼出 b=0 与清零", 64, 4003, 0, NB_EBANDS, 0, False,
        NB_EBANDS, 60, -20, 1, 555004, cfg_bal_neg)
    add("瞬态短块（B=M）", 512, 4004, 0, NB_EBANDS, 1, True,
        NB_EBANDS, 25000, 300, 0, 555005)
    add("窄窗 start=5 end=17", 256, 4005, 5, 17, 0, False,
        12, 15000, 100, 2, 555006)
    add("负 balance 记账", 256, 4007, 0, NB_EBANDS, 2, False,
        NB_EBANDS, 40000, -60, 1, 555008, cfg_bal_neg)
    # start=7：首带宽 1、次带宽 2 → ln>0，special_hybrid_folding 真拷贝
    add("起始带宽不等（hybrid folding 补拷）", 256, 4006, 7, NB_EBANDS, 0,
        False, 14, 15000, 100, 1, 555007)

    need = [k for k in NEED if k not in diag]
    print(f"[pre] 覆盖 {len(diag)} 类，缺 {need}")

    # 分叉搜索：对会产生等效变异的细节，找能区分它的输入补定向用例
    pool = build_div_pool()
    sweep = build_sweep()
    for label, old, new in DIV_EDITS:
        mut = ref_variant(old, new)
        hit = None
        for c in pool:
            if replay(mut, c) != replay(quant_all_bands, c):
                hit = c
                break
        if hit is None:
            for c in sweep:
                if replay(mut, c) != replay(quant_all_bands, c):
                    hit = c
                    break
        if hit is None:
            raise SystemExit(f"分叉搜索未命中：{label}")
        # 池中移除，避免同一对象被两处编辑选中后重名
        if hit in pool:
            pool.remove(hit)
        else:
            sweep.remove(hit)
        hit.run()
        for kk, v in hit.diag.items():
            diag[kk] = diag.get(kk, 0) + v
        hit.name = "qab%d" % seq
        hit.label = label
        cases.append(hit)
        seq += 1
        print(f"[div] {label} -> {hit.name}")

    # 定向清零搜索：a_cm0 要求 折叠源覆盖带全 0（范围空）且本带 q==0
    # ——账目上需要 tell 走完后 remaining 恰好把带 9 的 b 压到 ≤8 而带 8
    # 仍 >16，用小载荷 + (总预算, balance, 脉冲剖面) 网格扫描。
    if "a_cm0" in need:
        rs0 = random.Random(20261013)
        totals = [30, 50, 80, 120, 200]
        bals = [-45, -30, -10, 0, 20]
        hit = False
        for k in range(8000):
            total = totals[k % len(totals)]
            bal = bals[(k // len(totals)) % len(bals)]
            p = (k // (len(totals) * len(bals))) % 13
            c = QabCase(
                "qabz%d" % k, f"定向清零 {k}", rand_bytes(16, 5300 + k),
                0, NB_EBANDS, 0, False, NB_EBANDS, total, bal,
                k % 2, rs0.randrange(1 << 32), None)
            for i in range(NB_EBANDS):
                c.pulses[i] = p
            c.pulses[8] = p + 6 + (k // 13) % 10
            c.run()
            if "a_cm0" in c.diag:
                for kk, v in c.diag.items():
                    diag[kk] = diag.get(kk, 0) + v
                c.name = "qab%d" % seq
                cases.append(c)
                seq += 1
                need = [k for k in NEED if k not in diag]
                hit = True
                break
        if not hit and "a_cm0" in need:
            raise SystemExit("定向清零搜索未命中 a_cm0")

    # 随机快搜：小载荷、lm0 为主，补齐其余状态键
    need = [k for k in NEED if k not in diag]
    rs = random.Random(20261012)
    tries = 0
    while need and tries < 4000:
        tries += 1
        c = QabCase(
            "qabx%d" % tries, f"覆盖搜索 {tries}",
            rand_bytes(rs.choice([8, 16, 32]), 4100 + tries),
            rs.choice([0, 0, 0, 5]),
            rs.choice([21, 21, 17]),
            rs.choice([0, 0, 1, 2]),
            rs.random() < 0.4,
            rs.choice([8, 12, 17, 21]),
            rs.choice([30, 60, 100, 300, 3000, 30000]),
            rs.choice([-45, -10, 0, 50, 4000]),
            rs.choice([0, 1, 2, 3]),
            rs.randrange(1 << 32),
            None)
        if rs.random() < 0.3:
            cfg_pos_tf(c, rs)
        if rs.random() < 0.3:
            cfg_zero_tail(c, rs)
        c.run()
        new = [k for k in c.diag if k in need]
        if new:
            for k, v in c.diag.items():
                diag[k] = diag.get(k, 0) + v
            c.name = "qab%d" % seq
            cases.append(c)
            seq += 1
            need = [k for k in NEED if k not in diag]
        tries += 1
    if need:
        raise SystemExit(f"quant_all_bands coverage incomplete: {need} "
                         f"(tries={tries})")
    return cases, diag


def emit_case(c):
    rng, val, tell, tf = c.state
    out = ["", "///|",
           f"fn play_{c.name}(dec : RangeDecoder) -> Unit raise {{"]
    out.append("  // 载荷与期望值由 tools/gen_quant_all_bands_goldens.py 的")
    out.append("  // 独立参考端算出，重放整条主循环后逐项比对。")
    out.append(f"  let x : Array[Double] = Array::make({120 * c.m}, 0.0)")
    out.append(f"  let pulses : Array[Int] = {fmt_i(c.pulses)}")
    out.append(f"  let tf_res : Array[Int] = {fmt_i(c.tf_res)}")
    out.append(f"  let masks : Array[Int] = Array::make({NB_EBANDS}, 0)")
    out.append("  let seed2 = celt_quant_all_bands(")
    out.append(
        f"    dec, x, {c.start}, {c.end}, {c.lm}, "
        f"{'true' if c.short_blocks else 'false'}, pulses, tf_res, "
        f"{c.coded_bands}, {c.total_bits}, {c.balance}, {c.spread}, "
        f"{c.seed}L, masks,")
    out.append("  )")
    out.append(f"  let want_x : Array[Double] = {fmt_f(c.want_x)}")
    out.append(f"  let want_masks : Array[Int] = {fmt_i(c.want_masks)}")
    out.append("  expect_qab(")
    out.append(
        f"    x, want_x, masks, want_masks, seed2, {c.want_seed}L, "
        f'"{c.name}",')
    out.append("  )")
    out.append(
        f'  expect_dec_state(dec, "{c.name}", {rng}L, {val}L, {tell}, {tf})')
    out.append("}")
    out.append("")
    return "\n".join(out)


def emit_test(c):
    return "\n".join([
        "",
        "///|",
        f'test "金标：quant_all_bands · {c.label}" {{',
        f"  let dec = RangeDecoder::new(QAB_{c.name.upper()}_BITS)",
        f"  play_{c.name}(dec)",
        "}",
        "",
    ])


def main():
    cases, diag = build_cases()
    lines = ["\n".join([
        "// 由 tools/gen_quant_all_bands_goldens.py 生成，请勿手改。",
        "//",
        "// quant_all_bands 主循环（RFC 6716 §4.3.4）金标：载荷、分配与",
        "// TF 输入随机造出，期望频谱 / collapse mask / seed 由本脚本内的",
        "// 独立 Python 参考端算出（账目记账、折叠源推进与保守 cm 估计），",
        "// MoonBit 端重放同一载荷后频谱按相对容差、masks/seed/解码器状态",
        "// 精确比对。",
        "",
        "///|",
        "",
    ])]
    for c in cases:
        hexlit = 'b"' + "".join("\\x%02x" % b for b in c.data) + '"'
        lines.append("\n".join([
            "",
            "///|",
            f"const QAB_{c.name.upper()}_BITS : Bytes = {hexlit}",
            "",
        ]))
        lines.append(emit_case(c))
        lines.append(emit_test(c))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "quant_all_bands_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    keys = " ".join(f"{k}={v}" for k, v in sorted(diag.items()))
    print(f"[ok] {len(cases)} cases -> quant_all_bands_goldens_wbtest.mbt")
    print(f"[cov] {keys}")
    moon_fmt()


if __name__ == "__main__":
    main()
