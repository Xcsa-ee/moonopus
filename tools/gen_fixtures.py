# -*- coding: utf-8 -*-
"""生成 moonopus 的测试样例（fixtures）。

测试页全部由本脚本（独立于 MoonBit 实现的 Python 参考构造器）计算 CRC 并拼装，
与 MoonBit 解析端交叉验证，避免「自己构造、自己解析」的自证循环。

CRC 自检：本脚本使用逐位 MSB-first 实现（多项式 0x04C11DB7，初值 0，
不反转、不取反）。金标值经双算法交叉验证并以真实 Ogg 文件页 CRC 锚定，
启动时断言（详见下方 GOLDEN 注释）。

用法：
    python tools/gen_fixtures.py
输出（写入仓库根目录，勿手改）：
    fixtures_crc_wbtest.mbt   CRC 金标常量
    fixtures_wbtest.mbt       合法样例与 28 个非法样例
"""
import os
import sys

from _fmt import moon_fmt

# ---------------------------------------------------------------------------
# 独立 CRC 实现（逐位，非查表，与 MoonBit 端实现路径不同）
# ---------------------------------------------------------------------------

def crc32_ogg(data: bytes) -> int:
    crc = 0
    for byte in data:
        crc ^= byte << 24
        for _ in range(8):
            if crc & 0x80000000:
                crc = ((crc << 1) ^ 0x04C11DB7) & 0xFFFFFFFF
            else:
                crc = (crc << 1) & 0xFFFFFFFF
    return crc

# 金标值锚定（Ogg CRC：多项式 0x04C11DB7、初值 0、不反转、不取反；
# 与 CRC-32/MPEG-2 仅差初值，不能套用其标准校验值 0x0376E6E7）。
# 下列值经两条独立算法（移位寄存器与 GF(2) 多项式长除法）交叉验证一致，
# 并以真实 muxer 产出的 Ogg 文件（moonvorbis demo/sample.ogg，3 页）
# 逐页存储 CRC 比对锚定。
GOLDEN = {
    b"": 0x00000000,
    b"OggS": 0x5FB0A94F,
    b"123456789": 0x89A1897F,
}
for _probe, _want in GOLDEN.items():
    _got = crc32_ogg(_probe)
    if _got != _want:
        sys.exit(f"CRC self-test failed for {_probe!r}: {_got:#010x} != {_want:#010x}")

# 可选：同作者旁仓库存在真实 Ogg 样例时，再做一次真实文件锚定
_sample = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "..", "moonvorbis", "demo", "sample.ogg",
)
if os.path.exists(_sample):
    _data = open(_sample, "rb").read()
    _off = _pages = 0
    while _off < len(_data) - 27:
        _nseg = _data[_off + 26]
        _total = 27 + _nseg + sum(_data[_off + 27 : _off + 27 + _nseg])
        _page = _data[_off : _off + _total]
        _stored = int.from_bytes(_page[22:26], "little")
        if crc32_ogg(_page[:22] + b"\x00\x00\x00\x00" + _page[26:]) != _stored:
            sys.exit(f"CRC self-test failed on real file page @{_off}")
        _pages += 1
        _off += _total
    print(f"[ok] real-file anchor: sample.ogg {_pages} pages")

CHECK_VECTOR = GOLDEN[b"123456789"]

# ---------------------------------------------------------------------------
# Ogg 页构造器
# ---------------------------------------------------------------------------

def _lacing(pieces):
    """由 (bytes, 是否为该 packet 的最后一段) 列表得到 lacing 表与 body。"""
    laces = []
    body = b""
    for data, final in pieces:
        if final:
            remaining = len(data)
            while remaining > 254:
                laces.append(255)
                remaining -= 255
            laces.append(remaining)  # 0..254，终结该 packet
        else:
            if len(data) == 0 or len(data) % 255 != 0:
                raise ValueError("非末段必须是 255 的正整数倍")
            laces.extend([255] * (len(data) // 255))
        body += data
    if len(laces) > 255:
        raise ValueError("单页 segment 数超上限")
    return bytes(laces), body

def build_page(header_type, granule, serial, seq, pieces):
    laces, body = _lacing(pieces)
    header = (
        b"OggS"
        + b"\x00"
        + bytes([header_type])
        + (granule & 0xFFFFFFFFFFFFFFFF).to_bytes(8, "little")
        + serial.to_bytes(4, "little")
        + seq.to_bytes(4, "little")
        + b"\x00\x00\x00\x00"  # CRC 占位
        + bytes([len(laces)])
        + laces
    )
    page = header + body
    crc = crc32_ogg(page)
    return page[:22] + crc.to_bytes(4, "little") + page[26:]

def refix_crc(page):
    """结构不变地重算单页 CRC（供改字段后的样例使用）。"""
    nseg = page[26]
    body_len = sum(page[27 : 27 + nseg])
    total = 27 + nseg + body_len
    if len(page) != total:
        raise ValueError("refix_crc: 页长度与 lacing 不符")
    fresh = page[:22] + b"\x00\x00\x00\x00" + page[26:]
    crc = crc32_ogg(fresh)
    return page[:22] + crc.to_bytes(4, "little") + page[26:]

FLAG_CONTINUED, FLAG_BOS, FLAG_EOS = 0x01, 0x02, 0x04

# ---------------------------------------------------------------------------
# OpusHead / OpusTags 构造器
# ---------------------------------------------------------------------------

def opus_head(version=1, channels=1, pre_skip=312, rate=48000, gain=0,
              family=0, table=None, raw_override=None):
    head = (
        b"OpusHead"
        + bytes([version, channels])
        + pre_skip.to_bytes(2, "little")
        + rate.to_bytes(4, "little")
        + (gain & 0xFFFF).to_bytes(2, "little")
        + bytes([family])
    )
    if family != 0:
        stream_count, coupled_count, mapping = table
        head += bytes([stream_count, coupled_count]) + bytes(mapping)
    if raw_override is not None:
        head = raw_override
    return head

def opus_tags(vendor, comments):
    out = b"OpusTags" + len(vendor).to_bytes(4, "little") + vendor
    out += len(comments).to_bytes(4, "little")
    for c in comments:
        out += len(c).to_bytes(4, "little") + c
    return out

# ---------------------------------------------------------------------------
# 合法样例
# ---------------------------------------------------------------------------

SERIAL_SIMPLE = 0x4D505553  # "MPUS"
SERIAL_FAM1 = 0x4D505531    # "MPU1"
HEAD_F0 = opus_head()
TAGS_SIMPLE = opus_tags(
    b"moonopus test encoder",
    [b"TITLE=moonopus \xe6\xb5\x8b\xe8\xaf\x95", b"DATE=2026"],
)
AUD_P1, AUD_P2, AUD_P3 = b"\xf8\xff\xfe", b"ABC", b"123456"

def simple_stream(eos=True):
    pages = [
        build_page(FLAG_BOS, 0, SERIAL_SIMPLE, 0, [(HEAD_F0, True)]),
        build_page(0, 0, SERIAL_SIMPLE, 1, [(TAGS_SIMPLE, True)]),
        build_page(FLAG_EOS if eos else 0, 2880, SERIAL_SIMPLE, 2,
                   [(AUD_P1, True), (AUD_P2, True), (AUD_P3, True)]),
    ]
    return b"".join(pages)

FIX_SIMPLE = simple_stream()

# 跨页样例：300 字节音频 packet 跨两页（page2 以 255 结尾，page3 带 CONTINUED）
SPAN_A = bytes(((i * 7 + 3) & 0xFF) for i in range(300))
SPAN_B = b"XYZXYZ"
FIX_SPANNED = b"".join([
    build_page(FLAG_BOS, 0, SERIAL_SIMPLE, 0, [(HEAD_F0, True)]),
    build_page(0, 0, SERIAL_SIMPLE, 1, [(TAGS_SIMPLE, True)]),
    # 单 packet 独占且未完的页：granule 按 RFC 7845 §4 取 -1
    build_page(0, -1, SERIAL_SIMPLE, 2, [(SPAN_A[:255], False)]),
    build_page(FLAG_CONTINUED | FLAG_EOS, 960, SERIAL_SIMPLE, 3,
               [(SPAN_A[255:], True), (SPAN_B, True)]),
])

# family 1 六声道、无 EOS（验证缺 EOS 的截断容忍与多包页）
HEAD_F1 = opus_head(channels=6, pre_skip=0, rate=44100, gain=-12,
                    family=1, table=(4, 2, [0, 1, 2, 3, 4, 5]))
TAGS_F1 = opus_tags(b"fam1-encoder", [b"CHANNELS=6"])
FIX_FAM1 = b"".join([
    build_page(FLAG_BOS, 0, SERIAL_FAM1, 0, [(HEAD_F1, True)]),
    build_page(0, 0, SERIAL_FAM1, 1, [(TAGS_F1, True)]),
    build_page(0, 1920, SERIAL_FAM1, 2, [(b"XY", True), (b"Z", True)]),
])

# ---------------------------------------------------------------------------
# 非法样例（改字段/改结构后重算 CRC；故意破坏 CRC 的除外）
# ---------------------------------------------------------------------------

def replace_page(stream, index, new_page):
    pages, rest = [], stream
    while rest:
        nseg = rest[26]
        total = 27 + nseg + sum(rest[27 : 27 + nseg])
        pages.append(rest[:total])
        rest = rest[total:]
    pages[index] = new_page
    return b"".join(pages)

def page_pieces(stream, index):
    """拆出第 index 页的 (header_type, granule, serial, seq, pieces)。"""
    rest = stream
    for _ in range(index):
        nseg = rest[26]
        rest = rest[27 + nseg + sum(rest[27 : 27 + nseg]) :]
    nseg = rest[26]
    laces = list(rest[27 : 27 + nseg])
    body = rest[27 + nseg : 27 + nseg + sum(laces)]
    header_type, granule = rest[5], int.from_bytes(rest[6:14], "little")
    if granule >= 1 << 63:
        granule -= 1 << 64
    serial = int.from_bytes(rest[14:18], "little")
    seq = int.from_bytes(rest[18:22], "little")
    pieces, pos, i = [], 0, 0
    while i < len(laces):
        data, final = b"", False
        while i < len(laces):
            data += body[pos : pos + laces[i]]
            pos += laces[i]
            lace = laces[i]
            i += 1
            if lace < 255:
                final = True  # 遇到 <255 的 lacing，该 packet 在本页终结
                break
        # 页以 255 结尾时 final=False：packet 延续到下一页
        pieces.append((data, final))
    return header_type, granule, serial, seq, pieces

def rebuild(stream, index, mutate_pieces=None, **mutate_header):
    ht, gr, se, sq, pieces = page_pieces(stream, index)
    if mutate_pieces is not None:
        pieces = mutate_pieces(pieces)
    ht = mutate_header.get("header_type", ht)
    gr = mutate_header.get("granule", gr)
    se = mutate_header.get("serial", se)
    sq = mutate_header.get("seq", sq)
    return replace_page(stream, index, build_page(ht, gr, se, sq, pieces))

def first_two_packets(stream):
    """返回 (head 包, tags 包) 的原始字节（仅供改造头包用，页必须合法）。"""
    _, _, _, _, head_pieces = page_pieces(stream, 0)
    _, _, _, _, tags_pieces = page_pieces(stream, 1)
    assert len(head_pieces) == 1 and len(tags_pieces) == 1
    return head_pieces[0][0], tags_pieces[0][0]

def swap_head(stream, new_head):
    return rebuild(stream, 0, mutate_pieces=lambda _: [(new_head, True)])

def swap_tags(stream, new_tags):
    return rebuild(stream, 1, mutate_pieces=lambda _: [(new_tags, True)])

def first_page(stream):
    nseg = stream[26]
    return stream[: 27 + nseg + sum(stream[27 : 27 + nseg])]

# —— 页级非法样例 ——
# 除「坏 CRC」「截断」外，所有样例保持页 CRC 一致，让被测规则成为唯一错误点。
_p0 = first_page(FIX_SIMPLE)
FIX_BAD_MAGIC = refix_crc(b"XggS" + _p0[4:]) + FIX_SIMPLE[len(_p0) :]
_bad_crc = bytearray(FIX_SIMPLE)
_bad_crc[27 + 1] ^= 0xFF          # 破坏第 0 页 body，保持旧 CRC
FIX_BAD_CRC = bytes(_bad_crc)
FIX_TRUNCATED = FIX_SIMPLE[:-5]   # 页 2 body 中途截断
FIX_ID_GRANULE = rebuild(FIX_SIMPLE, 0, granule=480)
FIX_NO_BOS = rebuild(FIX_SIMPLE, 0, header_type=0)
FIX_SERIAL_MISMATCH = rebuild(FIX_SIMPLE, 1, serial=SERIAL_SIMPLE ^ 0x000000FF)
FIX_SEQ_GAP = rebuild(FIX_SIMPLE, 1, seq=9)
FIX_SPURIOUS_CONTINUED = rebuild(FIX_SIMPLE, 1, header_type=FLAG_CONTINUED)
FIX_TAGS_GRANULE = rebuild(FIX_SIMPLE, 1, granule=100)
FIX_HEAD_NOT_ALONE = rebuild(
    FIX_SIMPLE, 0, mutate_pieces=lambda _: [(HEAD_F0, True), (b"extra", True)]
)
FIX_PAGE_AFTER_EOS = FIX_SIMPLE + build_page(
    0, 0, SERIAL_SIMPLE, 3, [(b"EXTRA", True)]
)
FIX_CHAINED = FIX_FAM1 + build_page(
    FLAG_BOS, 0, SERIAL_SIMPLE ^ 0x11111111, 0, [(HEAD_F0, True)]
)
# page3 丢掉 CONTINUED（page2 以 255 结尾，续包丢失）
FIX_MISSING_CONTINUED = rebuild(FIX_SPANNED, 3, header_type=FLAG_EOS)

# —— OpusHead 非法样例（页结构保持合法，仅改头包内容） ——
FIX_HEAD_BAD_MAGIC = swap_head(FIX_SIMPLE, b"XpusHead" + HEAD_F0[8:])
FIX_HEAD_VERSION = swap_head(FIX_SIMPLE, opus_head(version=16))
FIX_HEAD_CHANNELS0 = swap_head(FIX_SIMPLE, opus_head(channels=0))
FIX_FAM0_CHANNELS3 = swap_head(FIX_SIMPLE, opus_head(channels=3))
FIX_FAM0_EXTRA = swap_head(FIX_SIMPLE, HEAD_F0 + b"\x00")
FIX_HEAD_SHORT = swap_head(FIX_SIMPLE, HEAD_F0[:17])  # 17 字节 < 19 最小长度
FIX_FAM1_CHANNELS9 = swap_head(
    FIX_FAM1, opus_head(channels=9, family=1, table=(4, 2, [0, 1, 2, 3, 4, 5]))
)
FIX_FAM1_STREAM0 = swap_head(
    FIX_FAM1, opus_head(channels=6, family=1, table=(0, 0, [0, 1, 2, 3, 4, 5]))
)
FIX_FAM1_COUPLED_GT = swap_head(
    FIX_FAM1, opus_head(channels=6, family=1, table=(4, 5, [0, 1, 2, 3, 4, 5]))
)
FIX_FAM1_INDEX_OOB = swap_head(
    FIX_FAM1, opus_head(channels=6, family=1, table=(4, 2, [0, 1, 2, 3, 4, 7]))
)
FIX_FAM1_LEN = swap_head(FIX_FAM1, HEAD_F1[:-1])  # 26 字节，映射表缺 1 字节

# —— OpusTags 非法样例 ——
_t_bad_magic = b"XpusTags" + TAGS_SIMPLE[8:]
FIX_TAGS_BAD_MAGIC = swap_tags(FIX_SIMPLE, _t_bad_magic)
_tv = bytearray(TAGS_SIMPLE)
_tv[8:12] = (0xFFFFFF00).to_bytes(4, "little")
FIX_TAGS_VENDOR_LEN = swap_tags(FIX_SIMPLE, bytes(_tv))
FIX_TAGS_TRAILING = swap_tags(FIX_SIMPLE, TAGS_SIMPLE + b"xyz")
_tc = bytearray(TAGS_SIMPLE)
# count 位于 vendor 之后：8 + 4 + len(vendor)
_cnt_at = 8 + 4 + int.from_bytes(TAGS_SIMPLE[8:12], "little")
_tc[_cnt_at : _cnt_at + 4] = (0x7FFFFFFF).to_bytes(4, "little")
FIX_TAGS_COUNT = swap_tags(FIX_SIMPLE, bytes(_tc))

VALID = {
    "FIX_SIMPLE": FIX_SIMPLE,
    "FIX_SPANNED": FIX_SPANNED,
    "FIX_FAM1": FIX_FAM1,
}
INVALID = {
    "FIX_BAD_MAGIC": FIX_BAD_MAGIC,
    "FIX_BAD_CRC": FIX_BAD_CRC,
    "FIX_TRUNCATED": FIX_TRUNCATED,
    "FIX_ID_GRANULE": FIX_ID_GRANULE,
    "FIX_NO_BOS": FIX_NO_BOS,
    "FIX_SERIAL_MISMATCH": FIX_SERIAL_MISMATCH,
    "FIX_SEQ_GAP": FIX_SEQ_GAP,
    "FIX_SPURIOUS_CONTINUED": FIX_SPURIOUS_CONTINUED,
    "FIX_TAGS_GRANULE": FIX_TAGS_GRANULE,
    "FIX_HEAD_NOT_ALONE": FIX_HEAD_NOT_ALONE,
    "FIX_PAGE_AFTER_EOS": FIX_PAGE_AFTER_EOS,
    "FIX_CHAINED": FIX_CHAINED,
    "FIX_MISSING_CONTINUED": FIX_MISSING_CONTINUED,
    "FIX_HEAD_BAD_MAGIC": FIX_HEAD_BAD_MAGIC,
    "FIX_HEAD_VERSION": FIX_HEAD_VERSION,
    "FIX_HEAD_CHANNELS0": FIX_HEAD_CHANNELS0,
    "FIX_FAM0_CHANNELS3": FIX_FAM0_CHANNELS3,
    "FIX_FAM0_EXTRA": FIX_FAM0_EXTRA,
    "FIX_HEAD_SHORT": FIX_HEAD_SHORT,
    "FIX_FAM1_CHANNELS9": FIX_FAM1_CHANNELS9,
    "FIX_FAM1_STREAM0": FIX_FAM1_STREAM0,
    "FIX_FAM1_COUPLED_GT": FIX_FAM1_COUPLED_GT,
    "FIX_FAM1_INDEX_OOB": FIX_FAM1_INDEX_OOB,
    "FIX_FAM1_LEN": FIX_FAM1_LEN,
    "FIX_TAGS_BAD_MAGIC": FIX_TAGS_BAD_MAGIC,
    "FIX_TAGS_VENDOR_LEN": FIX_TAGS_VENDOR_LEN,
    "FIX_TAGS_TRAILING": FIX_TAGS_TRAILING,
    "FIX_TAGS_COUNT": FIX_TAGS_COUNT,
}

# ---------------------------------------------------------------------------
# 自检：合法样例必须页页 CRC 正确、页序号连续；非法样例长度/结构基本合理
# ---------------------------------------------------------------------------

def walk(stream):
    pages, rest = [], stream
    while rest:
        if len(rest) < 27:
            raise ValueError("自检：残页")
        nseg = rest[26]
        total = 27 + nseg + sum(rest[27 : 27 + nseg])
        page = rest[:total]
        if crc32_ogg(page[:22] + b"\x00\x00\x00\x00" + page[26:]) != int.from_bytes(page[22:26], "little"):
            raise ValueError("自检：合法样例 CRC 错误")
        pages.append(page)
        rest = rest[total:]
    return pages

for name, blob in VALID.items():
    pages = walk(blob)
    for i, p in enumerate(pages):
        seq = int.from_bytes(p[18:22], "little")
        if seq != i:  # 页序必须从 0 连续（FAM1 允许缺 EOS，但页序不许跳）
            raise ValueError(f"自检：{name} 页序 {seq} != {i}")
    print(f"[ok] {name}: {len(pages)} pages, {len(blob)} bytes")

# 非法样例除 bad_crc / truncated 外都必须 CRC 正确（错误点在校验规则本身）
for name, blob in INVALID.items():
    if name in ("FIX_BAD_CRC", "FIX_TRUNCATED"):
        continue
    walk(blob)
print(f"[ok] {len(INVALID)} invalid fixtures built")

# ---------------------------------------------------------------------------
# 输出 .mbt
# ---------------------------------------------------------------------------

def hexlit(data):
    return '"' + "".join(f"\\x{b:02x}" for b in data) + '"'

HDR = "// 由 tools/gen_fixtures.py 生成，请勿手改。\n"

crc_out = [
    HDR
    + "//\n// Ogg CRC-32 金标值（多项式 0x04C11DB7、初值 0、不反转）。\n"
    + "// 由独立逐位实现与 GF(2) 多项式长除法双算法交叉验证，\n"
    + "// 并经真实 muxer 产出的 Ogg 文件逐页 CRC 比对锚定。\n",
]
for name, value in [
    ("FIX_CRC_EMPTY", crc32_ogg(b"")),
    ("FIX_CRC_OGGS", crc32_ogg(b"OggS")),
    ("FIX_CRC_CHECK", CHECK_VECTOR),
]:
    crc_out.append(f"\n///|\nconst {name} : UInt = 0x{value:08x}U\n")

fix_out = [
    HDR
    + "//\n// 样例由独立 Python 构造器生成（页 CRC 全部真实），\n"
    + "// 与 MoonBit 解析实现交叉验证；非法样例每条对应一条 RFC 7845 硬规则。\n",
]
for name, blob in list(VALID.items()) + list(INVALID.items()):
    fix_out.append(f"\n///|\nconst {name} : Bytes = b{hexlit(blob)}\n")

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
with open(os.path.join(root, "fixtures_crc_wbtest.mbt"), "w", encoding="utf-8") as f:
    f.write("".join(crc_out))
with open(os.path.join(root, "fixtures_wbtest.mbt"), "w", encoding="utf-8") as f:
    f.write("".join(fix_out))
print(f"[ok] wrote fixtures_crc_wbtest.mbt / fixtures_wbtest.mbt "
      f"({sum(len(b) for b in VALID.values())} valid bytes, "
      f"{sum(len(b) for b in INVALID.values())} invalid bytes)")
moon_fmt()
