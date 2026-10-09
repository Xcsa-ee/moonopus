# -*- coding: utf-8 -*-
"""生成时域合成链（RFC 6716 §4.3.7 / §4.3.7.1 / §4.3.7.2）的 MoonBit 金标。

参考端在 tools/celt_decode_audio_ref.py（RFC 余弦和 IMDCT + 逐点直读
comb + 列表切片历史 + 直接 deemphasis），MoonBit 端是 IMDCT(DFT 路径) +
滑动状态 comb + 索引算术历史——本文件负责用例构造：
  - lm0/1/2/3 与瞬态帧、跨帧频谱复用（同信号只变参数，纯观测参数路由）；
  - 后滤波 关→开 / 开→改（周期·增益·tapset）/ 开→关（含钳制过境）；
  - LM=0 的参数延迟语义（本帧参数下一帧才开始过渡）；
  - 变长帧序列的历史滚动（N 逐帧变化）与零频谱帧（pending 衰减可见）。
覆盖自检：任一构造维度缺失即报错退出。

用法：python tools/gen_decode_audio_goldens.py
输出：decode_audio_goldens_wbtest.mbt
"""
import os
import random
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import celt_decode_audio_ref as ref  # noqa: E402
from celt_frame_ref import FrameState, decode_frame  # noqa: E402
from gen_frame_goldens import find_header  # noqa: E402
from gen_range_goldens import RangeDecoder  # noqa: E402
from _fmt import moon_fmt, moon_num  # noqa: E402

END = 21

# 跨帧递推放大：deemphasis 1/(1-α)≈6.7、comb 反馈 1/(1-G)≤4，稳态合计
# ~30×，单帧双路径 IMDCT 差实测 1e-11 级 → 取 1e-8（结构错 ≥1e-3 仍差
# 五个数量级）。
TOL = "0.00000001"


def freq_rand(n, seed, scale=16.0, nd=4):
    rs = random.Random(seed)
    return [round(rs.uniform(-scale, scale), nd) for _ in range(n)]


# 每案：(名字, 标签, 频谱表 {key: 列表或 "zeros"}, 帧序列)
# 帧 = (lm, transient, freq_key, pitch, gain, tapset)
CASES = [
    ("base_lm3", "20ms 基线：关滤波 + 零频谱帧的 pending 衰减",
     {"fa": lambda: freq_rand(960, 11), "fb": lambda: freq_rand(960, 12),
      "z": "zeros"},
     [(3, False, "fa", 0, 0.0, 0),
      (3, False, "fb", 0, 0.0, 0),
      (3, False, "z", 0, 0.0, 0),
      (3, False, "fa", 0, 0.0, 0)]),
    ("evolve_lm3", "20ms 关→开→连改三参→开→关（钳制过境）",
     {"fa": lambda: freq_rand(960, 21)},
     [(3, False, "fa", 0, 0.0, 0),
      (3, False, "fa", 100, 0.375, 1),
      (3, False, "fa", 47, 0.75, 2),
      (3, False, "fa", 60, 0.1875, 0),
      (3, False, "fa", 100, 0.375, 1),
      (3, False, "fa", 0, 0.0, 0)]),
    ("delay_lm0", "2.5ms 帧：参数逐帧变，LM=0 延迟一帧的过渡语义",
     {"g": lambda: freq_rand(120, 31)},
     [(0, False, "g", 60, 0.75, 1),
      (0, False, "g", 100, 0.375, 2),
      (0, False, "g", 47, 0.1875, 0),
      (0, False, "g", 100, 0.375, 2),
      (0, False, "g", 60, 0.75, 1)]),
    ("mix_lm", "变长帧序列 20/5/2.5/10/20ms 的历史滚动",
     {"fa": lambda: freq_rand(960, 41), "fb": lambda: freq_rand(240, 42),
      "g": lambda: freq_rand(120, 43), "fc": lambda: freq_rand(480, 44)},
     [(3, False, "fa", 100, 0.375, 1),
      (1, False, "fb", 100, 0.375, 1),
      (0, False, "g", 60, 0.75, 0),
      (2, False, "fc", 60, 0.75, 0),
      (3, False, "fa", 100, 0.375, 1)]),
    ("trans_lm3t", "瞬态短块帧 ×3 的合成与参数过渡",
     {"ta": lambda: freq_rand(960, 51), "tb": lambda: freq_rand(960, 52)},
     [(3, True, "ta", 60, 0.75, 2),
      (3, True, "tb", 100, 0.375, 1),
      (3, True, "ta", 100, 0.375, 1)]),
]


def build_cases():
    cov = {}
    out = []
    for name, label, spectra, frames in CASES:
        table = {}
        for key, spec in spectra.items():
            if spec == "zeros":
                table[key] = [0.0] * (120 << frames[0][0])
            else:
                table[key] = spec()
        # 参考端重放
        st = ref.new_state()
        want_pcm = []
        for (lm, tr, key, pitch, gain, tapset) in frames:
            want_pcm.append(
                ref.synth_frame(table[key], lm, tr, pitch, gain, tapset, st))
        out.append((name, label, table, frames, want_pcm))
        for i, (lm, tr, key, *_r) in enumerate(frames):
            cov[f"lm{lm}"] = 1
            if tr:
                cov["transient"] = 1
        on = [g > 0 for (_l, _t, _k, _p, g, _s) in frames]
        if any(not on[i] and on[i + 1] for i in range(len(on) - 1)):
            cov["off2on"] = 1
        if any(on[i] and not on[i + 1] for i in range(len(on) - 1)):
            cov["on2off"] = 1
        if any(on[i] and on[i + 1] and frames[i][2:] != frames[i + 1][2:]
               for i in range(len(on) - 1)):
            cov["change_on"] = 1
        if any(f[0] == 0 for f in frames):
            cov["lm0"] = 1
        if any(f[0] == 1 for f in frames):
            cov["lm1"] = 1
        if any(f[0] == 2 for f in frames):
            cov["lm2"] = 1
        if any(_l == 3 for (_l, _t, _k, _p, g, _s) in frames):
            cov["lm3"] = 1
        if any(table[f[2]] == [0.0] * len(table[f[2]]) for f in frames):
            cov["zero_frame"] = 1
    need = ["lm0", "lm1", "lm2", "lm3", "transient", "off2on", "on2off",
            "change_on", "zero_frame"]
    missing = [k for k in need if not cov.get(k)]
    if missing:
        raise SystemExit(f"decode_audio coverage incomplete: {missing}")
    print("[cov] " + " ".join(f"{k}={cov[k]}" for k in sorted(cov)))
    return out


def build_byte_cases():
    """真字节流端到端用例：bytes →（参考端 freq 解码 + 参考端合成链）
    期望 PCM；MoonBit 端走 celt_decode_frame_audio 全链重放。"""
    cov = {}
    cases = []

    def add(name, label, frames):
        fst = FrameState()
        sst = ref.new_state()
        rows = []
        for (data, lm) in frames:
            dec = RangeDecoder(data)
            res = decode_frame(dec, len(data), 0, END, lm, fst, {})
            h = res["header"]
            pcm = ref.synth_frame(
                res["freq"], lm, h["is_transient"], h["postfilter_pitch"],
                h["postfilter_gain"], h["postfilter_tapset"], sst)
            rows.append((data, lm, pcm))
            if h["postfilter_on"]:
                cov["pf_on"] = 1
            if h["is_transient"]:
                cov["transient"] = 1
            cov[f"lm{lm}"] = 1
        if len(rows) >= 2:
            cov["multi"] = 1
        cases.append((name, label, rows))

    off_a = find_header(
        lambda h: not h["postfilter_on"] and not h["silence"], 3, 64, 21000)
    on_b = find_header(
        lambda h: h["postfilter_on"] and not h["silence"], 3, 96, 21100)
    off_c = find_header(
        lambda h: not h["postfilter_on"] and not h["silence"], 3, 64, 21200)
    add("aud_pf", "字节流：关 → 后滤波开 → 关（帧头参数路由）",
        [(off_a, 3), (on_b, 3), (off_c, 3)])
    on0 = find_header(
        lambda h: h["postfilter_on"] and not h["silence"], 0, 64, 21300)
    add("aud_lm0", "字节流：2.5ms 后滤波单帧（lm 直通）", [(on0, 0)])
    try:
        t_on = find_header(
            lambda h: h["is_transient"] and h["postfilter_on"]
            and not h["silence"], 3, 96, 21400)
    except SystemExit:
        t_on = find_header(
            lambda h: h["is_transient"] and not h["silence"], 3, 64, 21401)
    add("aud_trans", "字节流：瞬态帧接长块帧（is_transient 直通）",
        [(t_on, 3), (off_a, 3)])
    need = ["pf_on", "transient", "lm0", "lm3", "multi"]
    missing = [k for k in need if not cov.get(k)]
    if missing:
        raise SystemExit(f"decode_audio byte coverage incomplete: {missing}")
    print("[cov-byte] " + " ".join(f"{k}={cov[k]}" for k in sorted(cov)))
    return cases


def emit_byte_case(name, label, rows):
    out = [""]
    for k, (data, _lm, _pcm) in enumerate(rows):
        hexlit = 'b"' + "".join("\\x%02x" % b for b in data) + '"'
        out += ["///|", f"const AUD_{name.upper()}_{k} : Bytes = {hexlit}", ""]
    out += ["///|", f"fn play_aud_{name}() -> Unit raise {{"]
    out.append("  let celt = CeltDecoderState::new()")
    out.append("  let synth = CeltSynthState::new()")
    for k, (data, lm, pcm) in enumerate(rows):
        out += [
            f"  let dec{k} = RangeDecoder::new(AUD_{name.upper()}_{k})",
            f"  let ares{k} = celt_decode_frame_audio(dec{k}, {len(data)}, "
            f"0, {END}, {lm}, celt, synth)",
            f"  expect_dn_close(ares{k}.pcm, {fmt_f(pcm)}, "
            f"\"aud/{name}/f{k}\", {TOL})",
        ]
    out += ["}", "", "///|", f'test "金标：音频端到端 · {label}" {{',
            f"  play_aud_{name}()", "}", ""]
    return "\n".join(out)


def fmt_f(vals):
    # 期望值取整到 1e-12：双路径噪声地板（~1e-19）在十进制展开时会丢
    # 尾数触发 moon_num 的回环校验，取整后的绝对偏差远小于比对容差。
    return "[" + ", ".join(moon_num(round(v, 12)) for v in vals) + "]"


def emit_case(name, label, table, frames, want_pcm):
    out = ["", "///|", f"fn play_syn_{name}() -> Unit raise {{"]
    out.append("  let st = CeltSynthState::new()")
    for key, vals in table.items():
        n = len(vals)
        if all(v == 0.0 for v in vals):
            out.append(f"  let {key} = Array::make({n}, 0.0)")
        else:
            out.append(f"  let {key} = {fmt_f(vals)}")
    for k, ((lm, tr, key, pitch, gain, tapset), want) in enumerate(
            zip(frames, want_pcm)):
        out.append(
            f"  let p{k} = celt_synth_frame({key}, {lm}, "
            f"{'true' if tr else 'false'}, {pitch}, "
            f"{moon_num(gain)}, {tapset}, st)")
        out.append(
            f"  expect_dn_close(p{k}, {fmt_f(want)}, "
            f"\"syn/{name}/f{k}\", {TOL})")
    out += ["}", "", "///|", f'test "金标：时域合成链 · {label}" {{',
            f"  play_syn_{name}()", "}", ""]
    return "\n".join(out)


def main():
    cases = build_cases()
    byte_cases = build_byte_cases()
    head = "\n".join([
        "// 由 tools/gen_decode_audio_goldens.py 生成，请勿手改。",
        "//",
        "// 时域合成链（RFC 6716 §4.3.7/§4.3.7.1/§4.3.7.2）金标：频谱与",
        "// 帧头后滤波参数的多帧序列，期望 PCM 由",
        "// tools/celt_decode_audio_ref.py 的独立参考端（余弦和 IMDCT +",
        "// 逐点直读 comb + 列表切片历史 + 直接 deemphasis）算出；MoonBit",
        "// 端以同一序列在 CeltSynthState 上重放后逐帧比对。末尾三例为真",
        "// 字节流端到端：参考端 freq 解码（celt_frame_ref）+ 参考端合成链",
        "// 对 MoonBit 端 celt_decode_frame_audio 全链。",
        "",
        "///|",
        "",
    ])
    body = [head]
    for c in cases:
        body.append(emit_case(*c))
    for c in byte_cases:
        body.append(emit_byte_case(*c))
    path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "decode_audio_goldens_wbtest.mbt",
    )
    with open(path, "w", encoding="utf-8") as f:
        f.write("".join(body))
    print(f"[ok] {len(cases)} + {len(byte_cases)} cases -> "
          f"decode_audio_goldens_wbtest.mbt")
    moon_fmt()


if __name__ == "__main__":
    main()
