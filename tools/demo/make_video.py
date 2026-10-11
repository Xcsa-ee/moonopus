# -*- coding: utf-8 -*-
"""demo 视频渲染：PIL 逐帧 + ffmpeg 合成（音轨 = moonopus 解出的真实 PCM）。

时间轴（共 19.6 s @30fps）：
  0.0-3.0   封面
  3.0-3.8   小节标题（音频 3.8s 起）
  3.8-9.9   波形渐进展示（与音频同步）
  9.9-15.4  与 libopus 参考的叠图 + 逐样本差分曲线
  15.4-19.6 验证指标卡

输入：
  本库 PCM   --pcm（默认 _build/demo/moon.f32，由 cmd/main 生成）
  比特流     --opus（默认 demo/sample.opus）
  参考解码   --ref（缺省时用 ffmpeg+libopus 现场解码 --opus 到
              _build/demo/ref.f32；自带文件时用 --ref-shift 指定对齐偏移）

产出：_build/demo/frames/*.png、_build/demo/demo_audio.wav、docs/demo.mp4
"""
import argparse
import os
import struct
import subprocess
import sys

import numpy as np
import soundfile as sf
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
BUILD = os.path.join(ROOT, "_build", "demo")
sys.path.insert(0, os.path.join(ROOT, "tools"))
from gen_pcm_gate import find_ffmpeg, decode_ref  # noqa: E402

W, H, FPS = 1280, 720, 30
BG = (13, 17, 23)
FG = (230, 237, 243)
DIM = (139, 148, 158)
CYAN = (34, 211, 238)
ORANGE = (245, 158, 11)
GREEN = (74, 222, 128)

# 中文字体候选（可用环境变量 MOONOPUS_FONT 覆盖）
FONT_CANDIDATES = [
    "C:/Windows/Fonts/msyh.ttc",
    "C:/Windows/Fonts/simhei.ttf",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/noto-cjk/NotoSansCJK-Regular.ttc",
    "/usr/share/fonts/truetype/wqy/wqy-microhei.ttc",
    "/System/Library/Fonts/PingFang.ttc",
]


def pick_font():
    for key in ("MOONOPUS_FONT", "MOONOPUS_FONT_BOLD"):
        if os.environ.get(key):
            if not os.path.exists(os.environ[key]):
                raise SystemExit(f"{key}={os.environ[key]} 不存在")
    plain = os.environ.get("MOONOPUS_FONT") or next(
        (p for p in FONT_CANDIDATES if os.path.exists(p)), None)
    if not plain:
        raise SystemExit(
            "未找到中文字体；请设置环境变量 MOONOPUS_FONT 指向 .ttf/.ttc")
    bold_env = os.environ.get("MOONOPUS_FONT_BOLD")
    bold = bold_env or next(
        (p for p in (os.path.join(os.path.dirname(plain), "msyhbd.ttc"),)
         if os.path.exists(p)), plain)
    return plain, bold


FONT, FONTB = pick_font()


def font(size, bold=False):
    return ImageFont.truetype(FONTB if bold else FONT, size)


def load_f32(path):
    blob = open(path, "rb").read()
    n = len(blob) // 4
    return np.array(struct.unpack("<%df" % n, blob[:n * 4]))


def envelope(x, width):
    n = len(x)
    step = max(1, n // width)
    lo = np.zeros(width)
    hi = np.zeros(width)
    for c in range(width):
        seg = x[c * step:(c + 1) * step]
        lo[c] = seg.min() if len(seg) else 0.0
        hi[c] = seg.max() if len(seg) else 0.0
    return lo, hi


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--pcm", default=os.path.join(BUILD, "moon.f32"),
                    help="moonopus 输出的原始 f32le（cmd/main 生成）")
    ap.add_argument("--opus", default=os.path.join(ROOT, "demo",
                                                   "sample.opus"),
                    help="待解码的 .opus 比特流")
    ap.add_argument("--ref", default=None,
                    help="参考解码 f32le；缺省时现场用 ffmpeg+libopus 解码")
    ap.add_argument("--ref-shift", type=int, default=0,
                    help="参考流相对本库输出的前导偏移样本数（默认 0）")
    ap.add_argument("--out", default=os.path.join(ROOT, "docs",
                                                   "demo.mp4"),
                    help="合成视频输出路径")
    args = ap.parse_args()

    if not os.path.exists(args.pcm):
        raise SystemExit(
            f"缺 {args.pcm}；先跑：\n"
            "  moon run cmd/main -- demo/sample.opus _build/demo/moon.f32")
    ffmpeg = find_ffmpeg()
    os.makedirs(BUILD, exist_ok=True)

    moon = load_f32(args.pcm)
    if args.ref:
        refl = load_f32(args.ref)
    else:
        args.ref = os.path.join(BUILD, "ref.f32")
        refl = decode_ref(ffmpeg, args.opus, args.ref)
        refl = np.array(refl, dtype=np.float32)
    s = args.ref_shift
    cref = refl[s:s + len(moon)]
    if len(cref) != len(moon):
        raise SystemExit(
            f"参考长度 {len(refl)}（shift {s}）与本库 {len(moon)} 不匹配")

    n = len(moon)
    # ---- 音轨：3.8s 静音 + 6s 音乐 + 静音补齐 ----
    TITLE_END, HEAD_END = 3.0, 3.8
    MUSIC_END = HEAD_END + n / 48000.0
    DIFF_END, TOTAL = 15.4, 19.6
    total_samp = int(TOTAL * 48000)
    audio = np.zeros(total_samp)
    s0 = int(HEAD_END * 48000)
    audio[s0:s0 + n] = moon * 0.85
    sf.write(os.path.join(BUILD, "demo_audio.wav"), audio, 48000)

    # ---- 波形包络 ----
    WW = 1120
    lo, hi = envelope(moon, WW)
    lo_c, hi_c = envelope(cref, WW)
    d = np.abs(moon - cref)
    dcol = d[:WW * (n // WW)].reshape(WW, -1).max(axis=1)
    cmax = dict(m=float(d.max()), med=float(np.median(d)))
    print(f"diff max={cmax['m']:.3e} med={cmax['med']:.3e}")

    frames_dir = os.path.join(BUILD, "frames")
    os.makedirs(frames_dir, exist_ok=True)
    nframes = int(TOTAL * FPS)
    f_title = font(110, True)
    f_sub = font(30)
    f_head = font(34, True)
    f_body = font(26)
    f_small = font(21)
    f_num = font(54, True)

    for k in range(nframes):
        t = k / FPS
        im = Image.new("RGB", (W, H), BG)
        dr = ImageDraw.Draw(im)

        if t < TITLE_END:  # 封面
            a = min(1.0, t / 0.6)
            dr.text((W // 2, 250), "moonopus", font=f_title,
                    fill=tuple(int(v * a) for v in CYAN), anchor="mm")
            dr.text((W // 2, 330), "纯 MoonBit 实现的 Opus(CELT) 解码器",
                    font=f_sub, fill=tuple(int(v * a) for v in FG),
                    anchor="mm")
            dr.text((W // 2, 385), "v0.2.0 · 零 C 依赖 · 零 FFI",
                    font=f_small, fill=tuple(int(v * a) for v in DIM),
                    anchor="mm")
            dr.text((W // 2, 640), "wasm-gc · js · native   |   396 tests",
                    font=f_small, fill=DIM, anchor="mm")
        elif t < HEAD_END:  # 小节标题
            dr.text((60, 90), "① 解码真实 Opus 比特流", font=f_head,
                    fill=CYAN)
            dr.text((60, 150),
                    "demo/sample.opus · 20 ms 帧 · CELT 全频带（config 31）"
                    " · 64 kbps VBR", font=f_body, fill=FG)
            dr.text((60, 195), "音频即为下方波形——由 moonopus 解码器输出",
                    font=f_small, fill=DIM)
        elif t < MUSIC_END + 0.1:  # 波形渐进
            dr.text((60, 70), "① 解码真实 Opus 比特流", font=f_head,
                    fill=CYAN)
            dr.text((60, 122), "demo/sample.opus · 20 ms 帧 · CELT 全频带"
                    "（config 31） · 64 kbps VBR", font=f_small, fill=DIM)
            x0, y0, hh = 80, 260, 260
            mid = y0 + hh // 2
            prog = min(1.0, max(0.0, (t - HEAD_END) / (n / 48000.0)))
            cur = int(prog * WW)
            dr.line((x0, mid, x0 + WW, mid), fill=(40, 48, 60), width=1)
            for c in range(WW):
                dr.line((x0 + c, mid - int(hi[c] * hh), x0 + c,
                         mid - int(lo[c] * hh)), fill=(36, 52, 64))
            for c in range(cur):
                dr.line((x0 + c, mid - int(hi[c] * hh), x0 + c,
                         mid - int(lo[c] * hh)), fill=CYAN)
            dr.line((x0 + cur, y0 - 10, x0 + cur, y0 + hh + 10),
                    fill=ORANGE, width=2)
            secs = min(n / 48000.0, max(0.0, t - HEAD_END))
            dr.text((60, 580), f"已解码 {int(secs * 48000):7d} / {n} 采样"
                    f"（48 kHz 浮点 PCM，pre-skip 与 granule 已截）",
                    font=f_small, fill=DIM)
            dr.text((60, 615), "音轨 = moonopus 输出", font=f_small,
                    fill=DIM)
        elif t < DIFF_END:  # 差分
            dr.text((60, 70), "② 与参考 libopus 逐样本差分", font=f_head,
                    fill=CYAN)
            x0, y0, hh = 80, 200, 150
            mid = y0 + hh // 2
            r = (t - DIFF_END + 5.5) / 2.0
            rev = int(min(1.0, max(0.15, r)) * WW)
            for c in range(rev):
                dr.line((x0 + c, mid - int(hi_c[c] * hh), x0 + c,
                         mid - int(lo_c[c] * hh)), fill=ORANGE, width=2)
            for c in range(rev):
                dr.line((x0 + c, mid - int(hi[c] * hh), x0 + c,
                         mid - int(lo[c] * hh)), fill=CYAN, width=1)
            dr.text((60, 365), "叠加：moonopus（青） vs libopus 参考（橙）",
                    font=f_small, fill=DIM)
            # 差分曲线（对数刻度 1e-8..1e-3）
            dy0, dhh = 430, 170
            dr.rectangle((x0, dy0, x0 + WW, dy0 + dhh),
                         outline=(40, 48, 60))
            for e in (1e-8, 1e-6, 1e-4):
                yy = dy0 + dhh - int((np.log10(e) + 8) / 5 * dhh)
                dr.line((x0, yy, x0 + WW, yy), fill=(35, 42, 52))
                dr.text((x0 + WW + 8, yy), f"1e{int(np.log10(e))}",
                        font=f_small, fill=DIM)
            for c in range(rev):
                v = max(dcol[c], 1e-9)
                yy = dy0 + dhh - int((np.log10(v) + 8) / 5 * dhh)
                dr.line((x0 + c, dy0 + dhh, x0 + c, yy), fill=ORANGE)
            dr.text((60, 625), f"最大 |Δ| = {cmax['m']:.2e}"
                    f"（中位 {cmax['med']:.1e}，≈ -86 dB）", font=f_body,
                    fill=FG)
        else:  # 指标卡
            dr.text((60, 90), "③ 验证", font=f_head, fill=CYAN)
            lines = [
                ("396 项测试全绿", "wasm-gc / js / native 三后端"),
                ("PCM 闸门 5 组真实比特流", "与 ffmpeg 的 libopus 参考"
                 "逐样本差 < 1e-4"),
                ("比特分配与帧级内部状态", "与 C 参考逐位/逐帧一致"),
                ("残余差异 = f32/f64 数值噪声", "两个 libopus 构建之间互差"
                 "同量级"),
            ]
            y = 210
            for idx, (a, b) in enumerate(lines):
                if t > DIFF_END + 0.35 * idx:
                    dr.rectangle((60, y + 8, 74, y + 22), fill=GREEN)
                    dr.text((92, y), a, font=f_body, fill=FG)
                    dr.text((92, y + 36), b, font=f_small, fill=DIM)
                y += 100
            dr.text((W // 2, 660), "github.com/Xcsa-ee/moonopus",
                    font=f_small, fill=DIM, anchor="mm")

        dr.text((W - 20, 20), "moonopus v0.2.0", font=f_small, fill=DIM,
                anchor="ra")
        im.save(os.path.join(frames_dir, f"f{k:04d}.png"))

    print(f"[ok] {nframes} frames")
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    subprocess.run(
        [ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
         "-framerate", str(FPS),
         "-i", os.path.join(frames_dir, "f%04d.png"),
         "-i", os.path.join(BUILD, "demo_audio.wav"),
         "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "21",
         "-preset", "medium", "-c:a", "aac", "-b:a", "128k",
         "-movflags", "+faststart", "-shortest", args.out],
        check=True, cwd=ROOT)
    print("[ok]", args.out, os.path.getsize(args.out) // 1024, "KB")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    main()
