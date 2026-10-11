// cmd/main/main.mbt
//
// 命令行入口：读 .opus 文件 → decode_opus_pcm → 输出 16-bit PCM WAV。

///|
/// 把 48 kHz 单声道 Float PCM 序列化为 16-bit PCM WAV 字节。
/// 样本超出 [-1,1] 时截断，再四舍五入到 16 位有符号整数。
fn wav_encode_pcm16(pcm : Array[Double], sample_rate : Int) -> Bytes {
  let frames = pcm.length()
  let data_size = frames * 2
  let buf = @buffer.Buffer()
  // RIFF 头
  buf.write_bytes(b"RIFF")
  buf.write_uint_le((36 + data_size).reinterpret_as_uint())
  buf.write_bytes(b"WAVE")
  // fmt chunk
  buf.write_bytes(b"fmt ")
  buf.write_uint_le(16U)
  buf.write_uint16_le((1).to_uint16()) // PCM
  buf.write_uint16_le((1).to_uint16()) // 单声道
  buf.write_uint_le(sample_rate.reinterpret_as_uint())
  buf.write_uint_le((sample_rate * 2).reinterpret_as_uint()) // 字节率
  buf.write_uint16_le((2).to_uint16()) // block align
  buf.write_uint16_le((16).to_uint16()) // 位深
  // data chunk
  buf.write_bytes(b"data")
  buf.write_uint_le(data_size.reinterpret_as_uint())
  for f in 0..<frames {
    let c = pcm[f].clamp(min=-1.0, max=1.0)
    let v = (c * 32767.0).round().to_int()
    buf.write_int16_le(Int16::from_int(v))
  }
  buf.to_bytes()
}

///|
fn main {
  let args = @env.args()
  if args.length() < 2 {
    println("用法: moon run cmd/main -- <input.opus> [output.wav|.f32]")
    return
  }
  let input = args[1]
  let output = if args.length() >= 3 { args[2] } else { "\{input}.wav" }
  try {
    let data = @fs.read_file_to_bytes(input)
    match @moonopus.decode_opus_pcm(data) {
      Ok(pcm) => {
        println("解码成功: \{pcm.length()} 个样本 @ 48 kHz 单声道")
        let blob = if output.has_suffix(".f32") {
          // 原始 f32le（逐样本 little-endian 32 位浮点），供逐样本差分复现
          let buf = @buffer.Buffer()
          for i in 0..<pcm.length() {
            buf.write_uint_le(Float::from_double(pcm[i]).reinterpret_as_uint())
          }
          buf.to_bytes()
        } else {
          wav_encode_pcm16(pcm, 48000)
        }
        @fs.write_bytes_to_file(output, blob)
        println("已写入: \{output}")
      }
      Err(e) => println("解码失败: \{e}")
    }
  } catch {
    @fs.IOError::IOError(msg) => println("I/O 错误: \{msg}")
  }
}
