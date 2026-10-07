# -*- coding: utf-8 -*-
"""生成 M3a 范围解码器的金标测试样例。

本脚本按 RFC 6716 §4.1 独立实现参考范围**解码**端（与 MoonBit 实现无
共享代码、不同语言、不同算法组织），对一批比特流执行固定的操作序列，
记录每步的符号与内部状态轨迹，供 MoonBit 解码端逐项复原并比对。

为什么用解码端而不是编码端做金标：§5.1 编码器的终结与进位传播（end 的
选取、rem/ext 的 flush 条件）在规范文字中存在实现自由度，自行推导容易
引入与规范不符的偏差；而 §4.1 解码端的公式是明确给出的。

「两端共同理解错」这类错误不在本脚本的覆盖范围内，由 M3b 的真实 libopus
比特流 PCM 差分兜底（任何解码错误都会让 PCM 完全失真）。

用法：
    python tools/gen_range_goldens.py
输出（写入仓库根目录，勿手改）：
    range_goldens_wbtest.mbt
"""
import os
import random
from _fmt import moon_fmt  # noqa: E402

MASK31 = 0x7FFFFFFF

# icdf 表（ftb=8，5 个符号）：icdf[k] = (1<<ftb) - fh[k]，以 0 结尾。
# MoonBit 测试侧使用同一张表（表本身是固定输入，不构成两端互证）。
ICDF_TABLE = [200, 150, 100, 40, 0]


def ilog(x):
    """RFC §1.1 的 ilog(v) = floor(log2(v)) + 1，即最高位位置（1-based）。

    注意这与「floor(log2(v))」不同；对 x>0 等价于 x.bit_length()。
    """
    return x.bit_length()


class RangeDecoder:
    """RFC 6716 §4.1 范围解码端参考实现。"""

    def __init__(self, data):
        self.data = data
        self.len = len(data)
        self.offs = 0          # 已消费的字节数（含首字节）
        self.leftover = 0      # 上一字节存留的 1 位
        self.val = 0
        self.rng = 0
        self.raw_pos = self.len   # raw bits 从尾部反向读
        self.raw_bits_read = 0
        # §4.1.1 初始化
        b0 = data[0] if self.len > 0 else 0
        self.leftover = b0 & 1
        self.val = 127 - (b0 >> 1)
        self.rng = 128
        self.offs = 1
        self._normalize()

    def _next_byte(self):
        if self.offs < self.len:
            b = self.data[self.offs]
        else:
            b = 0          # §4.1.2.1：读尽后补零
        self.offs += 1
        return b

    def _normalize(self):
        # §4.1.2.1：直到 rng > 2**23
        while self.rng <= (1 << 23):
            self.rng <<= 8
            nb = self._next_byte()
            sym = ((self.leftover << 7) | (nb >> 1)) & 0xFF
            self.leftover = nb & 1
            self.val = ((self.val << 8) + (255 - sym)) & MASK31

    def _decode(self, ft):
        # §4.1.2：ec_decode()
        d = self.rng // ft
        if d == 0:
            return ft
        return ft - min(self.val // d + 1, ft)

    def _update(self, fl, fh, ft):
        # §4.1.2：ec_dec_update()（val 不在此处掩码，掩码在 renormalization）
        s = self.rng // ft
        if fl > 0:
            self.val = self.val - s * (ft - fh)
            self.rng = s * (fh - fl)
        else:
            self.rng = self.rng - s * (ft - fh)
        self._normalize()

    def decode_ctx(self, freqs):
        """解一个由频率数组描述的上下文，返回真实符号 k（§4.1.2 搜索）。

        freqs[i] 是符号 i 的频率，其和即 ft；fl/fh 由累计和推出。
        符号由比特流决定，而非由调用方指定。
        """
        ft = sum(freqs)
        fs = self._decode(ft)
        fl = 0
        for k, f in enumerate(freqs):
            fh = fl + f
            if fl <= fs < fh:
                self._update(fl, fh, ft)
                return k
            fl = fh
        raise AssertionError(
            f"fs={fs} outside context [0,{ft}) — freqs={freqs}")

    def decode_bit_logp(self, logp):
        ft = 1 << logp
        fs = self._decode(ft)
        if fs < ft - 1:
            self._update(0, ft - 1, ft)
            return 0
        self._update(ft - 1, ft, ft)
        return 1

    def decode_bin(self, ftb):
        # §4.1.3.1：ec_decode_bin() 等价于 ft = 1<<ftb 的二元解码
        ft = 1 << ftb
        fs = self._decode(ft)
        if fs < ft - 1:
            self._update(0, ft - 1, ft)
            return 0
        self._update(ft - 1, ft, ft)
        return 1

    def decode_bin_fs(self, ftb):
        # §4.1.3.1：ec_decode_bin() 只算 fs、**不推进状态**，调用方自行
        # 用 (fl, fh, ft) 调 update——Laplace 解码正依赖这一点。
        return self._decode(1 << ftb)

    def decode_icdf(self, icdf, ftb):
        ft = 1 << ftb
        fs = self._decode(ft)
        # 找第一个 k 使 fs < ft - icdf[k]
        k = 0
        while k < len(icdf) - 1 and fs >= ft - icdf[k]:
            k += 1
        fl = 0 if k == 0 else ft - icdf[k - 1]
        fh = ft - icdf[k]
        self._update(fl, fh, ft)
        return k

    def decode_uint(self, ft):
        # §4.1.5
        ftb = ilog(ft - 1)
        if ftb <= 8:
            fs = self._decode(ft)
            k = fs
            assert 0 <= k < ft, f"uint symbol {k} out of [0,{ft})"
            self._update(k, k + 1, ft)
            return k
        top_ft = ((ft - 1) >> (ftb - 8)) + 1
        fs = self._decode(top_ft)
        hi = fs
        self._update(hi, hi + 1, top_ft)
        return ((hi << (ftb - 8)) | self.dec_bits(ftb - 8)) % ft

    def dec_bits(self, nbits):
        """§4.1.4：raw bits 从帧尾反向打包，LSB 起。"""
        val = 0
        for i in range(nbits):
            pos = self.raw_pos - 1 - (self.raw_bits_read // 8)
            bit_index = self.raw_bits_read % 8
            if pos < 0:
                bit = 0
            else:
                bit = (self.data[pos] >> bit_index) & 1
            val |= bit << i
            self.raw_bits_read += 1
        return val

    def nbits_total(self):
        # §4.1.6：整位数含缓冲位；初始化完成后为 33（= 8*4 + 1），
        # 每轮 renormalization +8，raw bits 读取数计入。
        return 8 * self.offs + 1 + self.raw_bits_read

    def tell(self):
        # §4.1.6.1：nbits_total - ilog(rng)
        return self.nbits_total() - ilog(self.rng)

    def tell_frac(self):
        # §4.1.6.2
        nbits_total = self.nbits_total()
        lg = ilog(self.rng)
        r_q15 = self.rng >> (lg - 16)
        for _ in range(3):
            r_q15 = (r_q15 * r_q15) >> 15
            lg = 2 * lg + (r_q15 >> 16)
            if (r_q15 >> 16) & 1:
                r_q15 >>= 1
        return nbits_total * 8 - lg


def build_cases():
    """金标用例：(名字, 比特流, 操作序列)。操作序列同时驱动 MoonBit 侧。"""
    cases = []
    rng = random.Random(20261006)

    def rand_bytes(n):
        return bytes(rng.randint(0, 255) for _ in range(n))

    # 用例 1：均匀 4 符号上下文（ft=16），符号由比特流决定
    syms4 = "4,4,4,4"
    cases.append(("uniform16", rand_bytes(64),
                  [("enc", syms4)] * 16))

    # 用例 2：bit_logp 变化
    ops2 = [("bit", lp) for lp in
            [1, 2, 3, 4, 5, 6, 7, 8, 1, 3, 5, 7, 2, 4, 6, 8, 3, 3, 1, 8]]
    cases.append(("bitlogp", rand_bytes(48), ops2))

    # 用例 3：icdf 表（ftb=8）
    ops3 = [("icdf", 8)] * 16
    cases.append(("icdf8", rand_bytes(48), ops3))

    # 用例 4：ec_dec_uint 两种分支
    ops4 = [("uint", 16), ("uint", 100), ("uint", 10000),
            ("uint", 70000), ("uint", 65536)]
    cases.append(("uint", rand_bytes(64), ops4))

    # 用例 5：混合
    ops5 = ([("bit", 3), ("bit", 3)]
            + [("icdf", 8)] * 7
            + [("uint", 32), ("bit", 8), ("bin", 4)]
            + [("enc", "8,8,8,8")] * 4)
    cases.append(("mixed", rand_bytes(80), ops5))

    # 用例 6：随机大量操作，压测重归一化与补零
    ops6 = []
    for _ in range(300):
        r = rng.random()
        if r < 0.35:
            ops6.append(("bit", rng.randint(1, 8)))
        elif r < 0.6:
            ftb = rng.randint(1, 8)
            ops6.append(("bin", ftb))
        elif r < 0.8:
            ctxs = ["1,1,1,1,1,1,1,1", "4,4,4,4", "1,2,3,10",
                    "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1"]
            ops6.append(("enc", rng.choice(ctxs)))
        elif r < 0.9:
            ft = rng.choice([5, 10, 100])
            ops6.append(("uint", ft))
        else:
            ft = rng.choice([1000, 70000, 65536])
            ops6.append(("uint", ft))
    cases.append(("random300", rand_bytes(128), ops6))

    # 用例 7：短流（越界补零路径）
    cases.append(("short", bytes([0x5A, 0xA5]),
                  [("bit", 2), ("enc", "1,1,1,1,1,1,1,1")]))

    # 用例 8：长流（raw bits 与范围数据重叠）
    ops8 = [("uint", 65536)] + [("bit", 4), ("enc", "4,4,4,4")] * 40
    cases.append(("long", rand_bytes(256), ops8))

    return cases


def run_trace(bits, ops):
    """用参考解码端跑完整操作序列，记录每步轨迹。

    ops 只描述要执行的操作（含其参数），**不带期望符号**——符号由比特流
    决定。期望值全部由本函数的参考解码端算出并写入轨迹，MoonBit 解码端
    执行同样的操作序列后逐项比对轨迹。
    """
    dec = RangeDecoder(bits)
    trace = []
    for op in ops:
        kind = op[0]
        if kind == "enc":
            freqs = tuple(int(x) for x in op[1].split(","))
            got = dec.decode_ctx(freqs)
        elif kind == "bit":
            got = dec.decode_bit_logp(op[1])
        elif kind == "bin":
            got = dec.decode_bin(op[1])
        elif kind == "icdf":
            got = dec.decode_icdf(ICDF_TABLE, op[1])
        elif kind == "uint":
            got = dec.decode_uint(op[1])
        elif kind == "rawbits":
            got = dec.dec_bits(op[1])
        else:
            raise ValueError(f"unknown op {kind}")
        trace.append((got, dec.rng, dec.val, dec.tell(), dec.tell_frac()))
    return trace


def emit_play(name, ops, trace):
    """把操作序列与期望轨迹输出为一个可编译的 MoonBit 函数。

    每步生成一次方法调用，期望值（sym, rng, val, tell, tell_frac）内联其中；
    rng/val 是 32 位无符号量（rng 可达 2**31），故带 Int64 后缀 L。
    """
    up = name.upper()
    out = [
        "",
        "///|",
        f"fn play_{name}(dec : RangeDecoder) -> Unit raise {{",
        f"  // 比特流见 RANGE_{up}_BITS；轨迹由 tools/gen_range_goldens.py",
        f"  // 的独立参考解码端算出，本函数重放同一操作并逐项比对。",
    ]
    for op, (sym, rng, val, tf, tff) in zip(ops, trace):
        kind = op[0]
        if kind == "enc":
            freqs = ", ".join(op[1].split(","))
            args = f"[{freqs}]"
            out.append(
                f"  dec.expect_ctx({args}, {sym}, {rng}L, {val}L, {tf}, {tff})"
            )
        elif kind == "bit":
            out.append(
                f"  dec.expect_bit({op[1]}, {sym}, {rng}L, {val}L, {tf}, {tff})"
            )
        elif kind == "bin":
            out.append(
                f"  dec.expect_bin({op[1]}, {sym}, {rng}L, {val}L, {tf}, {tff})"
            )
        elif kind == "icdf":
            out.append(
                f"  dec.expect_icdf({op[1]}, {sym}, {rng}L, {val}L, {tf}, {tff})"
            )
        elif kind == "uint":
            out.append(
                f"  dec.expect_uint({op[1]}, {sym}, {rng}L, {val}L, {tf}, {tff})"
            )
        else:
            raise ValueError(f"unhandled op kind {kind}")
    out.append("}")
    return chr(10).join(out) + chr(10)


def main():
    cases = build_cases()
    # 全部用 chr(92)/chr(10) 构造反斜杠与换行，避免任何转义被传输层折叠
    nl, bs = chr(10), chr(92)
    header = nl.join([
        "// 由 tools/gen_range_goldens.py 生成，请勿手改。",
        "//",
        "// 范围解码器（RFC 6716 §4.1）金标：比特流与逐轨迹期望值由本脚本内",
        "// 独立实现的参考解码端算出（不同语言、不同实现路径），MoonBit 解码端",
        "// 重放同一操作序列后逐项比对 (sym, rng, val, tell, tell_frac)。",
        "//",
        "// 端到端正确性另由 M3b 的真实 libopus 比特流 PCM 差分兜底——任何",
        "// 熵解码错误都会让解出的 PCM 完全失真。",
        "",
        "///|",
        "",
    ])
    lines = [header]
    for name, bits, ops in cases:
        trace = run_trace(bits, ops)
        up = name.upper()
        hexlit = '"' + "".join(bs + "x%02x" % b for b in bits) + '"'
        lines.append(
            nl.join(["", "///|", f"const RANGE_{up}_BITS : Bytes = b{hexlit}", ""])
        )
        lines.append(emit_play(name, ops, trace))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "range_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    print(f"[ok] {len(cases)} cases, wrote range_goldens_wbtest.mbt")
    moon_fmt()


if __name__ == "__main__":
    main()
