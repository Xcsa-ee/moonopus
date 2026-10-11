# demo 视频复现

`docs/demo.mp4`（19.6 秒）用这里两个脚本生成。依赖：

- MoonBit 工具链、仓库自带的 `cmd/main` 示例；
- Python：`numpy`、`soundfile`、`Pillow`；
- 带 libopus / libx264 / aac 的 ffmpeg（先找 `../_ffmpeg/_bin/`，否则 PATH）。

## 复现视频

```bash
# 1. 本库全精度 PCM（f32le）
moon run cmd/main -- demo/sample.opus _build/demo/moon.f32

# 2. 渲染逐帧画面 + 参考差分 + 合成（输出 docs/demo.mp4）
python tools/demo/make_video.py
```

参考解码（ffmpeg+libopus 解 `demo/sample.opus`）由脚本现场生成到
`_build/demo/ref.f32`，无需其他素材。中间产物（帧 PNG、音轨 WAV）都在
`_build/demo/`。

与已提交视频的差异：提交版用本机 coracle 导出的 C 参考（对齐偏移 312 样本，
差分指标 max 4.9e-5 / 中位 1.3e-8），其参考流不随仓库分发；本脚本默认用
ffmpeg+libopus 参考（偏移 0，max ≈5.9e-5 / 中位 ≈8.3e-6），二者都在两个
libopus 构建彼此的差异带内。若手头有旧版 C 参考流：

```bash
python tools/demo/make_video.py --ref path/to/demo_tune_c.f32 --ref-shift 312
```

字体按「Windows 微软雅黑 → Noto CJK → 文泉驿 → 苹方」探测，或用
`MOONOPUS_FONT`（及 `MOONOPUS_FONT_BOLD`）指定。

## 更换演示素材（不常用）

`make_opus.py` 合成一段确定性旋律并用 ffmpeg(libopus) 编码为 CELT 全频带
20 ms VBR 流，产物在 `_build/demo/`。仓库已带现成的 `demo/sample.opus`，
只有更换素材时才跑它，然后把 `demo_tune.opus` 复制到 `demo/sample.opus`：

```bash
python tools/demo/make_opus.py
```
