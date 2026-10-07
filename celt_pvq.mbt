// celt_pvq.mbt
//
// PVQ 脉冲解码（RFC 6716 §4.3.4.2）：把范围解码器里的均匀整数还原成一个
// 脉冲向量。这是 CELT 残差解码的第一步，后面还有 spreading、split、去重
// 与带内合成。
//
// 规范给了两条独立的东西，本文件都照做并各留一道测试：
//   1. V(N,K) 的递归定义——码字总数；
//   2. 下标还原向量的五步迭代——从码字下标走到具体向量。
// 规范明说实现可任选等价方法，这里用最直白的写法以便逐行对照。

///|
/// V(N,K)：K 个脉冲分配到 N 维的码字数（§4.3.4.2）。
///
/// 按规范递归 `V(N,K) = V(N-1,K) + V(N,K-1) + V(N-1,K-1)`，边界
/// `V(N,0)=1`、`V(0,K)=0 (K>0)`，动态规划逐行填表。
///
/// 返回行主序的一维表：`表[a*(k+1) + b]` = V(a,b)，其中 a ≤ n、b ≤ k。
/// 值用 Int64——码本按 32 bits 设计（§4.3.4.4 与 cwrs.c 注释），(96,5)
/// 这类组合就已越过 Int32 上限。
pub fn celt_pvq_v_table(n : Int, k : Int) -> Array[Int64] {
  let cols = k + 1
  let tab = Array::make((n + 1) * cols, 0L)
  // V(0,K)=0 (K>0) 已由初值给出；V(N,0)=1 对所有 N 单独置上
  for a in 0..<(n + 1) {
    tab[a * cols] = 1L
  }
  for a in 1..<(n + 1) {
    for b in 1..<cols {
      tab[a * cols + b] = tab[(a - 1) * cols + b] +
        tab[a * cols + b - 1] +
        tab[(a - 1) * cols + b - 1]
    }
  }
  tab
}

///|
/// 解一个 PVQ 脉冲向量：先按 V(N,K) 解出码字下标，再按 §4.3.4.2 的五步
/// 迭代把下标还原成向量。
///
/// `n` 是带的维数、`k` 是该带分到的脉冲数。返回长度 n 的向量，且
/// Σ|X| = k（脉冲数守恒，这是测试里的不变量）。
///
/// k=0 时码字唯一（全零向量），不读比特——参考实现同样断言 k>0 才进此
/// 函数，由外层负责 k=0 的情况。
pub fn celt_decode_pulses(dec : RangeDecoder, n : Int, k : Int) -> Array[Int] {
  if n <= 0 {
    return []
  }
  if k <= 0 {
    return Array::make(n, 0)
  }
  let cols = k + 1
  let tab = celt_pvq_v_table(n, k)
  let idx = dec.decode_uint64(tab[n * cols + k])
  celt_pvq_unindex(n, k, tab, idx)
}

///|
/// §4.3.4.2 的五步迭代：把码字下标还原成脉冲向量。
///
/// 单独抽出来是因为它是纯函数——下标由比特流决定，不经解码器就没法指定
/// 某个下标，而穷举所有下标正是验证脉冲数守恒的唯一办法。
///
/// `tab` 是 `celt_pvq_v_table(n, k)` 的结果，`idx` 应落在 `[0, V(n,k))`。
pub fn celt_pvq_unindex(
  n : Int,
  k : Int,
  tab : Array[Int64],
  idx : Int64,
) -> Array[Int] {
  let cols = k + 1
  let x = Array::make(n, 0)
  if n <= 0 || k <= 0 {
    return x
  }
  let mut idx = idx
  let mut kk = k
  for j in 0..<n {
    // 1. p = (V(n-j-1,k) + V(n-j,k)) / 2，整数除法向下取整
    let p0 = tab[(n - j - 1) * cols + kk]
    let mut p = (p0 + tab[(n - j) * cols + kk]) / 2
    // 2. 下标落在 p 之前为正号，之后为负号
    let mut sgn = 1
    if idx >= p {
      sgn = -1
      idx = idx - p
    }
    // 3. 退回 V(n-j-1,k0) 那一半，往下找 k
    let k0 = kk
    p = p - p0
    // 4. 逐级减 V(n-j-1,k) 直到 p 落到下标以内
    while p > idx && kk > 0 {
      kk = kk - 1
      p = p - tab[(n - j - 1) * cols + kk]
    }
    // 5. 本维的脉冲数就是 k0 与 kk 之差
    x[j] = sgn * (k0 - kk)
    idx = idx - p
  }
  x
}
