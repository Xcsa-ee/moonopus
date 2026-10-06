// 由 tools/gen_fixtures.py 生成，请勿手改。
//
// Ogg CRC-32 金标值（多项式 0x04C11DB7、初值 0、不反转）。
// 由独立逐位实现与 GF(2) 多项式长除法双算法交叉验证，
// 并经真实 muxer 产出的 Ogg 文件逐页 CRC 比对锚定。

///|
const FIX_CRC_EMPTY : UInt = 0x00000000U

///|
const FIX_CRC_OGGS : UInt = 0x5fb0a94fU

///|
const FIX_CRC_CHECK : UInt = 0x89a1897fU
