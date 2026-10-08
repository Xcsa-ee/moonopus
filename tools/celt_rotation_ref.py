# -*- coding: utf-8 -*-
"""RFC 6716 §4.3.4.3 展宽旋转的独立 Python 参考端。

与 MoonBit 侧的 celt_exp_rotation.mbt 走两条不同的代码路径：

  - 实现端把每个相位做成两条全局扫描（前向一路、回扫一路）就地更新；
  - 这里按步长把下标拆成 residue 链，逐链「先整链前向、再去掉链首对
    回扫」。依据是不相交的下标对可交换、链间顺序无关，而链内的相对
    顺序与全局扫描逐对一致（回扫上界 len-2σ-1 恰好等于前向集合去掉
    每链的最大元，两者始终差一个步长）。

数值路径也不同：c/s 走参考宏的结构——HALF16(g²)=g²/2 与
celt_cos_norm(x)=cos(π/2·x)，即 c = cos(π/2·g²/2)、s = cos(π/2·(1−g²/2))；
实现端走 RFC 结构 cos(πg²/4)、sin(πg²/4)。f_r 表这里是字面量。两侧同为
双精度；libopus 的 float32 舍入差异（约 1e-7 相对量）留给最终 PCM 差分。

系数与扫描方向照抄参考实现解码端：逐对映射为 [c, -s; s, c]，先交错相位
（系数 (s,c)）再主相位（系数 (c,s)），按时间块分段。
"""
import math

# RFC Table 59: spread → f_r；0 = 不旋转
SPREAD_FACTOR = [0, 15, 10, 5]


def rotation(x, b, k, spread):
    """返回旋转后的新数组，不修改入参。"""
    n = len(x)
    if spread == 0 or 2 * k >= n:
        return list(x)
    f = SPREAD_FACTOR[spread]
    g = n / (n + f * k)
    half = 0.5 * g * g  # 参考实现的 HALF16(gain*gain)
    c = math.cos(0.5 * math.pi * half)
    s = math.cos(0.5 * math.pi * (1.0 - half))
    stride2 = 0
    if n >= 8 * b:
        while (stride2 * stride2 + stride2) * b + (b >> 2) < n:
            stride2 += 1
    block = n // b
    out = list(x)
    for blk in range(b):
        base = blk * block
        if stride2 > 0:
            _sweep(out, base, block, stride2, s, c)
        _sweep(out, base, block, 1, c, s)
    return out


def _sweep(out, off, length, stride, c, s):
    """按 residue 链分解的成对扫描，逐对映射 [c, -s; s, c]（同实现端）。"""
    for r in range(stride):
        # 前向：i < length - stride 且 i ≡ r (mod stride)
        idx = list(range(r, length - stride, stride))
        for i in idx:
            _rot2(out, off + i, off + i + stride, c, s)
        # 回扫：前向集合去掉链内最大元，反向执行
        for i in reversed(idx[:-1]):
            _rot2(out, off + i, off + i + stride, c, s)


def _rot2(out, p, q, c, s):
    x1, x2 = out[p], out[q]
    out[q] = c * x2 + s * x1
    out[p] = c * x1 - s * x2


def norm2(x):
    return sum(v * v for v in x)
