# moonopus

纯 MoonBit 实现的 Opus 音频解码库：零 C 依赖、零 FFI，可编译到 wasm-gc、js 与 native。

> **当前状态：进行中。** 已完成 Ogg Opus 容器解封装（RFC 7845：页解析、跨页
> packet 重组、OpusHead/OpusTags 解析与页序校验）；音频解码（RFC 6716 的
> SILK / CELT）仍在开发中，尚未提供 PCM 输出。

## 功能

- Ogg 容器解封装：页 CRC 校验、lacing 规则、跨页 packet 重组
- RFC 7845 合规校验：BOS/EOS、页序号、continued 一致性、granule 规则、
  链式流拒绝、OpusHead 各字段合法域
- `OpusHead` / `OpusTags` 解析：声道、pre-skip、输入采样率、输出增益、
  映射族与声道映射表、vendor 与 comments 元数据

## 用法

`moon.pkg` 中引入依赖：

```text
import {
  "Xcsa-ee/moonopus",
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

## 开发

```bash
moon test --target wasm-gc   # 运行测试
moon test --target js
python tools/gen_fixtures.py # 重新生成测试样例（测试页由独立实现构造）
```

## 许可证

Apache-2.0
