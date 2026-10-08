// celt_pulse_cache.mbt
//
// 位数↔脉冲换算与脉冲缓存（RFC 6716 §4.3.4.1 Bits to Pulses）。
//
// 解码端从比特分配拿到的是 1/8 bit 单位的每带位数，PVQ 解码需要的是
// 伪脉冲索引（决定 V(N,K) 的 K）——两者按缓存表换算：
//
//   - cel_cache_index50 / cel_cache_bits50（celt_tables.mbt）是标准
//     48 kHz 模式的静态缓存产物，行 = LM+1、列 = 带号；条目首槽是
//     Kmax，其后 j=1..Kmax 槽存 位数(get_pulses(j))−1；
//   - celt_bits2pulses 是定次 6 轮二分加 tie-break，逐行对应参考实现
//     rate.h 的同名函数：解码必须与其同结果，平台段上平局端点的选择
//     会改变 K，进而改变 PVQ 解出的矢量；
//   - celt_pulses2bits 反向查表，0 个脉冲恒为 0。
//
// 标准构建不走运行时 compute_pulse_cache：参考实现同样直接用静态表。

///|
/// 伪脉冲索引的最大值（rate.h 的 MAX_PSEUDO），也是条目 Kmax 的上限。
pub const CEL_MAX_PSEUDO : Int = 40

///|
/// celt_bits2pulses 定次二分的轮数（rate.h 的 LOG_MAX_PSEUDO）。
const CEL_LOG_MAX_PSEUDO : Int = 6

///|
/// 伪脉冲索引 → 实际脉冲数（rate.h 的 get_pulses）。
///
/// 0..7 原样；8 起每 8 个索引一档，档内取低 3 位线性递增，档号减 1 作
/// 左移量：8..15 → 8,9,...,15；16..23 → 16,18,...,30；末端 40 → 128。
pub fn celt_get_pulses(i : Int) -> Int {
  if i < 8 {
    i
  } else {
    (8 + (i & 7)) << ((i >> 3) - 1)
  }
}

///|
/// 位数（1/8 bit）→ 伪脉冲索引（§4.3.4.1，rate.h 的 bits2pulses）。
///
/// 查表行 = LM+1（解码 lm∈0..3 落在表行 1..4，行 0 只参与条目去重）。
/// 输入位数先减 1 与表内「位数−1」的存法对齐，再做固定 6 轮二分夹逼；
/// 收尾 tie-break 在 lo/hi 间取距离更小的一端，距离相等取 lo（`<=`）。
pub fn celt_bits2pulses(band : Int, lm : Int, bits : Int) -> Int {
  let off = cel_cache_index50[(lm + 1) * CEL_NB_EBANDS + band]
  let mut lo = 0
  let mut hi = cel_cache_bits50[off].to_int()
  let b = bits - 1
  for _ in 0..<CEL_LOG_MAX_PSEUDO {
    let mid = (lo + hi + 1) >> 1
    if cel_cache_bits50[off + mid].to_int() >= b {
      hi = mid
    } else {
      lo = mid
    }
  }
  let clo = if lo == 0 { -1 } else { cel_cache_bits50[off + lo].to_int() }
  if b - clo <= cel_cache_bits50[off + hi].to_int() - b {
    lo
  } else {
    hi
  }
}

///|
/// 伪脉冲索引 → 位数（1/8 bit）（§4.3.4.1，rate.h 的 pulses2bits）。
///
/// 0 个脉冲恒为 0；其余查条目的第 q 槽再加 1（表内存的是「位数−1」）。
pub fn celt_pulses2bits(band : Int, lm : Int, pulses : Int) -> Int {
  let off = cel_cache_index50[(lm + 1) * CEL_NB_EBANDS + band]
  if pulses == 0 {
    0
  } else {
    cel_cache_bits50[off + pulses].to_int() + 1
  }
}
