# -*- coding: utf-8 -*-
"""生成 band boost 与 allocation trim（RFC 6716 §4.3.3）的 MoonBit 金标。

参考端在 tools/celt_alloc_flags_ref.py（独立实现），本文件负责用例构造、
MoonBit 调用行与 test 块的生成。

帧载荷长度同时决定预算与 trim 的门控，所以用不同长度的载荷覆盖「读到
trim」「trim 被门控住」两条路径，不人为改写 frame_bytes。

用法：python tools/gen_alloc_flags_goldens.py
输出：alloc_flags_goldens_wbtest.mbt
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_alloc_ref import NB_EBANDS, init_caps  # noqa: E402
from celt_alloc_flags_ref import decode_alloc_flags  # noqa: E402
from _fmt import moon_fmt  # noqa: E402


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def merge(dst, src):
    for k, v in src.items():
        dst[k] = dst.get(k, 0) + v


def fanout(data, start, end, lm):
    """跑一遍参考端，返回 dynalloc_logp 被降档的次数（≈有 boost 的带数）。"""
    dec = RangeDecoder(data)
    cap = init_caps(lm, 1)
    diag = {}
    decode_alloc_flags(dec, start, end, cap, len(data), lm, diag)
    return diag.get("f_logp_down", 0)


def greedy_fanout(start, end, lm, nbytes, rs, target=4, max_try=8000):
    """定向找「连击多次 boost」的载荷。

    首次 boost 只有 2**-6 的概率，纯随机要百万次量级。这里用保留更优变异
    的贪心：每次随机改动若干字节，只有当 boost 带数不降时才采纳，改动幅度
    逐次退火到 1 字节。变异幅度大时能跳出局部，缩到 1 字节时前段已解出的
    符号不受影响（范围解码器顺序消费字节），容易在已达成的基础上再推进。
    """
    best = rand_bytes(nbytes, rs.randrange(10 ** 6))
    best_fit = fanout(best, start, end, lm)
    for i in range(max_try):
        if best_fit >= target:
            return best, best_fit
        k = max(1, 8 - (i * 8) // max_try)
        buf = bytearray(best)
        for _ in range(k):
            buf[rs.randrange(nbytes)] = rs.randrange(256)
        cand = bytes(buf)
        fit = fanout(cand, start, end, lm)
        if fit >= best_fit:
            best, best_fit = cand, fit
    return best, best_fit


class Case:
    def __init__(self, name, label, data):
        self.name = name
        self.label = label
        self.data = data
        self.dec = RangeDecoder(data)
        self.diag = {}
        self.calls = []
        self.locals = []

    def flags(self, start, end, lm):
        cap = init_caps(lm, 1)
        self.locals = [("cap", cap)]
        self.result = decode_alloc_flags(
            self.dec, start, end, cap, len(self.data), lm, self.diag)
        self.calls.append(
            f"celt_decode_alloc_flags(dec, {start}, {end}, cap, "
            f"{len(self.data)}, {lm})")

    @property
    def state(self):
        d = self.dec
        return (d.rng, d.val, d.tell(), d.tell_frac())


def build_cases():
    cases = []
    diag = {}
    seq = 0

    def add(label, nbytes, seed, start, end, lm):
        nonlocal seq
        c = Case("f%d" % seq, label, rand_bytes(nbytes, seed))
        c.flags(start, end, lm)
        merge(diag, c.diag)
        cases.append(c)
        seq += 1
        return c

    # 基线：载荷长度决定预算（门控 trim 与否也由它决定）× 帧长索引
    for nbytes in (1, 2, 4, 16, 64, 256):
        for lm in (0, 3):
            add(f"基线 {nbytes}B lm={lm}", nbytes, 6000 + seq, 0, NB_EBANDS, lm)
    add("带窗 5..17", 64, 6900, 5, 17, 2)
    add("带窗 5..17 大帧", 256, 6901, 5, 17, 1)

    need = [
        "f_stop_zero", "f_budget_out", "f_cap_out", "f_boost", "f_multi",
        "f_any_boost", "f_logp_down", "f_logp_floor", "f_trim_read",
        "f_trim_gated", "f_trim_nondefault",
    ]
    seed = 7000
    missing = [k for k in need if k not in diag]
    while missing and seed < 200000:
        nbytes = [1, 2, 4, 8, 16, 64, 256, 512][seed % 8]
        lm = [0, 1, 2, 3][seed % 4]
        start, end = (5, 17) if seed % 6 == 0 else (0, NB_EBANDS)
        c = Case("g%d" % seed, f"覆盖搜索 {seed}", rand_bytes(nbytes, seed))
        c.flags(start, end, lm)
        new = [k for k in c.diag if k in need and k not in diag]
        if new:
            merge(diag, c.diag)
            cases.append(c)
        missing = [k for k in need if k not in diag]
        seed += 1
    # f_logp_floor 要连续四个带都有 boost（首次 boost 只有 2**-6 的概率，
    # 纯随机要百万次量级），改用保留更优变异的贪心去定向找。
    if "f_logp_floor" in missing:
        rs = random.Random(20261007)
        for start, end, lm, nbytes in [
            (0, NB_EBANDS, 3, 64), (0, NB_EBANDS, 0, 64),
            (5, 17, 2, 64), (0, NB_EBANDS, 3, 256),
        ]:
            data, fit = greedy_fanout(start, end, lm, nbytes, rs)
            if fit >= 4:
                c = Case("h%d" % len(cases),
                         f"贪心连击 boost {nbytes}B lm={lm}", data)
                c.flags(start, end, lm)
                merge(diag, c.diag)
                cases.append(c)
                break
        missing = [k for k in need if k not in diag]

    if missing:
        raise SystemExit(f"alloc-flags coverage incomplete: {missing}")
    return cases, diag

def fmt_arr(vals):
    return "[" + ", ".join(str(int(v)) for v in vals) + "]"


def emit_case(case):
    rng, val, tell, tf = case.state
    offsets, alloc_trim = case.result
    out = ["", "///|",
           f"fn play_{case.name}(dec : RangeDecoder) -> Unit raise " + "{"]
    out.append(f"  // 载荷见 ALLOC_FLAGS_{case.name.upper()}_BITS；期望值由")
    out.append("  // tools/gen_alloc_flags_goldens.py 的独立参考端算出。")
    for name, arr in case.locals:
        out.append(f"  let {name} : Array[Int] = {fmt_arr(arr)}")
    out.append("  let got = " + case.calls[0])
    out.append(
        f"  expect_alloc_flags(got, {fmt_arr(offsets)}, {alloc_trim}, "
        f'"{case.name}")')
    out.append(f'  expect_dec_state(dec, "{case.name}", {rng}L, {val}L, '
               f"{tell}, {tf})")
    out.append("}")
    out.append("")
    return "\n".join(out)


def emit_test(case):
    return "\n".join([
        "",
        "///|",
        f'test "金标：boost 与 trim · {case.label}" {{',
        f"  let dec = RangeDecoder::new(ALLOC_FLAGS_{case.name.upper()}_BITS)",
        f"  play_{case.name}(dec)",
        "}",
        "",
    ])


def main():
    cases, diag = build_cases()
    lines = [
        "\n".join([
            "// 由 tools/gen_alloc_flags_goldens.py 生成，请勿手改。",
            "//",
            "// band boost 与 allocation trim（RFC 6716 §4.3.3）金标：载荷与",
            "// 期望值由本脚本内的独立参考端算出，MoonBit 端重放同一参数后",
            "// 逐项比对每带加成与 trim 值。",
            "//",
            "// frame_bytes 恒取载荷长度：trim 的门控条件由它决定，改写它就",
            "// 等于改写被测条件。",
            "",
            "///|",
            "",
        ]),
    ]
    for case in cases:
        hexlit = 'b"' + "".join("\\x%02x" % b for b in case.data) + '"'
        lines.append("\n".join([
            "",
            "///|",
            f"const ALLOC_FLAGS_{case.name.upper()}_BITS : Bytes = {hexlit}",
            "",
        ]))
        lines.append(emit_case(case))
        lines.append(emit_test(case))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "alloc_flags_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    keys = " ".join(f"{k}={v}" for k, v in sorted(diag.items()))
    print(f"[ok] {len(cases)} cases -> alloc_flags_goldens_wbtest.mbt")
    print(f"[cov] {keys}")
    moon_fmt()


if __name__ == "__main__":
    main()
