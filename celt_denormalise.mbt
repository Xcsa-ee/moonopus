// celt_denormalise.mbt
//
// 反归一化（RFC 6716 §4.3.6）：把各带的归一化形状与解码出的能量合成为
// 实际频谱，是频域链的最后一段，结果直接交给逆 MDCT。
//
// 每带一个标量增益：
//
//     lg = band_log_e[i] + eMeans[i]     §4.3.2 的能量状态 + 该带平均能量
//     g  = 2^lg                          上限 lg ≤ 32
//     freq[j] = x[j] * g                 eBands[i] ≤ j < eBands[i+1]
//
// RFC 正文只说「乘以解码能量的平方根」，没给式子。2^lg 由参考实现定死，
// 两处缺一不可：
//   - float 构建下 celt_exp2_db 就是 celt_exp2，即 2^x（celt/mathops.h），
//     没有额外的倍乘；
//   - band_log_e + eMeans 存的是**幅度** bandE = sqrt(Σx²) 的 log2，不是
//     能量本身的 log2（celt/bands.c 的 compute_band_energies 注释写的是
//     "Compute the amplitude (sqrt energy) in each of the bands"）。
// 两者相乘恰好得到 sqrt(能量)，与 RFC 的说法一致。参考实现里那句
// 「bandE[] being Q12 but celt_log2() taking a Q14 input」的 +2 补偿位于
// #ifdef FIXED_POINT 之内，浮点构建不走。
//
// band end 之后到 N、以及 start 之前的 bin一律为 0——本函数从零数组起步，
// 只写活跃区间，两处置零因此是结构性的。只实现原生采样率路径：参考实现
// 的 downsample 参数在这条路径上恒为 1，不存在收紧上界的那一步。

///|
/// 反归一化。`x` 是各带单位能量的形状（§4.3.4 的输出），`band_log_e` 是
/// §4.3.2 解出的能量状态，两者与返回值的长度都是 `m * 120`（带外部分为
/// 未使用的占位 0）。
pub fn celt_denormalise(
  x : Array[Double],
  band_log_e : Array[Double],
  start : Int,
  end : Int,
  m : Int,
  silence : Bool,
) -> Array[Double] {
  let freq = Array::make(m * CEL_SHORT_MDCT, 0.0)
  if !silence {
    for i in start..<end {
      let lg = band_log_e[i] + cel_e_means[i]
      // 上限 32 是参考实现对损坏码流的保护：lg 再大，2^lg 会溢出成 inf，
      // 乘到形状上变成 inf/NaN 后会扩散进整段时域输出。
      let g = @math.pow(2.0, if lg > 32.0 { 32.0 } else { lg })
      let band_end = celt_eband(i + 1, m)
      for j in celt_eband(i, m)..<band_end {
        freq[j] = x[j] * g
      }
    }
  }
  freq
}
