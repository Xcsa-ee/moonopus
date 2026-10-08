// celt_theta.mbt
//
// split 增益参数 θ 的量化阶数与解码（RFC 6716 §4.3.4.4 Split Decoding）。
//
// RFC 对 θ 的量化只有一句「精度由当前分配导出的量化增益参数熵编码」，
// QN 公式、三种 PDF 与 imid/iside 换算都未写入规范正文——bit-exact 的
// 事实标准是参考实现 celt_bands.c 的 compute_qn / compute_theta，本文件
// 按其解码侧逐行对应：
//
//   - celt_compute_qn：量化阶数，结果为 1 或偶数（≤256）；
//   - celt_compute_theta：按 PDF 解出 θ（立体声 N>2 用阶梯 p0=3，
//     B0>1 或立体声用均匀，长块单声道用三角，三角反解含 isqrt32），
//     再换算 imid/iside/delta——只做控制与熵解码，不碰谱系数；
//   - celt_bitexact_cos / celt_bitexact_log2tan 是全平台位一致的定点
//     近似，直接参与位分配（delta），必须与参考实现同结果。

///|
/// θ 量化的分辨率偏移（rate.h 的 QTHETA_OFFSET）。
const CEL_QTHETA_OFFSET : Int = 4

///|
/// N==2 立体声两相模式的偏移（rate.h 的 QTHETA_OFFSET_TWOPHASE）。
const CEL_QTHETA_OFFSET_TWOPHASE : Int = 16

///|
/// compute_qn 的 2**(i/8)×16384 表（celt_bands.c 的 exp2_table8，
/// 参考端用浮点 floor 独立算出后在生成器里对拍）。
let cel_exp2_table8 : Array[Int] = [
  16384, 17866, 19483, 21247, 23170, 25267, 27554, 30048,
]

///|
/// split 节点解码结果：θ 换算的全部控制量。
pub struct CeltThetaSplit {
  /// qn==1 立体声的反相标志（解码读出，disable_inv 时强制 0）
  inv : Int
  /// mid 的定点幅度（0..32767）
  imid : Int
  /// side 的定点幅度（0..32767）
  iside : Int
  /// mid/side 位数划分的倾斜量（1/8 bit·bin 单位）
  delta : Int
  /// 归一化后的 θ（0..16384）
  itheta : Int
  /// 本节点熵解码消耗的位数（1/8 bit）
  qalloc : Int
  /// 量化阶数（1 或偶数，≤256）
  qn : Int
}

///|
/// 最高有效位位置，即 EC_ILOG(x)（x ≥ 1）。
fn celt_ilog(x : Int) -> Int {
  let mut v = x
  let mut n = 0
  while v > 0 {
    v = v >> 1
    n += 1
  }
  n
}

///|
/// 按 opus_int16 语义截断（对应 C 把中间量存进 opus_int16）。
fn celt_s16(v : Int) -> Int {
  let u = v & 0xFFFF
  if u >= 0x8000 {
    u - 0x10000
  } else {
    u
  }
}

///|
/// celt_mathops.h 的 FRAC_MUL16：两操作数按 int16 截断后带 1/2 修正的
/// 15 位定点乘。右移对负值取 floor，与 C 的算术右移一致。
fn celt_frac_mul16(a : Int, b : Int) -> Int {
  (16384 + celt_s16(a) * celt_s16(b)) >> 15
}

///|
/// celt_sudiv：向零截断的有符号除法（d > 0）。b+N2*offset 可为负，
/// C 的 `n/d` 截断语义必须显式复刻（floor 会在负奇数上差 1）。
fn celt_sudiv(n : Int, d : Int) -> Int {
  if n < 0 {
    -(-n / d)
  } else {
    n / d
  }
}

///|
/// mathops.c 的 isqrt32：二进制位搜索 floor(sqrt(v))——三角 PDF 的
/// 累计频率反解靠它把 fm/f-tail 映射回 θ 档位。
pub fn celt_isqrt32(v : Int) -> Int {
  let mut g = 0
  let mut bshift = (celt_ilog(v) - 1) >> 1
  let mut b = 1 << bshift
  let mut val = v
  while bshift >= 0 {
    let t = ((g << 1) + b) << bshift
    if t <= val {
      g += b
      val -= t
    }
    b = b >> 1
    bshift -= 1
  }
  g
}

///|
/// celt_bands.c 的 bitexact_cos：全平台位一致的余弦近似，输入是
/// 0..16384 的 1/16384 弧度格点（0 与 16384 由调用方先行特判，
/// 格点最小步长 64 保证中间量不越过 int16 断言域）。
pub fn celt_bitexact_cos(x : Int) -> Int {
  let tmp = (4096 + x * x) >> 13
  let x2 = celt_s16(
    32767 -
    tmp +
    celt_frac_mul16(
      tmp,
      -7651 + celt_frac_mul16(tmp, 8277 + celt_frac_mul16(-626, tmp)),
    ),
  )
  1 + x2
}

///|
/// celt_bands.c 的 bitexact_log2tan：log2(tan) 的定点近似，
/// `delta = FRAC_MUL16((N-1)<<7, log2tan(iside, imid))` 消费其结果。
pub fn celt_bitexact_log2tan(isin : Int, icos : Int) -> Int {
  let lc = celt_ilog(icos)
  let ls = celt_ilog(isin)
  let s = isin << (15 - ls)
  let c = icos << (15 - lc)
  ((ls - lc) << 11) +
  celt_frac_mul16(s, celt_frac_mul16(s, -2597) + 7932) -
  celt_frac_mul16(c, celt_frac_mul16(c, -2597) + 7932)
}

///|
/// compute_qn：split 增益的量化阶数（celt_bands.c 同名函数）。
///
/// `offset` 与 `pulse_cap` 由调用方按
/// `pulse_cap = logN[band] + LM<<BITRES`、
/// `offset = (pulse_cap>>1) - QTHETA[_TWOPHASE]` 算好传入。
/// 上限 8<<BITRES 保证立体声 itheta==16384 时 side 侧仍能编出脉冲；
/// 结果为 1 或偶数。
pub fn celt_compute_qn(
  n : Int,
  b : Int,
  offset : Int,
  pulse_cap : Int,
  stereo : Bool,
) -> Int {
  let mut n2 = 2 * n - 1
  if stereo && n == 2 {
    n2 -= 1
  }
  let q1 = celt_sudiv(b + n2 * offset, n2)
  let q2 = b - pulse_cap - (4 << CEL_BITRES)
  let mut qb = if q1 < q2 { q1 } else { q2 }
  let cap = 8 << CEL_BITRES
  if cap < qb {
    qb = cap
  }
  if qb < 1 << CEL_BITRES >> 1 {
    return 1
  }
  let qn = cel_exp2_table8[qb & 0x7] >> (14 - (qb >> CEL_BITRES))
  (qn + 1) >> 1 << 1
}

///|
/// compute_theta 的解码侧：解出 split 节点的 θ 与 mid/side 控制量。
///
/// 入参 `lm` 是本节点的 LM（分割后已减 1），`blocks`/`blocks0` 是
/// 分割后/分割前的时间块数 B（PDF 选择看 B0），`remaining_bits` 只读
/// （qn==1 立体声 inv 判定的预算条件），扣减由调用方按返回的 qalloc
/// 做。返回 `(split, b 减 qalloc 后, fill 按 itheta 掩蔽后)`。
pub fn celt_compute_theta(
  dec : RangeDecoder,
  band : Int,
  lm : Int,
  n : Int,
  b : Int,
  blocks : Int,
  blocks0 : Int,
  stereo : Bool,
  intensity : Int,
  remaining_bits : Int,
  disable_inv : Bool,
  fill : Int,
) -> (CeltThetaSplit, Int, Int) {
  let pulse_cap = cel_log_n[band] + (lm << CEL_BITRES)
  let offset = (pulse_cap >> 1) -
    (if stereo && n == 2 {
      CEL_QTHETA_OFFSET_TWOPHASE
    } else {
      CEL_QTHETA_OFFSET
    })
  let mut qn = celt_compute_qn(n, b, offset, pulse_cap, stereo)
  if stereo && band >= intensity {
    qn = 1
  }
  let mut inv = 0
  let tell = dec.tell_frac()
  let mut itheta = 0
  if qn != 1 {
    if stereo && n > 2 {
      // 阶梯 PDF：0..x0 每档 p0=3，其后每档 1
      let p0 = 3
      let x0 = qn / 2
      let ft = p0 * (x0 + 1) + x0
      let fs = dec.decode(ft)
      let mut x = 0
      let mut fl = 0
      let mut fh = 0
      if fs < (x0 + 1) * p0 {
        x = fs / p0
        fl = p0 * x
        fh = p0 * (x + 1)
      } else {
        x = x0 + 1 + (fs - (x0 + 1) * p0)
        fl = x - 1 - x0 + (x0 + 1) * p0
        fh = x - x0 + (x0 + 1) * p0
      }
      dec.update(fl, fh, ft)
      itheta = x
    } else if blocks0 > 1 || stereo {
      // 均匀 PDF
      itheta = dec.decode_uint(qn + 1)
    } else {
      // 三角 PDF：频率 1,2,...,m+1,m,...,1（qn 恒为偶）
      let m = qn >> 1
      let ft = (m + 1) * (m + 1)
      let fs = dec.decode(ft)
      let mut fsym = 1
      let mut fl = 0
      if fs < (m * (m + 1)) >> 1 {
        itheta = (celt_isqrt32(8 * fs + 1) - 1) >> 1
        fsym = itheta + 1
        fl = (itheta * (itheta + 1)) >> 1
      } else {
        itheta = (2 * (qn + 1) - celt_isqrt32(8 * (ft - fs - 1) + 1)) >> 1
        fsym = qn + 1 - itheta
        fl = ft - (((qn + 1 - itheta) * (qn + 2 - itheta)) >> 1)
      }
      dec.update(fl, fl + fsym, ft)
    }
    itheta = itheta * 16384 / qn
  } else if stereo {
    if b > 2 << CEL_BITRES && remaining_bits > 2 << CEL_BITRES {
      inv = dec.decode_bit_logp(2)
    }
    if disable_inv {
      inv = 0
    }
  }
  let qalloc = dec.tell_frac() - tell
  let b_after = b - qalloc
  let mut fill_after = fill
  let mut imid = 0
  let mut iside = 0
  let mut delta = 0
  if itheta == 0 {
    imid = 32767
    iside = 0
    fill_after = fill & ((1 << blocks) - 1)
    delta = -16384
  } else if itheta == 16384 {
    imid = 0
    iside = 32767
    fill_after = fill & (((1 << blocks) - 1) << blocks)
    delta = 16384
  } else {
    imid = celt_bitexact_cos(itheta)
    iside = celt_bitexact_cos(16384 - itheta)
    delta = celt_frac_mul16((n - 1) << 7, celt_bitexact_log2tan(iside, imid))
  }
  ({ inv, imid, iside, delta, itheta, qalloc, qn, }, b_after, fill_after)
}
