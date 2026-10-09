# -*- coding: utf-8 -*-
"""生成「与真实 libopus 比特流的 PCM 差分」闸门金标。

流程（需本地 ffmpeg，带 libopus 编解码器；缺则报错退出）：
  1. 合成确定性音乐信号 WAV（单声道 48 kHz）；
  2. libopus 编码器产出 CELT-only 夹具（帧时长/码率/CBR 组合），
     Ogg TOC 逐包校验：config 必须在 28..31（CELT 全频带，即解码器
     end=21 的已验证路径）、非立体声，否则自动升码率/换 lowdelay
     重编，仍不达标即退出；
  3. libopus **解码器**（ffmpeg -c:a libopus，非原生解码器）出参考
     f32 PCM，按 pre-skip 对齐口径由 MoonBit 端截同位置；
  4. 夹具字节与参考样本字面量发到 pcm_gate_wbtest.mbt，MoonBit 端
     decode_opus_pcm 全链重放后逐样本比对。

用法：python tools/gen_pcm_gate.py
输出：pcm_gate_wbtest.mbt（可重复生成；tests 不依赖 ffmpeg）
"""
import glob
import math
import os
import random
import struct
import subprocess
import sys
import wave

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from _fmt import moon_fmt, moon_num  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORK = os.path.join(ROOT, "_build", "gate")
# 经验容差起点：libopus f32 逐步舍入经 deemphasis/comb 跨帧放大后的
# 量级（结构错 ≥1e-3，仍差数量级）；实测回填可调小。
TOL = "0.0001"

# (名字, 标签, 时长s, frame_duration ms, 初始码率, vbr)
CASES = [
    ("lm0", "2.5ms CBR 64k（lm0，密包）", 0.30, 2.5, "64k", "off"),
    ("lm1", "5ms VBR 96k（lm1）", 0.30, 5, "96k", "on"),
    ("lm2", "10ms VBR 128k（lm2）", 0.30, 10, "128k", "on"),
    ("lm3", "20ms VBR 96k（lm3）", 0.30, 20, "96k", "on"),
    ("long", "20ms VBR 128k 长流（累计漂移）", 0.80, 20, "128k", "on"),
]


def find_ffmpeg():
    pat = os.path.join(os.path.dirname(ROOT), "_ffmpeg", "_bin", "**",
                       "ffmpeg*.exe")
    got = glob.glob(pat, recursive=True)
    if not got:
        raise SystemExit(
            f"未找到 ffmpeg（扫描 {pat}）。参考端需要带 libopus 的 ffmpeg；"
            "可将完整构建放到 ../_ffmpeg/_bin/ 后重跑。")
    return got[0]


def make_wav(path, dur, seed=4242):
    """确定性音乐信号：和弦 + 滑音 + 包络 + 低噪声。"""
    rs = random.Random(seed)
    sr = 48000
    n = int(sr * dur)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        frames = bytearray()
        for i in range(n):
            t = i / sr
            env = min(1.0, t * 8.0) * (0.75 + 0.25 * math.sin(2 * math.pi * 3 * t))
            v = 0.30 * math.sin(2 * math.pi * 220.0 * t)
            v += 0.20 * math.sin(2 * math.pi * 277.18 * t + 0.7)
            v += 0.15 * math.sin(2 * math.pi * 329.63 * t + 1.3)
            v += 0.18 * math.sin(2 * math.pi * (440.0 + 120.0 * t) * t)
            v += 0.05 * (rs.random() - 0.5)
            s = max(-0.95, min(0.95, v * env))
            frames += struct.pack("<h", int(s * 32767))
        w.writeframes(bytes(frames))


def ogg_packets(data):
    """最小 Ogg 解包：按 lacing 重组逻辑 packet，返回 [bytes]。"""
    pkts = []
    partial = b""
    i = 0
    while True:
        j = data.find(b"OggS", i)
        if j < 0 or j + 27 > len(data):
            break
        continued = data[j + 5] & 1
        nseg = data[j + 26]
        # 页头共 27 字节（4+1+1+8+4+4+4+1），段表从 27 起
        segs = data[27 + j:27 + j + nseg]
        body = 27 + j + nseg
        buf = partial if continued else b""
        if not continued:
            partial = b""
        pos = body
        for s in segs:
            buf += data[pos:pos + s]
            pos += s
            if s < 255:
                pkts.append(buf)
                buf = b""
        partial = buf
        i = j + 1
    return pkts


def toc_info(pkt):
    toc = pkt[0]
    return toc >> 3, (toc >> 2) & 1, toc & 3


def encode(ffmpeg, wav, opus, fd, bitrate, vbr, application=None):
    cmd = [ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
           "-i", wav, "-c:a", "libopus", "-frame_duration", str(fd),
           "-b:a", bitrate, "-vbr", vbr, "-ar", "48000", "-ac", "1"]
    if application:
        cmd += ["-application", application]
    cmd += [opus]
    subprocess.run(cmd, check=True, capture_output=True)


def verify_celt_fb(opus_path):
    """逐包 TOC 校验：返回 (configs, codes, stereo_seen, bad_reason)。
    前两个包是 OpusHead/OpusTags 头包，音频从第 3 包起。"""
    data = open(opus_path, "rb").read()
    configs, codes = set(), set()
    stereo = False
    for pkt in ogg_packets(data)[2:]:
        if not pkt:
            continue
        cfg, st, code = toc_info(pkt)
        configs.add(cfg)
        codes.add(code)
        stereo = stereo or bool(st)
        if not (28 <= cfg <= 31):
            return configs, codes, stereo, f"config {cfg} 非 CELT 全频带"
        if st:
            return configs, codes, stereo, "出现立体声包"
    return configs, codes, stereo, None


def decode_ref(ffmpeg, opus, raw):
    # 显式指定 libopus 解码器（ffmpeg 另有原生 opus 解码器）
    subprocess.run(
        [ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
         "-c:a", "libopus", "-i", opus, "-f", "f32le",
         "-acodec", "pcm_f32le", "-ar", "48000", "-ac", "1", raw],
        check=True, capture_output=True)
    with open(raw, "rb") as f:
        blob = f.read()
    n = len(blob) // 4
    return list(struct.unpack("<%df" % n, blob[:n * 4]))


def build_case(ffmpeg, name, label, dur, fd, bitrate, vbr):
    wav = os.path.join(WORK, f"{name}.wav")
    opus = os.path.join(WORK, f"{name}.opus")
    raw = os.path.join(WORK, f"{name}.f32")
    make_wav(wav, dur)
    # 未达标时的升级阶梯：加码率 → 换 lowdelay 应用
    attempts = [(bitrate, vbr, None),
                ("160k", vbr, None),
                ("160k", "on", "lowdelay")]
    last = None
    for (br, vr, app) in attempts:
        encode(ffmpeg, wav, opus, fd, br, vr, app)
        configs, codes, stereo, bad = verify_celt_fb(opus)
        last = (configs, codes, stereo, bad)
        if bad is None:
            break
    if last[3]:
        raise SystemExit(f"[{name}] 夹具非 CELT 全频带：{last[3]} "
                         f"(configs={sorted(last[0])})")
    ref = decode_ref(ffmpeg, opus, raw)
    if len(ref) < int(dur * 48000 * 0.9):
        raise SystemExit(f"[{name}] 参考 PCM 过短：{len(ref)}")
    # 参考信号不得近静音（防假绿）
    energy = sum(v * v for v in ref) / len(ref)
    if energy < 1e-4:
        raise SystemExit(f"[{name}] 参考信号近静音 energy={energy}")
    opus_bytes = open(opus, "rb").read()
    print(f"[{name}] {len(opus_bytes)}B opus, ref {len(ref)} 样本, "
          f"energy={energy:.4f}, configs={sorted(last[0])}, "
          f"codes={sorted(last[1])}")
    return name, label, opus_bytes, ref, sorted(last[1])


def fmt_f(vals):
    return "[" + ", ".join(moon_num(round(v, 9)) for v in vals) + "]"


def emit(cases, codes_seen):
    out = ["// 由 tools/gen_pcm_gate.py 生成，请勿手改。",
           "//",
           "// 最终闸门：与真实 libopus 比特流的 PCM 差分。夹具由 libopus",
           "// 编码器产出（逐包 TOC 校验为 CELT 全频带 config 28..31），参考",
           "// PCM 来自 ffmpeg 显式指定的 libopus 解码器（f32）。MoonBit 端",
           "// decode_opus_pcm 全链重放后逐样本比对（pre-skip 截头，长度须",
           "// 与参考一致）。ffmpeg 构建与生成命令见证据注释。",
           "",
           "///|",
           f"const GATE_TOL : Double = {TOL}",
           "",
           "///|",
           "/// 逐样本差分：长度必须一致，超容差即失败（带样本下标）。",
           "fn expect_pcm_close(",
           "  got : Array[Double],",
           "  want : Array[Double],",
           "  tag : String,",
           ") -> Unit raise {",
           "  if got.length() != want.length() {",
           "    @test.fail(",
           "      \"\\{tag}: 长度 \\{got.length()} != 参考 \\{want.length()}\",",
           "    )",
           "  }",
           "  let mut worst = 0.0",
           "  let mut wi = 0",
           "  for i in 0..<want.length() {",
           "    let d = (got[i] - want[i]).abs()",
           "    if d > worst {",
           "      worst = d",
           "      wi = i",
           "    }",
           "    if d > GATE_TOL * (1.0 + want[i].abs()) {",
           "      @test.fail(",
           "        \"\\{tag}: 样本 \\{i} 差 \\{d}：got \\{got[i]} want \" +",
           "          \"\\{want[i]}（最差 \\{worst} @ \\{wi}）\",",
           "      )",
           "    }",
           "  }",
           "}",
           ""]
    for (name, label, opus_bytes, ref, _codes) in cases:
        hexlit = "b\"" + "".join("\\x%02x" % b for b in opus_bytes) + "\""
        out += ["///|", f"const GATE_{name.upper()}_OPUS : Bytes = {hexlit}", ""]
        # const 不允许数组类型，参考样本以函数体形式常驻
        out += ["///|", f"fn gate_{name}_ref() -> Array[Double] {{",
                f"  {fmt_f(ref)}", "}", ""]
        out += ["///|", f"fn play_gate_{name}() -> Unit raise {{",
                f"  let pcm = match decode_opus_pcm(GATE_{name.upper()}_OPUS) {{",
                "    Ok(a) => a",
                "    Err(e) => @test.fail(\"解码失败：\\{e}\")",
                "  }",
                f"  expect_pcm_close(pcm, gate_{name}_ref(), "
                f"\"gate/{name}\")",
                "}", "",
                "///|",
                f'test "PCM 差分：libopus 参考 · {label}" {{',
                f"  play_gate_{name}()",
                "}", ""]
    out = out[:1] + [f"// 用例打包形态覆盖的 §3 code：{codes_seen}"] + out[1:]
    path = os.path.join(ROOT, "pcm_gate_wbtest.mbt")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(out))
    print(f"[ok] {len(cases)} fixtures -> pcm_gate_wbtest.mbt")


def main():
    os.makedirs(WORK, exist_ok=True)
    ffmpeg = find_ffmpeg()
    ver = subprocess.run([ffmpeg, "-version"], capture_output=True,
                         encoding="utf-8", errors="replace"
                         ).stdout.splitlines()[0]
    print("[ffmpeg]", ver)
    cases = []
    codes_seen = set()
    for c in CASES:
        got = build_case(ffmpeg, *c)
        codes_seen.update(got[-1])
        cases.append(got)
    if 0 not in codes_seen:
        print("[warn] 未见 code 0 包")
    emit(cases, ",".join(str(x) for x in sorted(codes_seen)))
    moon_fmt()


if __name__ == "__main__":
    main()
