// celt_exp_rotation.mbt
//
// 展宽旋转（RFC 6716 §4.3.4.3）：PVQ 码字解码并归一化之后，把能量沿频轴
// 抹开，避免音调状的人工痕迹。只实现解码方向。
//
// 每带一次，三个部分：
//   1. 增益 g = n / (n + f_r·k)，f_r 取 Table 59（spread 1/2/3 → 15/10/5），
//      旋转角 θ = π·g²/4；
//   2. 每块 ≥ 8 样本（n ≥ 8b）时，先在每块内按 stride = round(sqrt(n/b))
//      交错地转 (π/2 − θ)——参考实现用 (s, c) 作系数，即 cos(π/2−θ)=sinθ、
//      sin(π/2−θ)=cosθ；
//   3. 再做 RFC 列出的主扫描：成对 (i, i+stride) 从头扫到尾，再从
//     n−2·stride−1 回扫到 0。
// 按时间块分段，块间互不影响。
//
// 两处取舍都照参考实现（最终以与 libopus 的 PCM 差分为准）：
//   - spread=0 或 2k ≥ n 时整个跳过。前者是 RFC Table 59 的「不旋转」，
//     后者是参考实现的早退，RFC 正文没写这条件；
//   - 参考实现解码端的逐对映射是 RFC 公式 (c·x_i + s·x_j, −s·x_i + c·x_j)
//     的转置（其编码端恰为 RFC 公式，两端互逆）。本函数照抄参考解码端的
//     系数摆法，注释里的矩阵即实际执行的那一个。
//
// 数值用双精度。参考实现是 float32（gain/theta 先落 f32 再算三角），两边
// 由此差约 1e-7 相对量，留给最终 PCM 差分统一兜底。

///|
/// 对带向量原地施加展宽旋转。`x` 长度 n ≥ 2，`b` 是该带的时间块数，
/// `k` 是脉冲数，`spread` ∈ 0..3（由 celt_decode_spread 的 icdf 解码保证）。
///
/// 调用方保证 k ≥ 1 且 n 是 b 的倍数——与参考实现相同：前者由
/// alg_unquant 的断言兜底，后者由带结构保证（参考实现直接整除截断）。
pub fn celt_exp_rotation(
  x : Array[Double],
  b : Int,
  k : Int,
  spread : Int,
) -> Unit {
  let n = x.length()
  if spread == 0 || 2 * k >= n {
    return
  }
  // Table 59 的 f_r。spread 由 icdf 解码限定在 0..3，0 已在上面早退，
  // 这里 1/2/3 各对应一档，档位之外按最高档兜底（不可达）。
  let factor = if spread >= 3 { 5 } else if spread >= 2 { 10 } else { 15 }
  let g = n.to_double() / (n + factor * k).to_double()
  // θ = π·g²/4（RFC）。参考实现走 cos(π/2·g²/2) 与 cos(π/2·(1−g²/2)) 两条
  // 等价路径，金标交叉时应在舍入级吻合。
  let theta = @math.PI * g * g / 4.0
  let c = @math.cos(theta)
  let s = @math.sin(theta)
  // 交错相位的步长 stride2 = round(sqrt(n/b))，用参考实现的整数判据
  // (stride2²+stride2)·b + b/4 < n 逐次递增——等价于 (stride2+0.5)² < n/b。
  let mut stride2 = 0
  if n >= 8 * b {
    while (stride2 * stride2 + stride2) * b + (b >> 2) < n {
      stride2 = stride2 + 1
    }
  }
  let block = n / b
  for blk in 0..<b {
    let base = blk * block
    // 解码方向：交错相位在前（系数 (s,c)），主相位在后（系数 (c,s)）
    if stride2 > 0 {
      rot_pairs(x, base, block, stride2, s, c)
    }
    rot_pairs(x, base, block, 1, c, s)
  }
}

///|
/// 成对扫描：前向 i = 0..len−stride−1，回扫 i = len−2·stride−1..0，每对
/// (i, i+stride) 就地施加同一 2-D 旋转 [c −s; s c]（照参考实现
/// exp_rotation1 的系数摆法）。回扫起点为负时循环自然不进。
fn rot_pairs(
  x : Array[Double],
  off : Int,
  len : Int,
  stride : Int,
  c : Double,
  s : Double,
) -> Unit {
  let mut i = 0
  while i < len - stride {
    let x1 = x[off + i]
    let x2 = x[off + i + stride]
    x[off + i + stride] = c * x2 + s * x1
    x[off + i] = c * x1 - s * x2
    i = i + 1
  }
  let mut j = len - 2 * stride - 1
  while j >= 0 {
    let x1 = x[off + j]
    let x2 = x[off + j + stride]
    x[off + j + stride] = c * x2 + s * x1
    x[off + j] = c * x1 - s * x2
    j = j - 1
  }
}
