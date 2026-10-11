# -*- coding: utf-8 -*-
"""demo 视频素材：合成旋律 -> demo_tune.opus（CELT 全频带 config 28..31）。

产出（均在 _build/demo/）：
  demo_tune.wav   源波形（48 kHz 单声道）
  demo_tune.opus  ffmpeg(libopus) 编码，逐包 TOC 校验 CELT 全频带
  demo_tune.f32   ffmpeg(libopus) 解码参考（f32le 原始流）

仓库已带现成素材 demo/sample.opus（即 demo_tune.opus 的提交副本），
仅在想更换演示素材时才需要重跑本脚本；重跑后把 demo_tune.opus
复制到 demo/sample.opus 即完成素材更新。
"""
import os
import sys

import numpy as np
import soundfile as sf
import struct

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
BUILD = os.path.join(ROOT, "_build", "demo")
sys.path.insert(0, os.path.join(ROOT, "tools"))
from gen_pcm_gate import (  # noqa: E402
    find_ffmpeg, encode, verify_celt_fb, decode_ref,
)

SR = 48000
DUR = 6.0


def melody():
    t = np.arange(int(SR * DUR)) / SR
    x = np.zeros_like(t)
    # 和弦进行 Am - F - C - G（每 3 s）
    chords = [
        (220.00, 261.63, 329.63),
        (174.61, 220.00, 261.63),
        (261.63, 329.63, 392.00),
        (196.00, 246.94, 293.66),
    ]
    for k, (f0, f1, f2) in enumerate(chords):
        seg = (t >= k * 3.0) & (t < (k + 1) * 3.0)
        tt = t[seg] - k * 3.0
        env = np.minimum(1.0, tt * 20.0) * np.exp(-tt * 0.7)
        x[seg] += 0.30 * np.sin(2 * np.pi * f0 * tt) * env
        x[seg] += 0.22 * np.sin(2 * np.pi * f1 * tt) * env
        x[seg] += 0.15 * np.sin(2 * np.pi * f2 * tt) * env
    # 琶音旋律（八分音符网格，带二次谐波与柔和包络）
    scale = [440.0, 523.25, 659.25, 783.99, 659.25, 523.25, 587.33, 493.88]
    step = 0.25
    n = int(DUR / step)
    for i in range(n):
        f = scale[i % len(scale)] * (2.0 if (i // 8) % 2 else 1.0)
        t0 = i * step
        seg = (t >= t0) & (t < t0 + step)
        tt = t[seg] - t0
        env = np.minimum(1.0, tt * 60.0) * np.exp(-tt * 6.5)
        x[seg] += 0.22 * np.sin(2 * np.pi * f * tt) * env
        x[seg] += 0.06 * np.sin(4 * np.pi * f * tt) * env
    return np.clip(x * 0.9, -0.95, 0.95).astype(np.float32)


def main():
    ffmpeg = find_ffmpeg()
    os.makedirs(BUILD, exist_ok=True)
    wav = os.path.join(BUILD, "demo_tune.wav")
    opus = os.path.join(BUILD, "demo_tune.opus")
    raw = os.path.join(BUILD, "demo_tune.f32")
    sf.write(wav, melody(), SR, subtype="PCM_16")
    attempts = [("64k", "on", None), ("96k", "on", None),
                ("160k", "on", "lowdelay")]
    bad = "未尝试"
    for br, vr, app in attempts:
        encode(ffmpeg, wav, opus, 20, br, vr, app)
        configs, codes, stereo, bad = verify_celt_fb(opus)
        print(f"  try {br} vbr={vr} app={app}: configs={sorted(configs)} "
              f"codes={sorted(codes)} bad={bad}")
        if bad is None:
            break
    if bad:
        raise SystemExit(f"非 CELT 全频带：{bad}")
    ref = decode_ref(ffmpeg, opus, raw)
    size = os.path.getsize(opus)
    print(f"[ok] {size}B opus, ref {len(ref)} samples, "
          f"configs={sorted(configs)}, codes={sorted(codes)}")


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    main()
