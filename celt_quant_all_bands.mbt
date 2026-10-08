// celt_quant_all_bands.mbt
//
// quant_all_bands 主循环（RFC 6716 §4.3.4 Shape Decoding），单声道解码。
//
// 对应参考实现 celt_bands.c 的 quant_all_bands 解码侧：逐带做位数
// 记账（balance/curr_balance/budget 三重夹逼），维护折叠源缓冲 norm
// （各带经 lowband_out 写入 ×√N0 的预缩放谱），按保守 cm 估计决定
// 本带 fill 与折叠源，再调 celt_quant_band 完成带内解码，最后聚合
// 每带 collapse mask 并跨带线程 lcg seed。
//
// 立体声（dual_stereo/intensity/quant_band_stereo）与 qext 分支不在此
// 范围：CELT-only 单声道路径里 Y 恒空、intensity 不参与；effEBands
// 恒等于 nbEBands，故 `i>=effEBands` 的 norm 重定向是死分支（注释
// 对应处保留判定说明）。lowband_scratch 的等价性：本实现的折叠源与
// 频谱都走带内数组（天然无别名），参考实现的 scratch 复制只是在别名
// 时达到同一效果。

///|
/// 单声道主循环。`x` 是帧频谱（长度 m*120，带区就地读写），`pulses`
/// 是分配结果（1/8 bit），`tf_res` 是每带 TF 决策（-3..3），`total_bits`
/// 是帧预算（1/8 bit），`masks` 写入每带 collapse mask（长度 ≥ end）。
/// 返回推进后的 seed。
pub fn celt_quant_all_bands(
  dec : RangeDecoder,
  x : Array[Double],
  start : Int,
  end : Int,
  lm : Int,
  short_blocks : Bool,
  pulses : Array[Int],
  tf_res : Array[Int],
  coded_bands : Int,
  total_bits : Int,
  balance : Int,
  spread : Int,
  seed : Int64,
  masks : Array[Int],
) -> Int64 {
  let m = 1 << lm
  let blocks = if short_blocks { m } else { 1 }
  let norm_offset = celt_eband(start, m)
  // 折叠源缓冲：与参考实现同尺寸（末带的 lowband_out 为 NULL 不越界）
  let norm : Array[Double] = Array::make(
    celt_eband(CEL_NB_EBANDS - 1, m) - norm_offset,
    0.0,
  )
  let mut lowband_offset = 0
  let mut update_lowband = true
  let mut bal = balance
  let mut rng = seed
  for i in start..<end {
    let last = i == end - 1
    let n = celt_band_bins(i, m)
    let tell = dec.tell_frac()
    if i != start {
      bal -= tell
    }
    let remaining_bits = total_bits - tell - 1
    let mut b = 0
    if i <= coded_bands - 1 {
      let denom = if coded_bands - i < 3 { coded_bands - i } else { 3 }
      let curr = celt_sudiv(bal, denom)
      let t1 = pulses[i] + curr
      let t2 = if remaining_bits + 1 < t1 { remaining_bits + 1 } else { t1 }
      b = if t2 < 0 { 0 } else if t2 > 16383 { 16383 } else { t2 }
    } else {
      b = 0
    }
    // 草案更新的折叠位置推进（解码恒 resynth=1；CELT-only 起始对
    // 等宽时 special_hybrid_folding 的拷贝长度为 0）
    let cond1 = celt_eband(i, m) - n >= celt_eband(start, m) || i == start + 1
    if cond1 && (update_lowband || lowband_offset == 0) {
      lowband_offset = i
    }
    if i == start + 1 {
      let n1 = celt_band_bins(start, m)
      let n2 = celt_band_bins(start + 1, m)
      let ln = n2 - n1
      if ln > 0 {
        for j in 0..<ln {
          norm[n1 + j] = norm[2 * n1 - n2 + j]
        }
      }
    }
    let tf_change = tf_res[i]
    // 保守 cm 估计：折叠源覆盖的各带 mask 按位或作为本带 fill
    let mut effective = -1
    let mut x_cm = 0
    if lowband_offset != 0 && (spread != 3 || blocks > 1 || tf_change < 0) {
      effective = celt_eband(lowband_offset, m) - norm_offset - n
      if effective < 0 {
        effective = 0
      }
      let t_lo = effective + norm_offset
      let mut fold_start = lowband_offset - 1
      while celt_eband(fold_start, m) > t_lo {
        fold_start -= 1
      }
      let mut fold_end = lowband_offset - 1
      while fold_end + 1 < i && celt_eband(fold_end + 1, m) < t_lo + n {
        fold_end += 1
      }
      let mut f = fold_start
      while f < fold_end {
        x_cm = x_cm | masks[f]
        f += 1
      }
    } else {
      x_cm = (1 << blocks) - 1
    }
    // 带内数组：频谱、折叠源切片、折叠预缩放输出
    let x_off = celt_eband(i, m)
    let x_band : Array[Double] = Array::make(n, 0.0)
    for j in 0..<n {
      x_band[j] = x[x_off + j]
    }
    let lb_band : Array[Double] = if effective >= 0 {
      let a : Array[Double] = Array::make(n, 0.0)
      for j in 0..<n {
        a[j] = norm[effective + j]
      }
      a
    } else {
      []
    }
    let lo_out : Array[Double] = if last { [] } else { Array::make(n, 0.0) }
    let (cm, seed2, _) = celt_quant_band(
      dec, x_band, lb_band, i, lm, n, b, blocks, tf_change, x_cm, 1.0, spread, rng,
      remaining_bits, lo_out,
    )
    rng = seed2
    for j in 0..<n {
      x[x_off + j] = x_band[j]
    }
    if effective >= 0 {
      // 镜像参考实现对 norm 的就地前向变换副作用（后续带可能再折叠到）
      for j in 0..<n {
        norm[effective + j] = lb_band[j]
      }
    }
    if lo_out.length() > 0 {
      let pos = celt_eband(i, m) - norm_offset
      for j in 0..<n {
        norm[pos + j] = lo_out[j]
      }
    }
    masks[i] = cm
    bal += pulses[i] + tell
    update_lowband = b > n << CEL_BITRES
  }
  rng
}
