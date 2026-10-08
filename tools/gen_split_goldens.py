# -*- coding: utf-8 -*-
"""生成 split 解码（RFC 6716 §4.3.4.4）的 MoonBit 金标。

参考端在 tools/celt_split_ref.py（独立实现），本文件负责：
  - 交叉断言：exp2 表（浮点 floor vs celt_bands.c 解析值）、logN
    （eband5ms 差分推算 vs dump_modes 的 logN400）；
  - 用例构造与覆盖搜索：θ 单元用例（三种 PDF、inv、两相偏移）与整树
    重放（分割/位数划分/rebalance/预算循环），期望值全部由参考端算出；
  - MoonBit 调用行、载荷常量与 test 块的生成。

用法：python tools/gen_split_goldens.py
输出：split_goldens_wbtest.mbt
"""
import os
import random
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_split_ref import (  # noqa: E402
    compute_theta,
    decode_quant_partition,
    exp2_table8,
    load_logn,
)
from gen_celt_tables import extract_array, read_src  # noqa: E402
from celt_alloc_ref import T  # noqa: E402
from _fmt import moon_fmt  # noqa: E402

THETA_NEED = [
    "t_pdf_step", "t_pdf_uniform", "t_pdf_tri", "t_qn1", "t_qn_gt1",
    "t_inv_read", "t_inv_skip", "t_intensity_qn1", "t_twophase",
    "t_disable_inv",
]
PART_NEED = [
    "p_split", "p_leaf", "p_mid_first", "p_side_first", "p_rebal_m",
    "p_rebal_s", "p_rebal_edge", "p_budget_loop", "p_q0", "p_qpos",
    "p_lm_m1", "p_n1", "p_delta_pos", "p_delta_neg",
]


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def cross_checks():
    """exp2 表与 logN 各自的第二来源对拍，任一侧读错在此暴露。"""
    # exp2_table8：参考端浮点 floor vs celt_bands.c 的字面量解析
    text = read_src("celt_bands.c")
    m = re.search(r"exp2_table8\[8\]\s*=\s*\{?([^}]*)\}", text)
    if not m:
        raise SystemExit("exp2_table8 not found in celt_bands.c")
    c_vals = [int(x) for x in re.findall(r"\d+", m.group(1))]
    if c_vals != exp2_table8():
        raise SystemExit(f"exp2 表不符: C={c_vals} 浮点={exp2_table8()}")
    # logN：eband5ms 差分推算 vs dump_modes 的 logN400（celt_tables
    # 的生成器已把 logN400 锚到 RFC Table 55，这里是第三重落点）
    smf = read_src("celt_static_modes_float.h")
    logn400 = extract_array(smf, "logN400")
    if load_logn() != logn400:
        diff = [
            (i, a, b) for i, (a, b) in enumerate(zip(load_logn(), logn400))
            if a != b
        ]
        raise SystemExit(f"logN 不符，前 5: {diff[:5]}")


class ThetaCase:
    """θ 解码单元用例。params 与 celt_compute_theta 的形参一致。"""

    def __init__(self, name, label, data, params):
        self.name = name
        self.label = label
        self.data = data
        self.params = params  # (band, lm, n, b, blocks, blocks0,
        #                          stereo, intensity, remaining,
        #                          disable_inv, fill)
        self.dec = RangeDecoder(data)
        self.diag = {}
        self.want = None
        self.state = None

    def run(self):
        before = self.dec.tell_frac()
        sctx, b_after, fill_after = compute_theta(
            self.dec, *self.params, self.diag)
        self.want = (
            [sctx[k] for k in
             ("inv", "imid", "iside", "delta", "itheta", "qalloc", "qn")]
            + [b_after, fill_after])
        self.tell_before = before
        self.state = (self.dec.rng, self.dec.val, self.dec.tell(),
                      self.dec.tell_frac())


class PartCase:
    """整树重放用例。params 与 celt_decode_quant_partition 一致。"""

    def __init__(self, name, label, data, params):
        self.name = name
        self.label = label
        self.data = data
        self.params = params  # (band, lm, n, b, blocks, fill, remaining)
        self.dec = RangeDecoder(data)
        self.diag = {}
        self.flat_splits = None
        self.flat_leaves = None
        self.remaining_end = None
        self.state = None

    def run(self):
        splits, leaves, rem = decode_quant_partition(
            self.dec, *self.params, self.diag)
        self.flat_splits = [
            v for s in splits for v in
            (s["qn"], s["itheta"], s["imid"], s["iside"], s["delta"],
             s["inv"], s["qalloc"])]
        self.flat_leaves = []
        for l in leaves:
            self.flat_leaves += [
                l["n"], l["blocks"], l["lm"], l["b"], l["q"], l["used"],
                l["fill"], len(l["pulses"])]
            self.flat_leaves += l["pulses"]
        self.remaining_end = rem
        self.state = (self.dec.rng, self.dec.val, self.dec.tell(),
                      self.dec.tell_frac())


def merge(dst, src):
    for k, v in src.items():
        dst[k] = dst.get(k, 0) + v


def build_theta_cases():
    """θ 单元：结构性键由参数组合直接保证，随机搜索兜底。"""
    cases = []
    diag = {}
    seq = 0

    def add(label, nbytes, seed, params):
        nonlocal seq
        c = ThetaCase("th%d" % seq, label, rand_bytes(nbytes, seed), params)
        c.run()
        merge(diag, c.diag)
        cases.append(c)
        seq += 1

    # 三种 PDF（mono B0=1 三角 / B0>1 均匀 / 立体声 N>2 阶梯）
    add("三角 PDF 长块单声道", 64, 8100, (15, 0, 6, 120, 1, 1, False, 21, 4000, False, 15))
    add("均匀 PDF B0>1", 64, 8101, (15, 0, 6, 120, 2, 2, False, 21, 4000, False, 15))
    add("阶梯 PDF 立体声 N>2", 64, 8102, (15, 0, 6, 120, 1, 1, True, 21, 4000, False, 15))
    # 两相偏移（stereo N==2 → uniform）
    add("两相偏移 立体声 N==2", 64, 8103, (15, 0, 2, 120, 1, 1, True, 21, 4000, False, 15))
    # qn==1 族：单声道 / 立体声 inv 读与跳过 / intensity 强制 / disable_inv
    add("qn=1 单声道", 16, 8104, (15, 0, 6, 10, 1, 1, False, 21, 4000, False, 15))
    add("qn=1 立体声 inv 读取", 16, 8105, (15, 0, 6, 20, 1, 1, True, 21, 400, False, 15))
    add("qn=1 立体声 inv 预算不足", 16, 8106, (15, 0, 6, 10, 1, 1, True, 21, 400, False, 15))
    add("intensity 强制 qn=1", 64, 8107, (15, 0, 6, 300, 1, 1, True, 15, 4000, False, 15))
    add("disable_inv 覆盖 inv", 16, 8108, (15, 0, 6, 20, 1, 1, True, 21, 400, True, 15))
    # 其他参数面：lm=3 的 pulse_cap、qn 上限 256、N==1 的 delta=0
    add("lm=3 三角", 128, 8109, (15, 3, 48, 400, 1, 1, False, 21, 8000, False, 15))
    add("大 b 触 qn 上限", 128, 8110, (15, 0, 6, 100000, 1, 1, False, 21, 80000, False, 15))
    add("N==1 带", 16, 8111, (0, 0, 1, 8, 1, 1, False, 21, 400, False, 1))
    # qb 落在 [1,3]：阈值边界本身（qb<4 与 qb<1 的分野）
    add("qb∈[1,3] 的 qn=1 边界", 16, 8112, (15, 0, 6, 54, 1, 1, False, 21, 4000, False, 15))

    need = [k for k in THETA_NEED if k not in diag]
    if need:
        raise SystemExit(f"theta coverage incomplete: {need}")
    return cases, diag


def build_part_cases():
    """整树：结构性键用定向参数，状态性键靠随机搜索兜底。"""
    cases = []
    diag = {}
    seq = 0

    def add(label, nbytes, seed, params):
        nonlocal seq
        c = PartCase("pt%d" % seq, label, rand_bytes(nbytes, seed), params)
        c.run()
        merge(diag, c.diag)
        cases.append(c)
        seq += 1
        return c

    add("无分割 落叶", 64, 8200, (15, 0, 6, 40, 1, 15, 4000))
    add("零脉冲叶", 16, 8201, (15, 0, 6, 8, 1, 15, 4000))
    add("深分割到 lm=-1 与 N=1 叶", 256, 8202, (15, 3, 12, 400, 1, 15, 8000))
    add("预算循环逼退脉冲", 64, 8203, (15, 0, 6, 40, 1, 15, 10))
    add("B0=2 的 delta 微调", 128, 8204, (15, 1, 12, 300, 2, 15, 8000))
    add("紧预算下的深树", 256, 8205, (15, 3, 48, 400, 1, 15, 60))
    add("升频 B=4", 128, 8206, (8, 1, 16, 260, 4, 15, 8000))
    add("fill=0 的低带", 64, 8207, (0, 0, 1, 30, 1, 0, 4000))
    # n=3 的节点也继续分割（→ N=1 叶）：N>2 判据的边界样本。
    # b 要足够大，让对半分后的子树仍超过分割门槛。
    add("n=3 处继续分割到 N=1", 128, 8208, (15, 1, 6, 1200, 1, 15, 8000))

    # 随机搜索补状态性键（mid/side 次序、rebalance、delta 微调方向）
    need = [k for k in PART_NEED if k not in diag]
    rs = random.Random(20261008)
    tries = 0
    while need and tries < 60000:
        tries += 1
        band = rs.choice([0, 4, 8, 12, 15, 17, 19, 20])
        lm = rs.choice([0, 1, 2, 3])
        eb = T["eband5ms"]
        n = (eb[band + 1] - eb[band]) << lm
        b = rs.choice([20, 40, 60, 120, 260, 400, 700, 1200])
        blocks = rs.choice([1, 2, 4])
        fill = rs.choice([0, 15])
        remaining = rs.choice([4, 10, 60, 300, 8000, 64000])
        nbytes = rs.choice([4, 8, 16, 64, 256])
        c = PartCase("ptx%d" % tries, f"覆盖搜索 {tries}",
                     rand_bytes(nbytes, 8300 + tries),
                     (band, lm, n, b, blocks, fill, remaining))
        c.run()
        new = [k for k in c.diag if k in need]
        if new:
            merge(diag, c.diag)
            c.name = "pt%d" % seq
            cases.append(c)
            seq += 1
            need = [k for k in PART_NEED if k not in diag]
    if need:
        raise SystemExit(f"partition coverage incomplete: {need} "
                         f"(tries={tries})")
    return cases, diag


def fmt_arr(vals):
    return "[" + ", ".join(str(int(v)) for v in vals) + "]"


def bool_str(v):
    return "true" if v else "false"


def emit_theta_case(case):
    rng, val, tell, tf = case.state
    band, lm, n, b, blocks, blocks0, stereo, intensity, remaining, dis, fill = (
        case.params)
    out = ["", "///|",
           f"fn play_split_{case.name}(dec : RangeDecoder) -> Unit raise {{"]
    out.append(f"  // 载荷见 SPLIT_{case.name.upper()}_BITS；期望值由")
    out.append("  // tools/gen_split_goldens.py 的独立参考端算出。")
    out.append(f"  let before = dec.tell_frac()")
    out.append(f"  let (sctx, b_after, fill_after) = celt_compute_theta(")
    out.append(
        f"    dec, {band}, {lm}, {n}, {b}, {blocks}, {blocks0}, "
        f"{bool_str(stereo)}, {intensity}, {remaining}, {bool_str(dis)}, "
        f"{fill},")
    out.append("  )")
    out.append(f"  expect_theta(")
    out.append(f"    dec, sctx, b_after, fill_after, {fmt_arr(case.want)},")
    out.append(f'    before, "{case.name}",')
    out.append("  )")
    out.append(
        f'  expect_dec_state(dec, "{case.name}", {rng}L, {val}L, '
        f"{tell}, {tf})")
    out.append("}")
    out.append("")
    return "\n".join(out)


def emit_part_case(case):
    rng, val, tell, tf = case.state
    band, lm, n, b, blocks, fill, remaining = case.params
    out = ["", "///|",
           f"fn play_split_{case.name}(dec : RangeDecoder) -> Unit raise {{"]
    out.append(f"  // 载荷见 SPLIT_{case.name.upper()}_BITS；期望值由")
    out.append("  // tools/gen_split_goldens.py 的独立参考端算出。")
    out.append(
        f"  let got = celt_decode_quant_partition(dec, {band}, {lm}, {n}, "
        f"{b}, {blocks}, {fill}, {remaining})")
    out.append("  expect_partition(")
    out.append(f"    got, {band}, {remaining},")
    out.append(f"    {fmt_arr(case.flat_splits)},")
    # 叶扁平数组可能很长，交给 moon fmt 折行
    out.append(f"    {fmt_arr(case.flat_leaves)},")
    out.append(f'    {case.remaining_end}, "{case.name}",')
    out.append("  )")
    out.append(
        f'  expect_dec_state(dec, "{case.name}", {rng}L, {val}L, '
        f"{tell}, {tf})")
    out.append("}")
    out.append("")
    return "\n".join(out)


def emit_test(case, kind):
    return "\n".join([
        "",
        "///|",
        f'test "金标：{kind} · {case.label}" {{',
        f"  let dec = RangeDecoder::new(SPLIT_{case.name.upper()}_BITS)",
        f"  play_split_{case.name}(dec)",
        "}",
        "",
    ])


def main():
    cross_checks()
    theta_cases, theta_diag = build_theta_cases()
    part_cases, part_diag = build_part_cases()
    lines = ["\n".join([
        "// 由 tools/gen_split_goldens.py 生成，请勿手改。",
        "//",
        "// split 解码（RFC 6716 §4.3.4.4）金标：载荷与期望值由本脚本内的",
        "// 独立 Python 参考端算出（θ 的三种 PDF、递归分割、位数划分与叶上",
        "// 预算循环），MoonBit 端重放同一载荷后逐项比对控制量、脉冲向量",
        "// 与范围解码器状态。",
        "",
        "///|",
        "",
    ])]
    for case in theta_cases + part_cases:
        hexlit = 'b"' + "".join("\\x%02x" % b for b in case.data) + '"'
        lines.append("\n".join([
            "",
            "///|",
            f"const SPLIT_{case.name.upper()}_BITS : Bytes = {hexlit}",
            "",
        ]))
        if isinstance(case, ThetaCase):
            lines.append(emit_theta_case(case))
            lines.append(emit_test(case, "theta"))
        else:
            lines.append(emit_part_case(case))
            lines.append(emit_test(case, "split"))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "split_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    keys = " ".join(f"{k}={v}" for k, v in sorted(
        {**theta_diag, **part_diag}.items()))
    print(f"[ok] {len(theta_cases)} theta + {len(part_cases)} split cases "
          f"-> split_goldens_wbtest.mbt")
    print(f"[cov] {keys}")
    moon_fmt()


if __name__ == "__main__":
    main()
