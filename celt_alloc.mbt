// celt_alloc.mbt
//
// CELT 比特分配（RFC 6716 §4.3.3）的解码路径。
//
// 规范要求分配必须 bit-exact：分配偏一拍，后面所有带的频谱解码都会错位。
// 三段结构与参考实现 rate.c 的 clt_compute_allocation /
// interp_bits2pulses 一一对应：
//
//   1. 算每带的阈值与 trim 倾斜，在 11 条静态分配向量上二分；
//   2. 在 6 步分辨率上二次二分插值出每带位数，再从比特流读 skip 标志
//      逐带回收位数（**这一步会读范围解码器**，故本函数必须带 dec）；
//   3. 逐带重平衡，得出细能量位 ebits 与收尾优先级 fine_priority，剩下的
//      位数给 PVQ。
//
// 单声道（C=1）路径：intensity / dual_stereo / LOG2_FRAC_TABLE 都只在
// 立体声分支用到，编码端专用的 prev 与 signalBandwidth 也不参与解码。

///|
/// 位分辨率：范围解码器按 1/8 bit 计位（celt/entcode.h 的 BITRES）。
pub const CEL_BITRES : Int = 3

///|
/// 第二次二分的步数（rate.c 的 ALLOC_STEPS）。
const CEL_ALLOC_STEPS : Int = 6

///|
/// 细能量偏移量（celt/rate.h 的 FINE_OFFSET）。
const CEL_FINE_OFFSET : Int = 21

///|
/// 静态分配向量的条数（模式结构体的 nbAllocVectors，对应 Table 57 的 11 列）。
const CEL_NB_ALLOC_VECTORS : Int = 11

///|
/// 分配结果。字段含义与参考实现的同名形参一致。
pub struct CeltAllocation {
  /// 每带交给 PVQ 的位数，单位 1/8 bit（对应参考实现的 pulses/bits）
  pulses : Array[Int]
  /// 每带的细能量位数（0..CEL_MAX_FINE_BITS）
  ebits : Array[Int]
  /// 每带是否进入收尾细能量轮（1 = 优先）
  fine_priority : Array[Int]
  /// 实际编码的带数，其后的带不编码
  coded_bands : Int
  /// 重平衡后剩下的位数，单位 1/8 bit（交由 quant_all_bands 再平衡）
  balance : Int
}

///|
/// 本帧可用于分配的位数，单位 1/8 bit。
///
/// `frame_bytes` 是本帧载荷字节数；`<<BITRES` 把比特换算成 1/8 bit，
/// `-1` 是规范为分配结束预留的那 1 bit，再减去解码器已用位数
/// （ec_tell_frac 本身就是 1/8 bit 单位）。反抵消（anti-collapse）的预留
/// 由帧解码阶段另行扣除。
pub fn celt_alloc_total(frame_bytes : Int, dec : RangeDecoder) -> Int {
  frame_bytes * 8 * (1 << CEL_BITRES) - dec.tell_frac() - 1
}

///|
/// 无符号 32 位除法（参考实现的 celt_udiv）。
///
/// 余量分配处的 `left` 在规范外情况下可能为负；参考实现把它按 opus_uint32
/// 重解释后再除，这里照搬同一位型语义以保证两端一致。对非负输入它就是
/// 普通整除。结果按 32 位回写成 Int，对应 C 把 uint32 存回 opus_int32。
fn celt_udiv(n : Int, d : Int) -> Int {
  let un = n.to_int64() & 0xFFFFFFFFL
  let q = un / (d.to_int64() & 0xFFFFFFFFL)
  let lo = q & 0xFFFFFFFFL
  (if lo >= 0x80000000L { lo - 0x100000000L } else { lo }).to_int()
}

///|
/// §4.3.3 第二段：二次二分插值、skip 决策、余量分摊与逐带重平衡。
///
/// 入参 `pulses` 是输出兼中间量（参考实现的 `bits`），返回
/// `(codedBands, balance)`。跳过决策会从 `dec` 读 1 个二元符号。
fn celt_interp_bits2pulses(
  dec : RangeDecoder,
  start : Int,
  end : Int,
  skip_start : Int,
  bits1 : Array[Int],
  bits2 : Array[Int],
  thresh : Array[Int],
  cap : Array[Int],
  pulses : Array[Int],
  ebits : Array[Int],
  fine_priority : Array[Int],
  total : Int,
  skip_rsv : Int,
  lm : Int,
) -> (Int, Int) {
  let m = 1 << lm
  let mut total = total // 带回分配点时要把预留的 skip 位还回去
  let alloc_floor = 1 << CEL_BITRES // 单声道：C << BITRES
  let log_m = lm << CEL_BITRES
  let floor_gate = alloc_floor + (1 << CEL_BITRES)

  // ---- 二次二分：在 bits1..bits2 之间找不超过 total 的插值点 ----
  let mut lo = 0
  let mut hi = 1 << CEL_ALLOC_STEPS
  for _ in 0..<CEL_ALLOC_STEPS {
    let mid = (lo + hi) >> 1
    let mut psum = 0
    let mut done = false
    let mut j = end - 1
    while j >= start {
      let tmp = bits1[j] + ((mid * bits2[j]) >> CEL_ALLOC_STEPS)
      if tmp >= thresh[j] || done {
        done = true
        psum += if tmp < cap[j] { tmp } else { cap[j] }
      } else if tmp >= alloc_floor {
        psum += alloc_floor
      }
      j -= 1
    }
    if psum > total {
      hi = mid
    } else {
      lo = mid
    }
  }

  // 用选定的插值点落出每带位数
  let mut psum = 0
  let mut done = false
  let mut j = end - 1
  while j >= start {
    let mut tmp = bits1[j] + ((lo * bits2[j]) >> CEL_ALLOC_STEPS)
    if tmp < thresh[j] && !done {
      tmp = if tmp >= alloc_floor { alloc_floor } else { 0 }
    } else {
      done = true
    }
    tmp = if tmp < cap[j] { tmp } else { cap[j] }
    pulses[j] = tmp
    psum += tmp
    j -= 1
  }

  // ---- 从尾部逐带决定跳过 ----
  // 跳过决策本身要占 1 bit，所以只有位数够的带才有资格被跳（否则是被
  // 强制跳过的，不花位）。循环到 skip_start 为止；读到 1 就停止跳过。
  let mut coded_bands = end
  let mut keep = false
  while !keep && coded_bands > skip_start + 1 {
    let jb = coded_bands - 1
    let span = celt_eband(coded_bands, m) - celt_eband(start, m)
    let mut left = total - psum
    let percoeff = celt_udiv(left, span)
    left -= span * percoeff
    let used = celt_eband(jb, m) - celt_eband(start, m)
    let rem = if left - used > 0 { left - used } else { 0 }
    let band_width = celt_eband(coded_bands, m) - celt_eband(jb, m)
    let mut band_bits = pulses[jb] + percoeff * band_width + rem
    let gate = if thresh[jb] > floor_gate { thresh[jb] } else { floor_gate }
    if band_bits >= gate {
      // 解码路径：读到 1 表示这个带不跳过
      if dec.decode_bit_logp(1) != 0 {
        keep = true
      } else {
        psum += 1 << CEL_BITRES
        band_bits -= 1 << CEL_BITRES
      }
    }
    if !keep {
      // 回收这个带原本分到的位数（单声道 intensity_rsv 恒为 0）
      psum -= pulses[jb]
      if band_bits >= alloc_floor {
        // 至少够每声道一个细能量位，就用它
        psum += alloc_floor
        pulses[jb] = alloc_floor
      } else {
        pulses[jb] = 0
      }
      coded_bands -= 1
    }
  }
  if !keep {
    // 走到 skip_start 了：「跳带到此结束」的信号位用不着，还回去
    total += skip_rsv
  }

  // ---- 余量按带宽分摊，不够整份的逐带补齐 ----
  let mut left = total - psum
  let span = celt_eband(coded_bands, m) - celt_eband(start, m)
  let percoeff = celt_udiv(left, span)
  left -= span * percoeff
  for jb in start..<coded_bands {
    pulses[jb] += percoeff * (celt_eband(jb + 1, m) - celt_eband(jb, m))
  }
  for jb in start..<coded_bands {
    let room = celt_eband(jb + 1, m) - celt_eband(jb, m)
    let take = if left < room { left } else { room }
    pulses[jb] += take
    left -= take
  }

  // ---- 逐带重平衡并切出细能量位 ----
  let mut balance = 0
  let mut jb = start
  while jb < coded_bands {
    let n = (celt_eband(jb + 1, m) - celt_eband(jb, m)) << lm
    let bit = pulses[jb] + balance
    let mut excess = 0
    if n > 1 {
      excess = if bit > cap[jb] { bit - cap[jb] } else { 0 }
      pulses[jb] = bit - excess
      let den = n // 单声道 C=1，故 den = C*N
      let nclogn = den * (cel_log_n[jb] + log_m)
      // 相比「公平份额」的偏移：log2(N)/2 + FINE_OFFSET
      let mut offset = (nclogn >> 1) - den * CEL_FINE_OFFSET
      // N=2 是曲线上唯一不吻合的点
      if n == 2 {
        offset += den << CEL_BITRES >> 2
      }
      if pulses[jb] + offset < (den * 2) << CEL_BITRES {
        offset += nclogn >> 2
      } else if pulses[jb] + offset < (den * 3) << CEL_BITRES {
        offset += nclogn >> 3
      }
      // 带舍入的除法：先加 den<<(BITRES-1) 再除
      let mut fine = pulses[jb] + offset + (den << (CEL_BITRES - 1))
      if fine < 0 {
        fine = 0
      }
      fine = celt_udiv(fine, den) >> CEL_BITRES
      // 别超过这个带实际有的位数（单声道 stereo=0）
      if fine > pulses[jb] >> CEL_BITRES {
        fine = pulses[jb] >> CEL_BITRES
      }
      // 参考实现此处还有 `fine > MAX_FINE_BITS` 的封顶。单声道解码路径
      // 下它不可达：重平衡保证 pulses[jb] <= cap[jb]，而对全部 (LM, 带)
      // 组合按此约束算出的 fine 最大为 8。故不搬这段不会改变结果，也免得
      // 留下一段永远测不到的分支。
      ebits[jb] = fine
      // 舍入向下或被封顶的带，进收尾细能量轮
      fine_priority[jb] = if fine * (den << CEL_BITRES) >= pulses[jb] + offset {
        1
      } else {
        0
      }
      // 细能量的位数先扣掉，剩下的归 PVQ
      pulses[jb] -= fine << CEL_BITRES
    } else {
      // N=1：除了一个符号位，其余全给细能量
      excess = if bit > 1 << CEL_BITRES { bit - (1 << CEL_BITRES) } else { 0 }
      pulses[jb] = bit - excess
      ebits[jb] = 0
      fine_priority[jb] = 1
    }
    // 超出 cap 的部分改投细能量（参考实现注释：细能量吃不到
    // quant_all_bands 的再平衡，所以在这儿补）
    if excess > 0 {
      let mut extra_fine = excess >> CEL_BITRES // 单声道 stereo=0
      let room = CEL_MAX_FINE_BITS - ebits[jb]
      if extra_fine > room {
        extra_fine = room
      }
      ebits[jb] += extra_fine
      let extra_bits = extra_fine << CEL_BITRES
      fine_priority[jb] = if extra_bits >= excess - balance { 1 } else { 0 }
      excess -= extra_bits
    }
    balance = excess
    jb += 1
  }

  // 被跳过的带：位数全给细能量
  while jb < end {
    ebits[jb] = pulses[jb] >> CEL_BITRES
    pulses[jb] = 0
    fine_priority[jb] = if ebits[jb] < 1 { 1 } else { 0 }
    jb += 1
  }
  (coded_bands, balance)
}

///|
/// 比特分配（§4.3.3）：恢复本帧每带的 PVQ 位数、细能量位与收尾优先级。
///
/// `offsets` 是 dynalloc 的加成（单位 1/8 bit，长度 21），`cap` 由
/// `celt_init_caps` 给出，`alloc_trim` 是解出的 0..10（§4.3.3：5 表示不加
/// 不减），`total` 用 `celt_alloc_total` 算（单位 1/8 bit）。范围解码器会被
/// 推进——skip 决策要读符号，顺序与帧内其它符号一致。
pub fn celt_compute_allocation(
  dec : RangeDecoder,
  start : Int,
  end : Int,
  offsets : Array[Int],
  cap : Array[Int],
  alloc_trim : Int,
  total : Int,
  lm : Int,
) -> CeltAllocation {
  let m = 1 << lm
  let len = CEL_NB_EBANDS
  let pulses = Array::make(len, 0)
  let ebits = Array::make(len, 0)
  let fine_priority = Array::make(len, 0)
  let thresh = Array::make(len, 0)
  let trim_offset = Array::make(len, 0)
  let bits1 = Array::make(len, 0)
  let bits2 = Array::make(len, 0)

  let mut total = if total > 0 { total } else { 0 }
  let mut skip_start = start
  // 预留 1 bit 表示「手动跳带到此结束」
  let skip_rsv = if total >= 1 << CEL_BITRES { 1 << CEL_BITRES } else { 0 }
  total -= skip_rsv
  // 单声道不需要 intensity / dual_stereo 的预留位

  for jb in start..<end {
    let n0 = celt_eband(jb + 1, m) - celt_eband(jb, m)
    // 低于这个阈值必定不分配 PVQ 位
    let floor_bits = 1 << CEL_BITRES // C << BITRES
    let scaled = (3 * n0) << lm << CEL_BITRES >> 4
    thresh[jb] = if floor_bits > scaled { floor_bits } else { scaled }
    // 分配曲线的倾斜
    trim_offset[jb] = (
        n0 * (alloc_trim - 5 - lm) * (end - jb - 1) * (1 << (lm + CEL_BITRES))
      ) >>
      6
    // 单系数带给的分辨率低一些：它们一个粗值就够
    if n0 << lm == 1 {
      trim_offset[jb] -= 1 << CEL_BITRES
    }
  }

  // ---- 第一次二分：在 11 条静态分配向量上找不超过 total 的那条 ----
  // do-while：先算后判，故用 cont 标志复刻「至少跑一轮」。
  let mut lo = 1
  let mut hi = CEL_NB_ALLOC_VECTORS - 1
  let mut cont = true
  while cont {
    let mid = (lo + hi) >> 1
    let mut psum = 0
    let mut done = false
    let mut jb = end - 1
    while jb >= start {
      let n0 = celt_eband(jb + 1, m) - celt_eband(jb, m)
      let mut bitsj = (n0 * cel_alloc_vectors[mid * len + jb]) << lm >> 2
      if bitsj > 0 {
        bitsj = if bitsj + trim_offset[jb] > 0 {
          bitsj + trim_offset[jb]
        } else {
          0
        }
      }
      bitsj += offsets[jb]
      if bitsj >= thresh[jb] || done {
        done = true
        psum += if bitsj < cap[jb] { bitsj } else { cap[jb] }
      } else if bitsj >= 1 << CEL_BITRES {
        psum += 1 << CEL_BITRES
      }
      jb -= 1
    }
    if psum > total {
      hi = mid - 1
    } else {
      lo = mid + 1
    }
    cont = lo <= hi
  }
  // 退出时 lo 是刚越过的那条，故有效插值区间是 [lo-1, lo]
  let lo_edge = lo - 1
  let hi_edge = lo

  for jb in start..<end {
    let n0 = celt_eband(jb + 1, m) - celt_eband(jb, m)
    let mut b1 = (n0 * cel_alloc_vectors[lo_edge * len + jb]) << lm >> 2
    let mut b2 = if hi_edge >= CEL_NB_ALLOC_VECTORS {
      cap[jb]
    } else {
      (n0 * cel_alloc_vectors[hi_edge * len + jb]) << lm >> 2
    }
    if b1 > 0 {
      b1 = if b1 + trim_offset[jb] > 0 { b1 + trim_offset[jb] } else { 0 }
    }
    if b2 > 0 {
      b2 = if b2 + trim_offset[jb] > 0 { b2 + trim_offset[jb] } else { 0 }
    }
    if lo_edge > 0 {
      b1 += offsets[jb]
    }
    b2 += offsets[jb]
    // 被 dynalloc 加过成的带不能被手动跳过
    if offsets[jb] > 0 {
      skip_start = jb
    }
    b2 = if b2 - b1 > 0 { b2 - b1 } else { 0 }
    bits1[jb] = b1
    bits2[jb] = b2
  }

  let cb = celt_interp_bits2pulses(
    dec, start, end, skip_start, bits1, bits2, thresh, cap, pulses, ebits, fine_priority,
    total, skip_rsv, lm,
  )
  CeltAllocation::{
    pulses,
    ebits,
    fine_priority,
    coded_bands: cb.0,
    balance: cb.1,
  }
}
