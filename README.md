# moonopus

纯 MoonBit 实现的 Opus 音频解码库：零 C 依赖、零 FFI，可编译到 wasm-gc、js 与 native。

> **当前状态：进行中。** 已完成 Ogg Opus 容器解封装（RFC 7845：页解析、跨页
> packet 重组、OpusHead/OpusTags 解析与页序校验）、音频包结构解析
> （RFC 6716 §3：TOC、code 0–3 帧打包、CBR/VBR、填充与畸形包分类）、
> CELT 频域解码全链（RFC 6716 §4.3，见下）与帧合成模块（IMDCT、基音梳状
> 滤波），各模块均以双独立实现金标交叉验证。合成链路的端到端接线仍在
> 进行，**尚未提供 PCM 输出**；解码范围为 CELT-only（SILK 与 hybrid
> 模式不在范围内）。

## 功能

- Ogg 容器解封装：页 CRC 校验、lacing 规则、跨页 packet 重组
- RFC 7845 合规校验：BOS/EOS、页序号、continued 一致性、granule 规则、
  链式流拒绝、OpusHead 各字段合法域
- `OpusHead` / `OpusTags` 解析：声道、pre-skip、输入采样率、输出增益、
  映射族与声道映射表、vendor 与 comments 元数据
- RFC 6716 §3 音频包结构：TOC 配置表（32 配置的模式/带宽/帧时长）、
  code 0–3 帧打包、单/双字节帧长编码、Opus 填充、按 [R1]–[R7] 对
  畸形包分类拒绝
- RFC 6716 §4.1 范围解码器（Opus 算术解码）
- RFC 6716 §4.3 CELT 频域解码：帧头与 TF 调整（§4.3.1 / Table 56）、
  能量包络（§4.3.2）、比特分配与 band boost（§4.3.3）、脉冲缓存
  （§4.3.4.1）、PVQ 脉冲解码（§4.3.4.2）、展宽旋转（§4.3.4.3）、
  递归分割（§4.3.4.4）、TF 变换（§4.3.4.5）、谱层量化解码主循环
  （§4.3.4）、反塌缩（§4.3.5）、反归一化（§4.3.6）、帧级解码主流程
- 帧合成模块：IMDCT 与重叠相加缓冲（§4.3.7）、基音梳状滤波（§4.3.7.1）

## 用法

`moon.pkg` 中引入依赖：

```text
import {
  "LL728/moonopus",
}
```

在代码中打开一个 `.opus` 字节流：

```moonbit
fn inspect(data : Bytes) {
  match @moonopus.open_opus(data) {
    Ok(stream) => println(
      "\{stream.channels()} ch, pre-skip \{stream.pre_skip()}, \{stream.packet_count()} audio packets",
    )
    Err(e) => println("not a valid Ogg Opus stream: \{e}")
  }
}
```

解析单个音频包的结构（RFC 6716 §3）：

```moonbit
fn inspect_packet(pkt : Bytes) {
  match @moonopus.parse_opus_packet(pkt) {
    Ok(p) => println(
      "config \{p.config()}: \{p.frame_count()} frame(s), \{p.duration_48k()} samples @48k",
    )
    Err(e) => println("malformed packet: \{e}")
  }
}
```

## 开发

```bash
moon test --target wasm-gc   # 运行测试
moon test --target js
python tools/gen_fixtures.py # 重新生成测试样例（测试页由独立实现构造）
```

## 许可证

Apache-2.0。比特分配等表数据提取自 [xiph/opus](https://github.com/xiph/opus)
参考实现（BSD-3-Clause，许可见 `LICENSE-LIBOPUS`），解码流程亦参考了该
实现与 RFC 6716。
