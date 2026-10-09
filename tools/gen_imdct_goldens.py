# -*- coding: utf-8 -*-
"""生成 IMDCT 与帧合成（RFC 6716 §4.3.7）的 MoonBit 金标。

参考端在 tools/celt_imdct_ref.py（RFC 余弦和直接定义 + 显式跨帧镜像，
与 MoonBit 端的 FFT 路径不共享代码），本文件负责：
  - 各 LM、瞬态、跨帧 pending 贯穿的帧序列与谱形构造（高斯随机 /
    稀疏 / 近 DC / 零谱 / 大动态）；
  - 每帧期望输出与帧末 pending 字面量的生成；
  - 覆盖自检：任一构造分支缺失即报错退出。

用法：python tools/gen_imdct_goldens.py
输出：imdct_goldens_wbtest.mbt
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import celt_imdct_ref as ref  # noqa: E402
from _fmt import moon_fmt, moon_num  # noqa: E402


def fmt_f(vals):
    return "[" + ", ".join(moon_num(v) for v in vals) + "]"


def gauss_spec(n, seed, scale=0.5):
    rs = random.Random(seed)
    return [rs.gauss(0.0, scale) for _ in range(n)]


def sparse_spec(n, seed):
    rs = random.Random(seed)
    x = [0.0] * n
    for _ in range(6):
        x[rs.randrange(n)] = rs.choice([-3.0, -1.5, 1.5, 3.0])
    return x


def dc_spec(n):
    return [0.125] * n


def zero_spec(n):
    return [0.0] * n


class Case:
    """一个用例 = 同一 pending 链上的一串帧。"""

    def __init__(self, name, label, lm, transient, specs):
        self.name = name
        self.label = label
        self.lm = lm
        self.transient = transient
        self.specs = specs
        self.results = []
        pend = [0.0] * (ref.OVERLAP // 2)
        for sp in specs:
            out, pend = ref.synth_frame(sp, lm, transient, pend)
            self.results.append((sp, out, pend))
        self.final_pend = pend


def build_cases():
    cases = []
    cov = {}

    def add(name, label, lm, transient, specs):
        c = Case(name, label, lm, transient, specs)
        cases.append(c)
        cov[f"lm{lm}t" if transient else f"lm{lm}"] = 1
        for sp in specs:
            if all(v == 0.0 for v in sp):
                cov["zero"] = 1
            elif all(v == sp[0] for v in sp):
                cov["dc"] = 1
            elif sum(1 for v in sp if v != 0.0) <= 8:
                cov["sparse"] = 1
            elif max(abs(v) for v in sp) > 100.0:
                cov["big"] = 1
            else:
                cov["gauss"] = 1
        if len(specs) >= 3:
            cov["multi3"] = 1

    n0 = 120 << 0
    n1 = 120 << 1
    n2 = 120 << 2
    n3 = 120 << 3

    add("lm0", "2.5ms 单帧", 0, False, [gauss_spec(n0, 3101)])
    add("lm1", "5ms 两帧", 1, False,
        [gauss_spec(n1, 3111), sparse_spec(n1, 3112)])
    add("lm2", "10ms 三帧（含零谱贯穿）", 2, False,
        [gauss_spec(n2, 3121), dc_spec(n2), zero_spec(n2)])
    add("lm3", "20ms 三帧", 3, False,
        [gauss_spec(n3, 3131), sparse_spec(n3, 3132), dc_spec(n3)])
    add("lm1t", "5ms 瞬态两帧", 1, True,
        [gauss_spec(n1, 3141), sparse_spec(n1, 3142)])
    add("lm2t", "10ms 瞬态两帧", 2, True,
        [gauss_spec(n2, 3151), dc_spec(n2)])
    add("lm3t", "20ms 瞬态两帧（大动态）", 3, True,
        [gauss_spec(n3, 3161, scale=80.0), gauss_spec(n3, 3162, scale=80.0)])
    add("carry", "pending 三帧贯穿", 3, False,
        [dc_spec(n3), zero_spec(n3), gauss_spec(n3, 3171)])

    need = ["lm0", "lm1", "lm2", "lm3", "lm1t", "lm2t", "lm3t",
            "gauss", "sparse", "dc", "zero", "big", "multi3"]
    missing = [k for k in need if not cov.get(k)]
    if missing:
        raise SystemExit(f"imdct coverage incomplete: {missing}")
    print("[cov] " + " ".join(f"{k}={cov[k]}" for k in sorted(cov)))
    return cases


def emit_case(c):
    out = [""]
    tag = f"imd_{c.name}"
    for k, (sp, _o, _p) in enumerate(c.results):
        out += ["///|",
                f"let {tag}_{k} : Array[Double] = {fmt_f(sp)}",
                ""]
    out += ["///|", f"fn play_{tag}() -> Unit raise {{"]
    pend0 = fmt_f([0.0] * (ref.OVERLAP // 2))
    out.append(f"  let pend = {pend0}")
    for k, (_sp, o, p) in enumerate(c.results):
        trans = "true" if c.transient else "false"
        out += [
            f"  let (out{k}, np{k}) = celt_imdct_frame("
            f"{tag}_{k}, {c.lm}, {trans}, pend)",
            f"  expect_dn_close(out{k}, {fmt_f(o)}, "
            f"\"{c.name}.f{k}/out\", 0.000000001)",
            f"  expect_dn_close(np{k}, {fmt_f(p)}, "
            f"\"{c.name}.f{k}/pend\", 0.000000001)",
        ]
        if k + 1 < len(c.results):
            out.append(f"  let pend = np{k}")
    out += [
        "}",
        "",
        "///|",
        f'test "金标：IMDCT · {c.label}" {{',
        f"  play_{tag}()",
        "}",
        "",
    ]
    return "\n".join(out)


def main():
    cases = build_cases()
    head = "\n".join([
        "// 由 tools/gen_imdct_goldens.py 生成，请勿手改。",
        "//",
        "// IMDCT 与帧合成（RFC 6716 §4.3.7）金标：各 LM、瞬态与跨帧",
        "// pending 链上的帧序列，期望值（帧输出 / 帧末 pending）由",
        "// tools/celt_imdct_ref.py 的独立参考端（RFC 余弦和直接定义 +",
        "// 显式镜像）算出；MoonBit 端重放同一序列后逐项比对。",
        "",
        "///|",
        "",
    ])
    body = [head]
    for c in cases:
        body.append(emit_case(c))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "imdct_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(body))
    print(f"[ok] {len(cases)} cases -> imdct_goldens_wbtest.mbt")
    moon_fmt()


if __name__ == "__main__":
    main()
