// celt_tf_spread.mbt
//
// 每带 TF 分辨率调整与频谱扩展决策（RFC 6716 §4.3.1 与 Table 56）。
// 它们在符号流里紧邻——coarse energy 之后、dynalloc 之前，所以合在一个
// 文件里；补上这两项，从帧首到比特分配的整段符号流就接通了。
//
// TF 调整的两段：
//   1. 每带一个二元标志，把「当前分辨率」逐带翻转，记录是否变过；
//   2. tf_select 一位决定用表的哪一列——但只在**两列不同时**才读，读了也
//      没影响就省下这一位（§4.3.1 原文：only decoded if it can have an
//      impact on the result）。
// 最后按表把 0/1 重映射成实际的调整值（正数=更好的频率分辨率，负数=更好
// 的时间分辨率）。

///|
/// 门控不足时的默认频谱扩展强度（参考实现 celt/bands.h 的 SPREAD_NORMAL）。
///
/// 这个默认值同时被两件事印证：它是参考实现的初值，也是 RFC Table 56 的
/// PDF {7,2,21,2}/32 里概率最大的那个符号。
const CEL_SPREAD_NORMAL : Int = 2

///|
/// 解每带 TF 调整，返回长度 21 的调整值数组（窗外项恒为 0）。
///
/// `frame_bytes` 是本帧载荷字节数：tf_select 的预留位与逐带读取都由它把
/// 关。范围解码器会被推进，顺序与帧内其它符号一致。
pub fn celt_decode_tf(
  dec : RangeDecoder,
  start : Int,
  end : Int,
  is_transient : Bool,
  lm : Int,
  frame_bytes : Int,
) -> Array[Int] {
  let budget = frame_bytes * 8
  let is_t = if is_transient { 1 } else { 0 }
  let mut tell = dec.tell()
  // 第一带的翻转代价最低：transient 1/4、非 transient 1/16
  let mut logp = if is_transient { 2 } else { 4 }
  // tf_select 需要预留 1 bit，且 2.5ms 帧（LM=0）永远用不到它
  let tf_select_rsv = lm > 0 && tell + logp + 1 <= budget
  let budget = budget - (if tf_select_rsv { 1 } else { 0 })

  let mut tf_changed = 0
  let mut curr = 0
  let tf_res = Array::make(CEL_NB_EBANDS, 0)
  for i in start..<end {
    if tell + logp <= budget {
      // 位数不够的带不读符号，也就保持上一带的取值
      curr = curr ^ dec.decode_bit_logp(logp)
      tell = dec.tell()
      tf_changed = tf_changed | curr
    }
    tf_res[i] = curr
    // 首带之后翻转代价升高：transient 1/4、非 transient 1/32
    logp = if is_transient { 4 } else { 5 }
  }

  // 两列（tf_select=0 / 1）不同才有必要问这一位
  let base = lm * 8 + 4 * is_t
  let col0 = cel_tf_select_table[base + tf_changed]
  let col2 = cel_tf_select_table[base + 2 + tf_changed]
  let mut tf_select = 0
  if tf_select_rsv && col0 != col2 {
    tf_select = dec.decode_bit_logp(1)
  }

  for i in start..<end {
    tf_res[i] = cel_tf_select_table[base + 2 * tf_select + tf_res[i]]
  }
  tf_res
}

///|
/// 解频谱扩展决策，返回 0..3（NONE/LIGHT/NORMAL/AGGRESSIVE）。
///
/// `frame_bytes` 是本帧载荷字节数，位数不够就停在默认的 NORMAL——与编码
/// 端一致：门控失败意味着两端都不写这个符号。
pub fn celt_decode_spread(dec : RangeDecoder, frame_bytes : Int) -> Int {
  if dec.tell() + 4 <= frame_bytes * 8 {
    dec.decode_icdf(cel_spread_icdf, 5)
  } else {
    CEL_SPREAD_NORMAL
  }
}
