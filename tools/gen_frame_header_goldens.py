# -*- coding: utf-8 -*-
"""生成帧首四符号（RFC 6716 Table 56 前四项）的 MoonBit 金标。

参考端在 tools/celt_frame_header_ref.py（独立实现），本文件负责用例构造、
MoonBit 调用行与 test 块的生成。

frame_bytes 独立于载荷长度给定：门控条件完全由它决定，用它去触发「预算不
足」与「空帧」两类分支，载荷本身则提供比特。
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_frame_header_ref import decode_frame_header  # noqa: E402
from _fmt import moon_fmt  # noqa: E402


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def merge(dst, src):
    for k, v in src.items():
        dst[k] = dst.get(k, 0) + v


class Case:
    def __init__(self, name, label, data, frame_bytes, start, lm):
        self.name = name
        self.label = label
        self.data = data
        self.frame_bytes = frame_bytes
        self.dec = RangeDecoder(data)
        self.diag = {}
        self.result = decode_frame_header(
            self.dec, frame_bytes, start, lm, self.diag)
        self.call = (f"celt_decode_frame_header(dec, {frame_bytes}, "
                     f"{start}, {lm})")

    @property
    def state(self):
        d = self.dec
        return (d.rng, d.val, d.tell(), d.tell_frac())


def build_cases():
    cases = []
    diag = {}
    seq = 0

    def add(label, nbytes, seed, frame_bytes, start, lm):
        nonlocal seq
        c = Case("fh%d" % seq, label, rand_bytes(nbytes, seed), frame_bytes,
                 start, lm)
        merge(diag, c.diag)
        cases.append(c)
        seq += 1
        return c

    # 基线：帧长决定门控，lm 决定有没有瞬态标志，start 决定有没有后滤波
    for frame_bytes in (2, 4, 8, 32, 128):
        for lm in (0, 3):
            add(f"基线 {frame_bytes}B lm={lm}", 64, 8000 + seq, frame_bytes,
                0, lm)
    add("start=5（无后滤波）", 64, 8100, 64, 5, 3)
    add("start=5 小帧", 64, 8101, 4, 5, 1)
    add("空帧 frame_bytes=0", 64, 8102, 0, 0, 3)
    add("极小帧 2B", 64, 8103, 2, 0, 0)

    need = [
        "h_silence_noword", "h_silence_bit", "h_silence_off",
        "h_pf_gated", "h_pf_on", "h_pf_off", "h_tapset",
        "h_transient_read", "h_transient_skip", "h_intra_read", "h_intra_skip",
    ]
    # h_tapset_gated 不在此列：前置门控 tell+16<=total_bits 在非静音时给出
    # tell=1，故 total_bits>=17、frame_bytes>=3、total_bits>=24；而 tapset 被
    # 门控住要 tell_after+2>total_bits>=22，实测 18000 个样本里 tell_after
    # 最大只有 21（postfilter 只读 4 个符号）。两条不等式相抵，该分支不可达。
    # 静音帧更不行——它连 postfilter 都不进。判据本身只是一个 +2<= 比较。
    seed = 9000
    missing = [k for k in need if k not in diag]
    while missing and seed < 40000:
        frame_bytes = [2, 3, 4, 6, 8, 16, 32, 128][seed % 8]
        lm = [0, 1, 2, 3][seed % 4]
        start = 5 if seed % 5 == 0 else 0
        c = Case("fs%d" % seed, f"覆盖搜索 {seed}", rand_bytes(64, seed),
                 frame_bytes, start, lm)
        new = [k for k in c.diag if k in need and k not in diag]
        if new:
            merge(diag, c.diag)
            cases.append(c)
        missing = [k for k in need if k not in diag]
        seed += 1

    # 静音标志的低概率分支（PDF 为 {32767,1}/32768）：随机字节命中率
    # 2**-15，定向搜到为止。
    if "h_silence_bit" in missing:
        rs = random.Random(20261007)
        for _ in range(300000):
            data = rand_bytes(64, rs.randrange(10 ** 9))
            dec = RangeDecoder(data)
            d = {}
            r = decode_frame_header(dec, 64, 0, 3, d)
            if r["silence"] and "h_silence_bit" in d:
                c = Case("fz0", "定向搜到的静音帧", data, 64, 0, 3)
                merge(diag, c.diag)
                cases.append(c)
                break
        missing = [k for k in need if k not in diag]

    if missing:
        raise SystemExit(f"frame-header coverage incomplete: {missing}")
    return cases, diag


def fmt_bytes(data):
    return 'b"' + "".join("\\x%02x" % b for b in data) + '"'


def emit_case(case):
    rng, val, tell, tf = case.state
    r = case.result
    out = ["", "///|",
           f"fn play_{case.name}(dec : RangeDecoder) -> Unit raise " + "{"]
    out.append(f"  // 载荷见 FRAME_HEADER_{case.name.upper()}_BITS；期望值由")
    out.append("  // tools/gen_frame_header_goldens.py 的独立参考端算出。")
    out.append("  let got = " + case.call)
    out.append(
        f"  expect_frame_header(got, {_b(r['silence'])}, "
        f"{_b(r['postfilter_on'])}, {r['postfilter_pitch']}, "
        f"{r['postfilter_gain']!r}, {r['postfilter_tapset']}, "
        f"{_b(r['is_transient'])}, {_b(r['intra'])}, \"{case.name}\")")
    out.append(f'  expect_dec_state(dec, "{case.name}", {rng}L, {val}L, '
               f"{tell}, {tf})")
    out.append("}")
    out.append("")
    return "\n".join(out)


def _b(v):
    return "true" if v else "false"


def emit_test(case):
    return "\n".join([
        "",
        "///|",
        f'test "金标：帧首符号 · {case.label}" {{',
        f"  let dec = RangeDecoder::new(FRAME_HEADER_{case.name.upper()}_BITS)",
        f"  play_{case.name}(dec)",
        "}",
        "",
    ])


def main():
    cases, diag = build_cases()
    lines = [
        "\n".join([
            "// 由 tools/gen_frame_header_goldens.py 生成，请勿手改。",
            "//",
            "// 帧首四符号（RFC 6716 Table 56 前四项）金标：载荷与期望值由本",
            "// 脚本内的独立参考端算出，MoonBit 端重放同一参数后逐项比对。",
            "//",
            "// frame_bytes 独立于载荷长度给定——门控条件只看它，用它触发",
            "// 「预算不足」与「空帧」两类分支。",
            "",
            "///|",
            "",
        ]),
    ]
    for case in cases:
        lines.append("\n".join([
            "",
            "///|",
            f"const FRAME_HEADER_{case.name.upper()}_BITS : Bytes = "
            f"{fmt_bytes(case.data)}",
            "",
        ]))
        lines.append(emit_case(case))
        lines.append(emit_test(case))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "frame_header_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    keys = " ".join(f"{k}={v}" for k, v in sorted(diag.items()))
    print(f"[ok] {len(cases)} cases -> frame_header_goldens_wbtest.mbt")
    print(f"[cov] {keys}")
    moon_fmt()


if __name__ == "__main__":
    main()
