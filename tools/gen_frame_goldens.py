# -*- coding: utf-8 -*-
"""生成帧级主流程（RFC 6716 §4.3 频域段）的 MoonBit 金标。

参考端在 tools/celt_frame_ref.py（独立编排），本文件负责：
  - 帧序列构造与定向搜索（静音/瞬态/帧内/后滤波/反塌缩标志位、
    各 LM、预置状态）；
  - 每帧期望输出（帧首标志、频谱、频域输出、mask、seed、解码器
    终态）与帧末状态（三代能量 + rng）字面量的生成；
  - 覆盖自检：任一编排分支缺失即报错退出。

用法：python tools/gen_frame_goldens.py
输出：frame_goldens_wbtest.mbt
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
import celt_frame_ref as fr_mod  # noqa: E402
from celt_frame_ref import decode_frame, FrameState  # noqa: E402
from celt_frame_header_ref import decode_frame_header  # noqa: E402
from _fmt import moon_fmt, moon_num  # noqa: E402
import random  # noqa: E402

END = 21


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def fmt_i(vals):
    return "[" + ", ".join(str(int(v)) for v in vals) + "]"


def fmt_f(vals):
    return "[" + ", ".join(moon_num(v) for v in vals) + "]"


def find_header(pred, lm, nbytes, seed0, limit=400000):
    """只跑帧首解码的定向搜索（静音/瞬态/帧内/后滤波）。"""
    for k in range(limit):
        data = rand_bytes(nbytes, seed0 + k)
        dec = RangeDecoder(data)
        h = decode_frame_header(dec, nbytes, 0, lm, {})
        if pred(h):
            return data
    raise SystemExit(f"帧首定向搜索未命中 (lm={lm}, seed0={seed0})")


def find_full(pred, lm, nbytes, seed0, warm=None, limit=40000):
    """整帧解码的定向搜索（反塌缩标志等深层分支）。

    warm = 先跑的帧序列 [(data, lm), ...]：与候选帧共享状态，用于给
    三代能量历史打底（否则首帧的历史全 0，反塌缩的 prev 读取分不出
    对错）。pred(res, diag, hist_e, cur_e) 可读到候选帧开跑前的
    [0..21) 能量历史与帧末当前能量。
    """
    for k in range(limit):
        data = rand_bytes(nbytes, seed0 + k)
        st = FrameState()
        if warm:
            for wd, wlm in warm:
                wdec = RangeDecoder(wd)
                decode_frame(wdec, len(wd), 0, END, wlm, st, {})
        hist = st.old_e[:END]
        dec = RangeDecoder(data)
        diag = {}
        res = decode_frame(dec, nbytes, 0, END, lm, st, diag)
        if pred(res, diag, hist, st.old_e[:END]):
            return data
    raise SystemExit(f"整帧定向搜索未命中 (lm={lm}, seed0={seed0})")


_ORIG_ANTI = fr_mod.anti_collapse


def _mut_anti(x, masks, lm, start, end, loge, prev1, prev2, pulses, seed, diag):
    # 模拟 MoonBit 端「反塌缩 prev1 误接当前帧能量」的接错变异，
    # 仅供 find_prev_diverged 做分歧搜索（prev1 变成当前帧 loge）。
    _ORIG_ANTI(
        x, masks, lm, start, end, loge, loge, prev1, pulses, seed, diag)


def find_prev_diverged(warm, preset_loge, lm, nbytes, seed0, limit=400000):
    """定向搜索：原版与「prev1 误接当前帧能量」变异版输出显著分歧的帧。

    prev 接线对错的观测前提（反塌缩 §4.3.5）：
      - 原版 min(prev1=历史, prev2=旧史)：预置正历史 + 旧史 0 → 0，
        ediff = 当前能量 E2；接错版 prev1 变当前帧 → min(E2, 历史)，
        E2 < 历史时 ediff = 0 → 幅度顶到 thresh。原版只要未被 thresh
        饱和（E2 足够大）两版即分歧；
      - 全塌缩带的注入幅度会被 gain=1 的 renormalise 约掉（±r 归一成
        ±1/√n，只剩浮点尾数噪声），必须存在部分塌缩带才可观测，
        故金标判据用相对 1e-6 量级的显著分歧，不用逐位不等；
      - 帧首标志等门控（anti_on 需瞬态 + LM≥2 + 预算充足）先用原版
        便宜地过滤，只对通过者跑变异版。

    warm（预热帧序列，共享状态）与 preset_loge（预置 old_log_e 历史，
    旧史保持 0）二选一；金标取原版输出，MoonBit 端接错 prev1 必变红。
    """
    full = (1 << (1 << lm)) - 1
    base = None
    if warm:
        base = FrameState()
        for wd, wlm in warm:
            d = RangeDecoder(wd)
            decode_frame(d, len(wd), 0, END, wlm, base, {})

    def fresh():
        if warm:
            st = FrameState()
            st.old_e = base.old_e[:]
            st.old_log_e = base.old_log_e[:]
            st.old_log_e2 = base.old_log_e2[:]
            st.rng = base.rng
        else:
            st = FrameState()
            st.old_log_e = list(preset_loge)
        return st

    fr_mod.anti_collapse = _ORIG_ANTI
    try:
        for k in range(limit):
            cand = rand_bytes(nbytes, seed0 + k)
            st = fresh()
            d = RangeDecoder(cand)
            diag = {}
            res = decode_frame(d, len(cand), 0, END, lm, st, diag)
            if "r_anti_on" not in diag:
                continue
            if not any(0 < v < full for v in res["masks"]):
                continue
            fr_mod.anti_collapse = _mut_anti
            st2 = fresh()
            d2 = RangeDecoder(cand)
            res2 = decode_frame(d2, len(cand), 0, END, lm, st2, {})
            fr_mod.anti_collapse = _ORIG_ANTI
            a, b = res["spectrum"], res2["spectrum"]
            scale = max(abs(v) for v in a) or 1.0
            if max(abs(a[i] - b[i]) for i in range(len(a))) > 1e-6 * scale:
                return cand
    finally:
        fr_mod.anti_collapse = _ORIG_ANTI
    raise SystemExit(
        f"prev1 分歧搜索未命中 (lm={lm}, nbytes={nbytes}, seed0={seed0})")


class FrameCase:
    """一个用例 = 共享状态的一串帧。"""

    def __init__(self, name, label, frames, preset=None):
        self.name = name
        self.label = label
        self.frames = frames  # [(data, lm), ...]
        self.preset = preset  # (old_e, log_e, log_e2, rng) 或 None
        self.run()

    def run(self):
        st = FrameState()
        if self.preset:
            oe, le, l2, rng = self.preset
            st.old_e = list(oe)
            st.old_log_e = list(le)
            st.old_log_e2 = list(l2)
            st.rng = rng
        self.results = []
        for data, lm in self.frames:
            dec = RangeDecoder(data)
            diag = {}
            res = decode_frame(dec, len(data), 0, END, lm, st, diag)
            self.results.append((data, lm, dec, res, diag))
        self.final = (st.old_e[:], st.old_log_e[:], st.old_log_e2[:], st.rng)


def build_cases():
    cases = []
    cov = {"multi": 0, "preset": 0}

    def note(res, diag, lm, preset, nframes):
        h = res["header"]
        if h["silence"]:
            cov["silence"] = 1
        if h["is_transient"]:
            cov["transient"] = 1
        else:
            cov["nontransient"] = 1
        if h["intra"]:
            cov["intra"] = 1
        if h["postfilter_on"]:
            cov["pf_on"] = 1
        if "r_frsv" in diag:
            cov["anti_rsv"] = 1
        if "r_anti_on" in diag:
            cov["anti_on"] = 1
        if "r_anti_off" in diag:
            cov["anti_off"] = 1
        cov[f"lm{lm}"] = 1
        if nframes >= 2:
            cov["multi"] += 1
        if preset:
            cov["preset"] = 1

    def add(name, label, frames, preset=None):
        c = FrameCase(name, label, frames, preset)
        for _d, lm, _dec, res, diag in c.results:
            note(res, diag, lm, preset is not None, len(c.frames))
        cases.append(c)
        return c

    # 1. lm3 长块三帧序列：状态轮换与 rng 线程化的基线
    fs = []
    for k in range(3):
        fs.append((
            find_header(lambda h: not h["is_transient"], 3, 64, 9100 + k),
            3))
    add("seq3", "长块三帧序列", fs)

    # 2. 瞬态帧接长块帧：轮换的 min 分支与整体下移分支
    t0 = find_header(lambda h: h["is_transient"], 3, 64, 9300)
    t1 = find_header(lambda h: not h["is_transient"], 3, 64, 9301)
    add("trans", "瞬态接长块两帧", [(t0, 3), (t1, 3)])

    # 3. 各 LM 基线（lm0 无瞬态标志，恒长块）
    add("lm0", "2.5ms 单帧", [(rand_bytes(64, 9400), 0)])
    add("lm1", "5ms 瞬态单帧", [(find_header(
        lambda h: h["is_transient"], 1, 64, 9401), 1)])
    add("lm2", "10ms 单帧", [(rand_bytes(64, 9402), 2)])

    # 4. 反塌缩 prev 接线：预置正历史（old_log_e=3，旧史 0）打底，
    #    候选帧由 find_prev_diverged 的原版/接错版显著分歧搜索选出
    #    （帧首门控先过滤，部分塌缩带 + 能量条件才跑变异版）；金标
    #    取原版输出，MoonBit 端 prev1 误接当前帧能量必变红
    le3 = [3.0] * 42
    a_on = None
    for lm_p, nb_p, s0 in [(2, 64, 9500), (2, 32, 9610), (2, 96, 9710),
                           (2, 48, 9810), (3, 64, 10500), (3, 32, 10610)]:
        try:
            a_on = find_prev_diverged(None, le3, lm_p, nb_p, s0)
            break
        except SystemExit:
            continue
    if a_on is None:
        raise SystemExit("prev1 分歧搜索全部 profile 未命中")
    add("anti_prev", "反塌缩 prev 接线（预置历史）", [(a_on, lm_p)],
        preset=([0.0] * 42, le3, [0.0] * 42, 0))
    # lm3 瞬态 + 标志位关
    a_off = find_full(
        lambda r, d, e1, e2: (r["header"]["is_transient"]
                              and "r_anti_off" in d),
        3, 64, 9600)
    add("lm3anti0", "瞬态反塌缩关", [(a_off, 3)])

    # 5. 帧内能量标志：第二帧 intra，能量预测走 intra 分支
    i0 = find_header(lambda h: not h["intra"], 3, 64, 9700)
    i1 = find_header(lambda h: h["intra"], 3, 64, 9701)
    add("intra", "帧内能量两帧", [(i0, 3), (i1, 3)])

    # 6. 静音帧接正常帧：静音置位 → 下一帧从 -28 预测
    s0 = find_header(lambda h: h["silence"], 3, 64, 9800)
    s1 = find_header(lambda h: not h["silence"], 3, 64, 9801)
    add("silen", "静音接正常两帧", [(s0, 3), (s1, 3)])

    # 7. 后滤波开（帧首携带 pitch/gain/tapset）
    p0 = find_header(lambda h: h["postfilter_on"], 3, 96, 9900)
    add("pf", "后滤波单帧", [(p0, 3)])

    # 8. 预置状态：后半 > 前半（入口 MAXG 分支）+ 非零 rng（种子输入）
    oe = [0.0] * 42
    le = [0.0] * 42
    l2 = [0.0] * 42
    oe[5] = -3.5
    oe[21 + 5] = 1.25  # 后半更大 → 入口应把前半抬到 1.25
    oe[9] = 2.0
    oe[21 + 9] = -7.0  # 前半更大 → 保持
    le[5] = 0.5
    l2[5] = -1.25
    pf = find_header(lambda h: not h["is_transient"], 3, 64, 9950)
    add("preset", "预置状态入口保护", [(pf, 3)],
        preset=(oe, le, l2, 305419896))  # 0x12345678

    need = ["silence", "transient", "nontransient", "intra", "pf_on",
            "anti_rsv", "anti_on", "anti_off", "preset", "multi",
            "lm0", "lm1", "lm2", "lm3"]
    missing = [k for k in need if not cov.get(k)]
    if missing:
        raise SystemExit(f"frame coverage incomplete: {missing}")
    keys = " ".join(f"{k}={cov[k]}" for k in sorted(cov))
    print(f"[cov] {keys}")
    return cases


def emit_case(c):
    out = [""]
    for k, (data, _lm, _dec, _res, _diag) in enumerate(c.results):
        hexlit = 'b"' + "".join("\\x%02x" % b for b in data) + '"'
        out += ["///|", f"const FR_{c.name.upper()}_{k} : Bytes = {hexlit}", ""]
    out += ["///|", f"fn play_{c.name}() -> Unit raise {{"]
    if c.preset:
        oe, le, l2, rng = c.preset
        out.append(
            f"  let state = CeltDecoderState::{{old_e: {fmt_f(oe)}, "
            f"old_log_e: {fmt_f(le)}, old_log_e2: {fmt_f(l2)}, "
            f"rng: {rng}L}}")
    else:
        out.append(
            "  let state = CeltDecoderState::{old_e: "
            + fmt_f([0.0] * 42)
            + ", old_log_e: "
            + fmt_f([0.0] * 42)
            + ", old_log_e2: "
            + fmt_f([0.0] * 42)
            + ", rng: 0L}")
    for k, (data, lm, dec, res, _diag) in enumerate(c.results):
        h = res["header"]
        out += [
            f"  let dec{k} = RangeDecoder::new(FR_{c.name.upper()}_{k})",
            f"  let res{k} = celt_decode_frame(dec{k}, {len(data)}, 0, {END}, "
            f"{lm}, state)",
            f"  expect_frame(",
            f"    dec{k}, res{k}, \"{c.name}.f{k}\",",
            f"    {'true' if h['silence'] else 'false'}, "
            f"{'true' if h['is_transient'] else 'false'}, "
            f"{'true' if h['intra'] else 'false'}, "
            f"{'true' if h['postfilter_on'] else 'false'},",
            f"    {h['postfilter_pitch']}, {moon_num(h['postfilter_gain'])}, "
            f"{h['postfilter_tapset']},",
            f"    {fmt_f(res['spectrum'])},",
            f"    {fmt_f(res['freq'])},",
            f"    {fmt_i(res['masks'])},",
            f"    {res['seed']}L,",
            f"    {dec.rng}L, {dec.val}L, {dec.tell()}, {dec.tell_frac()},",
            f"  )",
        ]
    oe, le, l2, rng = c.final
    out += [
        f"  expect_state(state, \"{c.name}.end\",",
        f"    {fmt_f(oe)},",
        f"    {fmt_f(le)},",
        f"    {fmt_f(l2)},",
        f"    {rng}L,",
        f"  )",
        "}",
        "",
        "///|",
        f'test "金标：帧主流程 · {c.label}" {{',
        f"  play_{c.name}()",
        "}",
        "",
    ]
    return "\n".join(out)


def main():
    cases = build_cases()
    head = "\n".join([
        "// 由 tools/gen_frame_goldens.py 生成，请勿手改。",
        "//",
        "// 帧级主流程（RFC 6716 §4.3 频域段）金标：帧序列与标志位定向",
        "// 搜索造出，期望值（帧首标志 / 频谱 / 频域输出 / mask / seed /",
        "// 解码器终态 / 帧末三代能量状态）由 tools/celt_frame_ref.py 的",
        "// 独立编排参考端算出；MoonBit 端重放同一帧序列后逐项比对。",
        "",
        "///|",
        "",
    ])
    body = [head]
    for c in cases:
        body.append(emit_case(c))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "frame_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(body))
    print(f"[ok] {len(cases)} cases -> frame_goldens_wbtest.mbt")
    moon_fmt()


if __name__ == "__main__":
    main()
