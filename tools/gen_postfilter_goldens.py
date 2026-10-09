# -*- coding: utf-8 -*-
"""生成后滤波（RFC 6716 §4.3.7.1）的 MoonBit 金标。

参考端在 tools/celt_postfilter_ref.py（逐点直读结构），MoonBit 端是
参考实现的滑动状态结构——本文件负责：
  - 参数组合构造（恒等/常数段/过渡/淡出淡入/周期钳制/仅 tapset 切换/
    lm0 单段/最大周期边界/双段调用形态）；
  - 输入缓冲（1024 历史 + 960 主体，历史取周期附近正弦以放大滤波
    可观测性）与期望终值字面量的生成；
  - 覆盖自检：任一构造分支缺失即报错退出。

用法：python tools/gen_postfilter_goldens.py
输出：postfilter_goldens_wbtest.mbt
"""
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import celt_postfilter_ref as pf  # noqa: E402
from celt_imdct_ref import celt_window  # noqa: E402
from _fmt import moon_fmt, moon_num  # noqa: E402

BASE = 1024
N = 960
WIN = celt_window(120)


def fmt_f(vals):
    return "[" + ", ".join(moon_num(v) for v in vals) + "]"


def make_signal(seed):
    """历史+主体：两个基音周期附近正弦叠加确定性形状，幅度 ≤ 1。"""
    rs = random.Random(seed)
    out = []
    for k in range(BASE + N):
        v = 0.55 * math.sin(2 * math.pi * k / 100.0)
        v += 0.3 * math.sin(2 * math.pi * k / 47.0 + 1.1)
        v += 0.1 * math.sin(2 * math.pi * k / 60.0 + 2.3)
        v += rs.uniform(-0.05, 0.05)
        out.append(v)
    return out


# 每个用例：(名字, 标签, [(offset, n, t0, t1, g0, g1, ts0, ts1), ...])
CASES = [
    ("ident", "增益全零恒等",
     [(0, 960, 100, 100, 0.0, 0.0, 0, 0)]),
    ("const", "参数全等走常数段",
     [(0, 960, 100, 100, 0.375, 0.375, 1, 1)]),
    ("trans", "旧新过渡（双段调用形态）",
     [(0, 120, 60, 100, 0.75, 0.375, 2, 0),
      (120, 840, 100, 100, 0.375, 0.375, 0, 0)]),
    ("fadeout", "增益淡出到 0",
     [(0, 120, 47, 47, 0.75, 0.0, 0, 1),
      (120, 840, 47, 47, 0.0, 0.0, 1, 1)]),
    ("fadein", "增益从 0 淡入",
     [(0, 120, 100, 100, 0.0, 0.1875, 1, 1),
      (120, 840, 100, 100, 0.1875, 0.1875, 1, 1)]),
    ("fadein_long", "单段长淡入（g0=0 且 g1≠0，常数段非空）",
     [(0, 960, 100, 100, 0.0, 0.375, 1, 1)]),
    ("clamp", "周期低于 15 双双钳制",
     [(0, 960, 3, 7, 0.1875, 0.09375, 0, 2)]),
    ("tsonly", "周期增益相同仅切 tapset",
     [(0, 960, 100, 100, 0.375, 0.375, 0, 2)]),
    ("lm0seg", "lm0 单段 120 样本",
     [(0, 120, 60, 100, 0.75, 0.375, 2, 1)]),
    ("maxper", "旧周期顶到 1022 边界",
     [(0, 960, 1022, 60, 0.09375, 0.75, 1, 2)]),
]


def build_cases():
    cov = {}
    out = []
    for idx, (name, label, calls) in enumerate(CASES):
        buf = make_signal(7000 + idx)
        # 用例自带信号副本：滤波就地改写输入
        src = buf[:]
        for (off, n, t0, t1, g0, g1, ts0, ts1) in calls:
            pf.comb_filter(buf, BASE + off, t0, t1, n, g0, g1, ts0, ts1, WIN)
        out.append((name, label, src, calls, buf))
        cov["identity" if g0 == 0 and g1 == 0 else "active"] = 1
        if len(calls) > 1:
            cov["multi"] = 1
        if any(t0 < 15 or t1 < 15 for (_o, _n, t0, t1, *_r) in calls):
            cov["clamp"] = 1
        if any(t0 == 1022 for (_o, _n, t0, *_r) in calls):
            cov["maxper"] = 1
        if any(g0 != g1 or t0 != t1 or s0 != s1
               for (_o, _n, t0, t1, g0, g1, s0, s1) in calls):
            cov["transition"] = 1
    need = ["identity", "active", "multi", "clamp", "maxper", "transition"]
    missing = [k for k in need if not cov.get(k)]
    if missing:
        raise SystemExit(f"postfilter coverage incomplete: {missing}")
    print("[cov] " + " ".join(f"{k}={cov[k]}" for k in sorted(cov)))
    return out


def emit_case(name, label, src, calls, want):
    out = [""]
    out += ["///|", f"fn play_pf_{name}() -> Unit raise {{"]
    out.append(f"  let buf = {fmt_f(src)}")
    out.append("  let win = Array::make(120, 0.0)")
    out.append("  for i in 0..<120 {")
    out.append("    win[i] = celt_window(i, 120)")
    out.append("  }")
    for (off, n, t0, t1, g0, g1, ts0, ts1) in calls:
        out.append(
            f"  celt_comb_filter(buf, {BASE + off}, {t0}, {t1}, {n}, "
            f"{moon_num(g0)}, {moon_num(g1)}, {ts0}, {ts1}, win)")
    out.append(f"  expect_dn_close(buf, {fmt_f(want)}, "
               f"\"pf/{name}\", 0.000000001)")
    out += [
        "}",
        "",
        "///|",
        f'test "金标：后滤波 · {label}" {{',
        f"  play_pf_{name}()",
        "}",
        "",
    ]
    return "\n".join(out)


def main():
    cases = build_cases()
    head = "\n".join([
        "// 由 tools/gen_postfilter_goldens.py 生成，请勿手改。",
        "//",
        "// 后滤波（RFC 6716 §4.3.7.1）金标：参数组合构造（恒等/常数段/",
        "// 过渡/淡出淡入/钳制/仅切 tapset/边界周期），期望终值由",
        "// tools/celt_postfilter_ref.py 的独立参考端（逐点直读结构）算出；",
        "// MoonBit 端以滑动状态结构重放同一调用序列后逐项比对。",
        "",
        "///|",
        "",
    ])
    body = [head]
    for c in cases:
        body.append(emit_case(*c))
    path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "postfilter_goldens_wbtest.mbt",
    )
    with open(path, "w", encoding="utf-8") as f:
        f.write("".join(body))
    print(f"[ok] {len(cases)} cases -> postfilter_goldens_wbtest.mbt")
    moon_fmt()


if __name__ == "__main__":
    main()
