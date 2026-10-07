# -*- coding: utf-8 -*-
"""生成比特分配（RFC 6716 §4.3.3）的 MoonBit 金标测试。

参考端在 tools/celt_alloc_ref.py（独立实现），本文件负责用例构造与
MoonBit 调用行的生成：每条调用行与参考端的调用在同一处成对生成，参数
不会漂移。

total 恒由 celt_alloc_total(载荷字节数, dec) 算出，与参考实现
「len*8<<BITRES - ec_tell_frac - 1」一致；不同预算靠不同载荷长度表达，
不人为改写 total。

用法：python tools/gen_alloc_goldens.py
输出：alloc_goldens_wbtest.mbt（载荷常量 + 重放函数）
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_alloc_ref import (  # noqa: E402
    NB_EBANDS,
    alloc_total,
    compute_allocation,
    init_caps,
)
from _fmt import moon_fmt  # noqa: E402


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def make_offsets(mode):
    """dynalloc 加成（单位 1/8 bit）。mode 决定哪些带被加成。"""
    out = [0] * NB_EBANDS
    if mode == "none":
        return out
    if mode == "head":
        out[0] = 64
        out[1] = 32
        return out
    if mode == "scattered":
        for i in (0, 3, 9, 14, 20):
            out[i] = 40
        return out
    if mode == "tail":
        for i in range(18, 21):
            out[i] = 80
        return out
    raise ValueError(mode)


def merge(dst, src):
    for k, v in src.items():
        dst[k] = dst.get(k, 0) + v


class Case:
    """一个金标用例：一边跑参考端，一边登记等价的 MoonBit 调用行。"""

    def __init__(self, name, label, data, offset_mode):
        self.name = name
        self.label = label
        self.data = data
        self.dec = RangeDecoder(data)
        self.diag = {}
        self.calls = []
        self.locals = []
        self.offsets = make_offsets(offset_mode)
        self._offset_mode = offset_mode

    def alloc(self, start, end, trim, lm, total_override=None):
        cap = init_caps(lm, 1)
        self.locals = [
            ("offsets", self.offsets),
            ("cap", cap),
        ]
        if total_override is None:
            total = alloc_total(len(self.data), self.dec)
            total_expr = f"celt_alloc_total({len(self.data)}, dec)"
        else:
            # 极端分支（如细能量封顶）需要超出真实载荷的预算才能命中，
            # 这类用例直接给定 total 并在注释里标明。
            total = total_override
            total_expr = str(total_override)
        r = compute_allocation(
            self.dec, start, end, self.offsets, cap, trim, total, lm,
            self.diag)
        self.result = r
        self.calls.append(
            f"celt_compute_allocation(dec, {start}, {end}, offsets, cap, "
            f"{trim}, {total_expr}, {lm})")

    @property
    def state(self):
        d = self.dec
        return (d.rng, d.val, d.tell(), d.tell_frac())


def build_cases():
    cases = []
    diag = {}

    def add(name, label, nbytes, seed, offset_mode, start, end, trim, lm,
            total=None):
        c = Case(name, label, rand_bytes(nbytes, seed), offset_mode)
        c.alloc(start, end, trim, lm, total)
        merge(diag, c.diag)
        cases.append(c)
        return c

    # 基线：不同帧长（决定预算）× 帧长索引 × trim
    seq = 0
    for nbytes in (8, 64, 192):
        for lm in (0, 3):
            # trim 合法范围 0..10（§4.3.3），取两端与中点
            for trim in (0, 5, 7, 10):
                add(f"b{seq}", f"基线 {nbytes}B lm={lm} trim={trim}",
                    nbytes, 1000 + seq, "none", 0, NB_EBANDS, trim, lm)
                seq += 1

    # dynalloc 加成：抬高 skip_start、制造超额（excess）
    for mode in ("head", "scattered", "tail"):
        for nbytes in (64, 192):
            add(f"d{seq}", f"dynalloc/{mode} {nbytes}B", nbytes, 2000 + seq,
                mode, 0, NB_EBANDS, 5, 3)
            seq += 1

    # 带窗（非全带）与极小预算
    add(f"w{seq}", "极小预算 2B", 2, 3001, "none", 0, NB_EBANDS, 5, 3); seq += 1
    add(f"w{seq}", "单字节载荷", 1, 3002, "none", 0, NB_EBANDS, 5, 3); seq += 1
    add(f"w{seq}", "带窗 5..17 lm=2", 192, 3003, "none", 5, 17, 3, 2); seq += 1
    add(f"w{seq}", "带窗 5..17 加成", 64, 3004, "scattered", 5, 17, 0, 1); seq += 1

    # 极端预算：真实载荷长度到不了的分支（超出 cap 改投细能量）
    add(f"x{seq}", "极端预算 300000", 64, 4001, "head", 0, NB_EBANDS, 7, 3,
        300000); seq += 1
    add(f"x{seq}", "极端预算 900000", 64, 4002, "scattered", 0, NB_EBANDS, 7,
        0, 900000); seq += 1
    add(f"x{seq}", "中等预算 50000", 64, 4003, "tail", 0, NB_EBANDS, 5, 3,
        50000); seq += 1

    # 覆盖搜索：补齐难命中的分支（如读到 skip 标志、细能量封顶）
    need = [
        "a_keep", "a_skip_flag", "a_forced", "a_natural_end", "a_hi_over",
        "a_lo_zero", "a_skip_rsv", "a_skip_start_moved", "a_n_gt1",
        "a_n_eq1", "a_excess", "a_fine_bust", "a_fine_low",
        "a_tail", "a_trim_neg",
    ]
    seed = 5000
    missing = [k for k in need if k not in diag]
    while missing and seed < 120000:
        nbytes = [1, 2, 8, 64, 192][seed % 5]
        lm = [0, 1, 2, 3][seed % 4]
        trim = [0, 2, 5, 7][seed % 4]
        mode = ["none", "head", "scattered", "tail"][seed % 4]
        start, end = (5, 17) if seed % 7 == 0 else (0, NB_EBANDS)
        total = [None, 300000, 600000][seed % 3]
        c = Case("s%d" % seed, f"覆盖搜索 {seed}", rand_bytes(nbytes, seed),
                 mode)
        c.alloc(start, end, trim, lm, total)
        new = [k for k in c.diag if k in need and k not in diag]
        if new:
            merge(diag, c.diag)
            cases.append(c)
        missing = [k for k in need if k not in diag]
        seed += 1
    if missing:
        raise SystemExit(f"allocation coverage incomplete: {missing}")
    return cases, diag


def fmt_arr(vals):
    return "[" + ", ".join(str(int(v)) for v in vals) + "]"


def emit_case(case):
    rng, val, tell, tf = case.state
    r = case.result
    out = ["", "///|",
           f"fn play_{case.name}(dec : RangeDecoder) -> Unit raise " + "{"]
    out.append(f"  // 载荷见 ALLOC_{case.name.upper()}_BITS；期望值由")
    out.append("  // tools/gen_alloc_goldens.py 的独立参考端算出。")
    for name, arr in case.locals:
        out.append(f"  let {name} : Array[Int] = {fmt_arr(arr)}")
    out.append("  let got = " + case.calls[0])
    out.append(
        f"  expect_alloc(got, {fmt_arr(r['pulses'])}, {fmt_arr(r['ebits'])}, "
        f"{fmt_arr(r['fine_priority'])}, {r['coded_bands']}, {r['balance']}, "
        f'"{case.name}")')
    out.append(f'  expect_dec_state(dec, "{case.name}", {rng}L, {val}L, '
               f"{tell}, {tf})")
    out.append("}")
    out.append("")
    return "\n".join(out)


def emit_test(case):
    """每个用例配一个 test 块——用例多，交给生成器以免名字写岔。"""
    return "\n".join([
        "",
        "///|",
        f'test "金标：比特分配 · {case.label}" {{',
        f"  let dec = RangeDecoder::new(ALLOC_{case.name.upper()}_BITS)",
        f"  play_{case.name}(dec)",
        "}",
        "",
    ])


def main():
    cases, diag = build_cases()
    lines = [
        "\n".join([
            "// 由 tools/gen_alloc_goldens.py 生成，请勿手改。",
            "//",
            "// 比特分配（RFC 6716 §4.3.3）金标：载荷与期望值由本脚本内的独立",
            "// 参考端算出（不同语言、不同实现路径），MoonBit 的 celt_alloc.mbt",
            "// 重放同一参数后逐项比对 PVQ 位数、细能量位、收尾优先级、",
            "// codedBands 与 balance。",
            "//",
            "// total 多数由 celt_alloc_total(载荷字节数, dec) 算出，与参考实现",
            "// 「len*8<<BITRES - ec_tell_frac - 1」一致；少数为命中极端分支",
            "// 直接给定，并在用例注释中说明。",
            "",
            "///|",
            "",
        ]),
    ]
    for case in cases:
        lines.append("\n".join([
            "",
            "///|",
            f"const ALLOC_{case.name.upper()}_BITS : Bytes = "
            f"{bytes_hex(case.data)}",
            "",
        ]))
        lines.append(emit_case(case))
        lines.append(emit_test(case))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "alloc_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    keys = " ".join(f"{k}={v}" for k, v in sorted(diag.items()))
    print(f"[ok] {len(cases)} cases -> alloc_goldens_wbtest.mbt")
    print(f"[cov] {keys}")
    moon_fmt()


def bytes_hex(data):
    return 'b"' + "".join("\\x%02x" % b for b in data) + '"'


if __name__ == "__main__":
    main()
