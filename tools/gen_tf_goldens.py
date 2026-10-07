# -*- coding: utf-8 -*-
"""生成 TF 调整与频谱扩展决策（RFC 6716 §4.3.1 / Table 56）的 MoonBit 金标。

参考端在 tools/celt_tf_ref.py（独立实现），本文件负责用例构造、MoonBit 调用
行与 test 块的生成。

tf 与 spread 在符号流里紧邻，金标里也连着调，让范围解码器状态连续推进。
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_tf_ref import decode_spread, decode_tf  # noqa: E402
from _fmt import moon_fmt  # noqa: E402

NB_EBANDS = 21


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def merge(dst, src):
    for k, v in src.items():
        dst[k] = dst.get(k, 0) + v


class Case:
    def __init__(self, name, label, data, start, end, is_transient, lm,
                 frame_bytes):
        self.name = name
        self.label = label
        self.data = data
        self.dec = RangeDecoder(data)
        self.diag = {}
        tf = decode_tf(self.dec, start, end, is_transient, lm, frame_bytes,
                       self.diag)
        spread = decode_spread(self.dec, frame_bytes, self.diag)
        self.tf = tf
        self.spread = spread
        tr = "true" if is_transient else "false"
        self.calls = [
            f"celt_decode_tf(dec, {start}, {end}, {tr}, {lm}, {frame_bytes})",
            f"celt_decode_spread(dec, {frame_bytes})",
        ]

    @property
    def state(self):
        d = self.dec
        return (d.rng, d.val, d.tell(), d.tell_frac())


def build_cases():
    cases = []
    diag = {}
    seq = 0

    def add(label, nbytes, seed, start, end, is_transient, lm, frame_bytes):
        nonlocal seq
        c = Case("tf%d" % seq, label, rand_bytes(nbytes, seed), start, end,
                 is_transient, lm, frame_bytes)
        merge(diag, c.diag)
        cases.append(c)
        seq += 1
        return c

    # 基线：transient × 帧长 × 帧载荷长度（后两者决定 tf_select 的预留与
    # 逐带读取、spread 的门控）
    for frame_bytes in (4, 8, 64):
        for lm in (0, 1, 3):
            for is_transient in (False, True):
                add(f"基线 {frame_bytes}B lm={lm} "
                    f"{'短' if is_transient else '长'}块",
                    64, 11000 + seq, 0, NB_EBANDS, is_transient, lm,
                    frame_bytes)
    add("带窗 5..17", 64, 11900, 5, 17, False, 3, 64)
    add("带窗 5..17 短块", 64, 11901, 5, 17, True, 2, 16)
    add("极小帧 2B", 64, 11902, 0, NB_EBANDS, False, 3, 2)
    add("极小帧 2B 短块", 64, 11903, 0, NB_EBANDS, True, 3, 3)

    need = [
        "t_band_read", "t_band_hold", "t_select_read", "t_select_same_col",
        "t_select_rsv_off", "t_changed", "s_read", "s_nonnormal", "s_default",
    ]
    seed = 12000
    missing = [k for k in need if k not in diag]
    while missing and seed < 60000:
        frame_bytes = [2, 3, 4, 8, 16, 64, 128][seed % 7]
        lm = [0, 1, 2, 3][seed % 4]
        is_transient = bool(seed % 2)
        start, end = (5, 17) if seed % 6 == 0 else (0, NB_EBANDS)
        c = Case("tu%d" % seed, f"覆盖搜索 {seed}", rand_bytes(64, seed), start,
                 end, is_transient, lm, frame_bytes)
        new = [k for k in c.diag if k in need and k not in diag]
        if new:
            merge(diag, c.diag)
            cases.append(c)
        missing = [k for k in need if k not in diag]
        seed += 1
    if missing:
        raise SystemExit(f"tf/spread coverage incomplete: {missing}")
    return cases, diag


def fmt_bytes(data):
    return 'b"' + "".join("\\x%02x" % b for b in data) + '"'


def fmt_arr(vals):
    return "[" + ", ".join(str(int(v)) for v in vals) + "]"


def emit_case(case):
    rng, val, tell, tf_frac = case.state
    out = ["", "///|",
           f"fn play_{case.name}(dec : RangeDecoder) -> Unit raise " + "{"]
    out.append(f"  // 载荷见 TF_{case.name.upper()}_BITS；期望值由")
    out.append("  // tools/gen_tf_goldens.py 的独立参考端算出。")
    out.append("  let got_tf = " + case.calls[0])
    out.append("  let got_spread = " + case.calls[1])
    out.append(
        f"  expect_tf(got_tf, got_spread, {fmt_arr(case.tf)}, "
        f'{case.spread}, "{case.name}")')
    out.append(f'  expect_dec_state(dec, "{case.name}", {rng}L, {val}L, '
               f"{tell}, {tf_frac})")
    out.append("}")
    out.append("")
    return "\n".join(out)


def emit_test(case):
    return "\n".join([
        "",
        "///|",
        f'test "金标：TF 与 spread · {case.label}" {{',
        f"  let dec = RangeDecoder::new(TF_{case.name.upper()}_BITS)",
        f"  play_{case.name}(dec)",
        "}",
        "",
    ])


def main():
    cases, diag = build_cases()
    lines = [
        "\n".join([
            "// 由 tools/gen_tf_goldens.py 生成，请勿手改。",
            "//",
            "// TF 调整（§4.3.1）与频谱扩展决策（Table 56）金标：载荷与期望值",
            "// 由本脚本内的独立参考端算出，MoonBit 端重放同一参数后逐项比对。",
            "//",
            "// tf 与 spread 在符号流里紧邻，故在一个用例里连着调，让解码器",
            "// 状态连续推进。",
            "",
            "///|",
            "",
        ]),
    ]
    for case in cases:
        lines.append("\n".join([
            "",
            "///|",
            f"const TF_{case.name.upper()}_BITS : Bytes = "
            f"{fmt_bytes(case.data)}",
            "",
        ]))
        lines.append(emit_case(case))
        lines.append(emit_test(case))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "tf_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    keys = " ".join(f"{k}={v}" for k, v in sorted(diag.items()))
    print(f"[ok] {len(cases)} cases -> tf_goldens_wbtest.mbt")
    print(f"[cov] {keys}")
    moon_fmt()


if __name__ == "__main__":
    main()
