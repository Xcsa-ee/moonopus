// ogg_crc.mbt
//
// （容器层基础改编自同一作者的 moonvorbis 项目，Apache-2.0。）
//
// OGG 页校验使用的 CRC-32，与标准 IEEE CRC-32 有两处关键差异：
//   * 采用非反射（MSB-first 表驱动）算法，多项式 0x04C11DB7；
//   * 初始值与最终结果均为 0，不做 0xFFFFFFFF 的异或取反。
// 因此不能直接复用 zlib/标准 CRC-32 的实现。
// 注意它与 CRC-32/MPEG-2 仅差初值（后者为 0xFFFFFFFF），不能套用其标准
// 校验值。本实现的金标值（b"123456789" → 0x89A1897F）经移位寄存器与
// GF(2) 多项式长除法两条独立算法交叉验证，并以真实 muxer 产出的 Ogg
// 文件逐页 CRC 比对锚定。

///|
/// OGG CRC-32 查找表（256 项无符号 32 位值），在模块首次访问时惰性构造。
let crc_lookup : FixedArray[UInt] = {
  let table = FixedArray::make(256, 0U)
  for i in 0..<256 {
    let mut r : UInt = i.reinterpret_as_uint() << 24
    for _ in 0..<8 {
      if (r & 0x80000000U) != 0U {
        r = (r << 1) ^ 0x04c11db7U
      } else {
        r = r << 1
      }
    }
    table[i] = r
  }
  table
}

///|
/// 增量计算：从已有的 `crc` 继续处理 `data[start .. start + len)` 的字节。
///
/// 用于 OGG 页校验——页内 22..26 字节是 CRC 字段本身，校验时需要把它当作 0
/// 参与计算，因此把页头前 22 字节与 26 字节之后的部分分段累加。
pub fn ogg_crc32_update(
  crc : UInt,
  data : Bytes,
  start : Int,
  len : Int,
) -> UInt {
  let mut c = crc
  for i in start..<(start + len) {
    let byte = data.unsafe_get(i).to_uint()
    let idx = ((c >> 24) ^ byte).reinterpret_as_int()
    c = (c << 8) ^ crc_lookup[idx]
  }
  c
}

///|
/// 计算一段完整字节序列的 OGG CRC-32，返回 `0` 到 `0xFFFFFFFF` 之间的无符号值。
///
/// 调用方可将其结果写入 OGG 页头的 22..26 字节（小端）做校验。
pub fn ogg_crc32(data : Bytes) -> UInt {
  ogg_crc32_update(0U, data, 0, data.length())
}
