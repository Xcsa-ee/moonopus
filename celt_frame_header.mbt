// celt_frame_header.mbt
//
// CELT 帧首的四个符号（RFC 6716 Table 56 的前四项）：静音标志、pitch
// post-filter、瞬态标志、帧内能量标志。它们位于符号流最前面，任何一帧
// 解码都从这里开始；coarse energy 之后的 tf/spread 另有归属。
//
// 门控全部按「已解出的位数 vs 帧长」判断，单位是比特（1/8 bit 的换算从
// dynalloc 起才用）。参考实现用一个局部 tell 变量跟踪，这里必须照搬它——
// 不能直接读 dec.tell()：静音帧时参考实现把局部 tell 置为帧长，而
// ec_tell() 返回的是「帧长 − ilog(rng)」，两者差着 ilog(rng) 位，拿
// dec.tell() 去判门控会把本该跳过的符号放进来。
//
// 静音帧的处理是「假装读完」：位计数一次推到帧长而不消费任何比特，于是
// 后续几个符号的门控全部落空、一个都不读（§4.3.7 的语义与参考实现的
// nbits_total += tell - ec_tell() 一致）。

///|
/// 帧首四个符号的解码结果。
pub struct CeltFrameHeader {
  /// 静音帧：本帧其余符号一个都不读，输出置静音
  silence : Bool
  /// pitch post-filter 是否启用
  postfilter_on : Bool
  /// 后滤波周期，§4.3.7.1 规定落在 15..1022；未启用时为 0
  postfilter_pitch : Int
  /// 后滤波增益 G = 3*(int_gain+1)/32；未启用时为 0
  postfilter_gain : Double
  /// 后滤波 tapset 索引 0..2；未启用时为 0
  postfilter_tapset : Int
  /// 瞬态帧：切到短块
  is_transient : Bool
  /// 帧内能量：粗能量不预测上一帧
  intra : Bool
}

///|
/// 解帧首四个符号。
///
/// `frame_bytes` 是本帧载荷字节数（决定各项门控），`start` 是编码起始带
/// （单声道正常流为 0，Hybrid 模式为 17），`lm` 是帧长索引——2.5ms 帧
/// （LM=0）没有瞬态标志，因为已经是短块了。
///
/// 范围解码器会被推进，顺序与帧内其它符号一致。
pub fn celt_decode_frame_header(
  dec : RangeDecoder,
  frame_bytes : Int,
  start : Int,
  lm : Int,
) -> CeltFrameHeader {
  let total_bits = frame_bytes * 8

  // silence：{32767, 1}/32768，即 logp=15 的低概率分支
  let mut silence = false
  let mut tell = dec.tell()
  if tell >= total_bits {
    silence = true
  } else if tell == 1 {
    silence = dec.decode_bit_logp(15) != 0
  }
  if silence {
    // 局部 tell 置为帧长（不是 ec_tell()），位计数一次推过去、不消费比特
    tell = total_bits
    dec.skip_bits_to(total_bits)
  }

  // pitch post-filter：{1, 1}/2 的开关，之后是一串条件符号
  let mut postfilter_on = false
  let mut pitch = 0
  let mut gain = 0.0
  let mut tapset = 0
  if start == 0 && tell + 16 <= total_bits {
    if dec.decode_bit_logp(1) != 0 {
      postfilter_on = true
      // octave 为 0..5（ec_dec_uint 的 6 是 ft 而非上界），故
      // 4+octave 最多 9 个 raw bit，16<<octave 最多 512，都不会溢出
      let octave = dec.decode_uint(6)
      pitch = (16 << octave) + dec.dec_bits(4 + octave) - 1
      let qg = dec.dec_bits(3)
      gain = 3.0 * (qg + 1).to_double() / 32.0
      if dec.tell() + 2 <= total_bits {
        tapset = dec.decode_icdf(cel_tapset_icdf, 2)
      }
    }
    tell = dec.tell()
  }

  // transient：{7, 1}/8；2.5ms 帧本身已是短块，没有这个标志
  let mut is_transient = false
  if lm > 0 && tell + 3 <= total_bits {
    is_transient = dec.decode_bit_logp(3) != 0
    tell = dec.tell()
  }

  // intra：{7, 1}/8
  let mut intra = false
  if tell + 3 <= total_bits {
    intra = dec.decode_bit_logp(3) != 0
  }

  CeltFrameHeader::{
    silence,
    postfilter_on,
    postfilter_pitch: pitch,
    postfilter_gain: gain,
    postfilter_tapset: tapset,
    is_transient,
    intra,
  }
}
