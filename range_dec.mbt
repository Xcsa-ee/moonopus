// range_dec.mbt
//
// RFC 6716 §4.1 范围解码器。这是 SILK 与 CELT 两层共用的熵解码底座。
//
// 实现严格对应规范文字：初始化（§4.1.1）、符号解码与更新（§4.1.2）、
// 重归一化（§4.1.2.1）、三类快路径（§4.1.3）、raw bits（§4.1.4）、
// 均匀整数（§4.1.5）、位用量（§4.1.6）。
//
// 状态量 val/rng 是 32 位无符号量（rng 可达 2**31），故用 Int64 承载，
// 并在规范要求掩码处显式掩码（§4.1.2.1 的 & 0x7FFFFFFF），避免依赖语言
// 的溢出行为。除法均为正数整除，与规范的 integer division 一致。
//
// 独立的 Python 参考端见 tools/gen_range_goldens.py，它产出的逐轨迹金标
// 用于比对本实现；端到端正确性另由真实 libopus 比特流的 PCM 差分兜底。

///|
/// 范围解码器状态。创建后即可连续解码，所有 mut 字段透过 self 引用更新。
pub struct RangeDecoder {
  data : Bytes
  nbytes : Int
  mut offs : Int
  mut leftover : Int
  mut val : Int64
  mut rng : Int64
  mut raw_read : Int
}

///|
/// 创建解码器并完成初始化与首轮重归一化（RFC §4.1.1）。
///
/// rng 置 128、val 置 127-(b0>>1)，首字节的最低位存为 leftover 供后续
/// 重归一化拼接；无输入时按 0 处理。
pub fn RangeDecoder::new(data : Bytes) -> RangeDecoder {
  let nbytes = data.length()
  let b0 = if nbytes > 0 { data.unsafe_get(0).to_int() } else { 0 }
  let decoder = RangeDecoder::{
    data,
    nbytes,
    offs: 1,
    leftover: b0 & 1,
    val: (127 - (b0 >> 1)).to_int64(),
    rng: 128L,
    raw_read: 0,
  }
  decoder.normalize()
  decoder
}

///|
/// 读取下一字节；超出输入末尾补 0（§4.1.2.1）。
fn RangeDecoder::next_byte(self : RangeDecoder) -> Int {
  let b = if self.offs < self.nbytes {
    self.data.unsafe_get(self.offs).to_int()
  } else {
    0
  }
  self.offs += 1
  b
}

///|
/// 重归一化：反复左移 rng 并读字节，直到 rng > 2**23（§4.1.2.1）。
///
/// sym 由上一字节存留位作最高位、本字节高 7 位拼成；本字节最低位存回
/// leftover。val 只在此处按规范掩码到 31 位。
fn RangeDecoder::normalize(self : RangeDecoder) -> Unit {
  while self.rng <= 8388608L { // 2**23
    self.rng = self.rng << 8
    let nb = self.next_byte()
    let sym = ((self.leftover << 7) | (nb >> 1)) & 0xFF
    self.leftover = nb & 1
    self.val = ((self.val << 8) + (255 - sym).to_int64()) & 0x7FFFFFFFL
  }
}

///|
/// ec_decode()：算出落在目标符号区间内的 16 位值 fs（§4.1.2）。
fn RangeDecoder::decode(self : RangeDecoder, ft : Int) -> Int {
  let d = self.rng / ft.to_int64()
  if d == 0L {
    return ft
  }
  let t = (self.val / d + 1L).to_int()
  ft - (if t < ft { t } else { ft })
}

///|
/// ec_dec_update()：按 (fl, fh, ft) 推进状态并重归一化（§4.1.2）。
fn RangeDecoder::update(
  self : RangeDecoder,
  fl : Int,
  fh : Int,
  ft : Int,
) -> Unit {
  let s = self.rng / ft.to_int64()
  if fl > 0 {
    self.val = self.val - s * (ft - fh).to_int64()
    self.rng = s * (fh - fl).to_int64()
  } else {
    self.rng = self.rng - s * (ft - fh).to_int64()
  }
  self.normalize()
}

///|
/// 解一个由频率数组描述的上下文，返回解出的符号 k（§4.1.2）。
///
/// `freqs[i]` 是符号 i 的频率，其和即 ft；fl/fh 由累计和推出，符号由
/// 比特流决定而非由调用方指定。fs 不落在任何符号区间时属实现错误。
pub fn RangeDecoder::decode_ctx(self : RangeDecoder, freqs : Array[Int]) -> Int {
  let mut ft = 0
  for f in freqs {
    ft += f
  }
  let fs = self.decode(ft)
  let mut fl = 0
  for i in 0..<freqs.length() {
    let fh = fl + freqs[i]
    if fl <= fs && fs < fh {
      self.update(fl, fh, ft)
      return i
    }
    fl = fh
  }
  abort("range decode: fs outside context")
}

///|
/// ec_dec_bit_logp()：解一个二元符号，logp 是「1」的 log2 概率（§4.1.3.2）。
pub fn RangeDecoder::decode_bit_logp(self : RangeDecoder, logp : Int) -> Int {
  let ft = 1 << logp
  let fs = self.decode(ft)
  if fs < ft - 1 {
    self.update(0, ft - 1, ft)
    0
  } else {
    self.update(ft - 1, ft, ft)
    1
  }
}

///|
/// ec_decode_bin()：返回 `fs = ec_decode(1<<ftb)`，**不更新状态**（§4.1.3.1）。
///
/// 调用方自行决定用哪个 (fl, fh, ft) 调 `update`——Laplace 解码正是先取
/// `fs` 再自行构造目标区间（见 §4.3.2 的能量解码）。这与
/// `decode_bit_logp`（decode+update 的二元快捷路径）是两回事。
pub fn RangeDecoder::decode_bin_fs(self : RangeDecoder, ftb : Int) -> Int {
  self.decode(1 << ftb)
}

///|
/// ec_dec_icdf()：用逆累积分布表解符号（§4.1.3.3）。
///
/// `icdf[k] = (1<<ftb) - fh[k]`，表以 0 结尾（对应 fh = ft）。搜索首个
/// 满足 `fs < (1<<ftb) - icdf[k]` 的 k。
pub fn RangeDecoder::decode_icdf(
  self : RangeDecoder,
  icdf : Array[Int],
  ftb : Int,
) -> Int {
  let ft = 1 << ftb
  let fs = self.decode(ft)
  let mut k = 0
  while k < icdf.length() - 1 && fs >= ft - icdf[k] {
    k += 1
  }
  let fl = if k == 0 { 0 } else { ft - icdf[k - 1] }
  let fh = ft - icdf[k]
  self.update(fl, fh, ft)
  k
}

///|
/// ec_dec_uint()：解 0..ft-1 的均匀整数（§4.1.5）。
///
/// ftb<=8 时直接解一个符号；否则高 8 位走范围码、余位走 raw bits。
/// 结果可能超出 0..ft-1，此时按 §4.1.5 视为帧损坏（取模退回）。
pub fn RangeDecoder::decode_uint(self : RangeDecoder, ft : Int) -> Int {
  let mut ftb = 0
  let mut m = ft - 1
  while m > 0 {
    ftb += 1
    m = m >> 1
  }
  if ftb <= 8 {
    let k = self.decode(ft)
    self.update(k, k + 1, ft)
    k
  } else {
    let top_ft = ((ft - 1) >> (ftb - 8)) + 1
    let hi = self.decode(top_ft)
    self.update(hi, hi + 1, top_ft)
    let lo = self.dec_bits(ftb - 8)
    ((hi << (ftb - 8)) | lo) % ft
  }
}

///|
/// ec_dec_bits()：raw bits 从帧尾反向打包，LSB 起（§4.1.4）。
///
/// 与范围解码器的前向读取相互独立，允许重叠消费同一段数据。
pub fn RangeDecoder::dec_bits(self : RangeDecoder, nbits : Int) -> Int {
  let mut v = 0
  for i in 0..<nbits {
    let pos = self.nbytes - 1 - self.raw_read / 8
    let bit_index = self.raw_read % 8
    let bit = if pos < 0 {
      0
    } else {
      (self.data.unsafe_get(pos).to_int() >> bit_index) & 1
    }
    v = v | (bit << i)
    self.raw_read += 1
  }
  v
}

///|
/// 已消费的总位数 nbits_total（§4.1.6）：整字节 + 1 位保留 + raw bits。
///
/// 初始化完成后为 33（= 8*4 + 1），与规范给的初值一致。
fn RangeDecoder::nbits_total(self : RangeDecoder) -> Int {
  8 * self.offs + 1 + self.raw_read
}

///|
/// rng 的最高位位置，即 §1.1 的 ilog(rng) = floor(log2(rng)) + 1。
fn RangeDecoder::ilog_rng(self : RangeDecoder) -> Int {
  let mut x = self.rng
  let mut n = 0
  while x > 0L {
    x = x >> 1
    n += 1
  }
  n
}

///|
/// ec_tell()：已用位数的保守上界（§4.1.6.1）。初始化后为 1。
pub fn RangeDecoder::tell(self : RangeDecoder) -> Int {
  self.nbits_total() - self.ilog_rng()
}

///|
/// ec_tell_frac()：1/8 位精度的已用位数（§4.1.6.2）。
///
/// 比特分配例程要求它与编码端 bit-exact 一致；满足
/// `ec_tell() == ceil(ec_tell_frac() / 8)`。
pub fn RangeDecoder::tell_frac(self : RangeDecoder) -> Int {
  let nbits_total = self.nbits_total()
  let mut lg = self.ilog_rng()
  let mut r = self.rng >> (lg - 16)
  for _ in 0..<3 {
    r = (r * r) >> 15
    lg = 2 * lg + (r >> 16).to_int()
    if ((r >> 16) & 1L) != 0L {
      r = r >> 1
    }
  }
  nbits_total * 8 - lg
}
