// celt_alloc_flags.mbt
//
// 比特分配之前的两个标志（RFC 6716 §4.3.3）：band boost（dynalloc）与
// allocation trim。它们的产出正是 celt_compute_allocation 的两个输入
// （offsets 与 alloc_trim），所以在帧解码里紧接在 tf / spread 之后、
// 分配之前。
//
// 符号顺序：带内 boost 是一串极低概率的二元符号——首带首次 boost 要 6 bit，
// 之后每次降到 1 bit，同时把该带的初始成本往下压（最低 2 bit）；trim 是
// 11 个符号的 icdf，默认 5 表示不加不减，且受门控（预算不够就不读）。
//
// 循环条件按参考实现取**递减后的** total_bits。RFC 正文的字面是
// 「total_bits + total_boost」，因每次 boost 同时让 total_bits 减 quanta、
// total_boost 加 quanta，那个和恒等于帧长——两种写法不同。此处跟参考实现
// 一致（真实比特流由参考实现的编码器产生，解码必须与之对齐）；trim 的
// 门控两种理解下等价，因为门控用的正是这个递减后的值。

///|
/// 分配相关的两个标志。
pub struct CeltAllocFlags {
  /// 每带的 boost 加成，单位 1/8 bit（长度 21，窗外为 0）
  offsets : Array[Int]
  /// 分配倾斜，0..10；5 表示不加不减，<5 偏低频、>5 偏高频
  alloc_trim : Int
}

///|
/// 解 band boost 与 allocation trim。
///
/// `cap` 由 `celt_init_caps` 给出，`frame_bytes` 是本帧载荷字节数（决定
/// 预算与门控），`lm` 是帧长索引（决定每带的 boost 步长）。
/// 范围解码器会被推进，顺序与帧内其它符号一致。
pub fn celt_decode_alloc_flags(
  dec : RangeDecoder,
  start : Int,
  end : Int,
  cap : Array[Int],
  frame_bytes : Int,
  lm : Int,
) -> CeltAllocFlags {
  let offsets = Array::make(CEL_NB_EBANDS, 0)
  // 预算与门控都按 1/8 bit 计；循环里每 boost 一次就扣掉 quanta
  let mut total_bits = frame_bytes * 8 * (1 << CEL_BITRES)
  let mut tell = dec.tell_frac()
  let mut dynalloc_logp = 6

  for i in start..<end {
    // boost 步长：6 bit/步，但下限 1/8 bit/样本、上限 1 bit/样本
    let width = celt_band_bins(i, 1 << lm)
    let lo = if 48 > width { 48 } else { width }
    let wide = width << CEL_BITRES
    let quanta = if wide < lo { wide } else { lo }

    let mut loop_logp = dynalloc_logp
    let mut boost = 0
    let mut again = true
    while again &&
          tell + (loop_logp << CEL_BITRES) < total_bits &&
          boost < cap[i] {
      let flag = dec.decode_bit_logp(loop_logp)
      tell = dec.tell_frac()
      if flag == 0 {
        again = false
      } else {
        boost += quanta
        total_bits -= quanta
        // 首次 boost 之后，本带后续的 boost 只花 1 bit
        loop_logp = 1
      }
    }
    offsets[i] = boost
    // 动过 boost 的带，下一个带的初始成本降一档（最低 2 bit）
    if boost > 0 && dynalloc_logp > 2 {
      dynalloc_logp -= 1
    }
  }

  // §4.3.3：预算不够就把 trim 留在默认值 5，不读符号
  let mut alloc_trim = 5
  if tell + (6 << CEL_BITRES) <= total_bits {
    alloc_trim = dec.decode_icdf(cel_trim_icdf, 7)
  }
  CeltAllocFlags::{ offsets, alloc_trim, }
}
