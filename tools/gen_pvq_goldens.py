# -*- coding: utf-8 -*-
"""生成 PVQ 脉冲解码（RFC 6716 §4.3.4.2）的 MoonBit 金标。

参考端在 tools/celt_pvq_ref.py（独立实现，V 用带缓存的递归），本文件负责
挑用例、生成 MoonBit 调用行与 test 块。

用例按 V(N,K) 的**区间**挑选，而不是按 (N,K) 硬编码——V 决定码字下标要
多少位，正是 decode_uint64 那条路径的分界：
  - V <= 2**31-1：走原有位宽
  - V >  2**31-1：越过 Int，必须用 64 位（96,5 就是这样）
  - V >  2**32  ：已超出 §4.3.4.4 的 codebook 上限，正常流由 split 避开；
                  这里仍收一个用例，验证索引解码不溢出
"""
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_range_goldens import RangeDecoder  # noqa: E402
from celt_pvq_ref import decode_pulses, pvq_v  # noqa: E402
from _fmt import moon_fmt  # noqa: E402


def rand_bytes(nbytes, seed):
    rs = random.Random(seed)
    return bytes(rs.randrange(256) for _ in range(nbytes))


def merge(dst, src):
    for k, v in src.items():
        dst[k] = dst.get(k, 0) + v


def find_pair(pred, nmax=200, kmax=40):
    """按码字总数挑一对 (n,k)，比按维度硬编码更能说明意图。"""
    for n in range(1, nmax + 1):
        for k in range(1, kmax + 1):
            v = pvq_v(n, k)
            if pred(v):
                return n, k, v
    raise SystemExit("no (n,k) satisfies the predicate")


class Case:
    def __init__(self, name, label, data, n, k):
        self.name = name
        self.label = label
        self.data = data
        self.n = n
        self.k = k
        self.v = pvq_v(n, k) if k > 0 else 0
        self.dec = RangeDecoder(data)
        self.diag = {}
        self.result = decode_pulses(self.dec, n, k, self.diag)
        self.call = f"celt_decode_pulses(dec, {n}, {k})"

    @property
    def state(self):
        d = self.dec
        return (d.rng, d.val, d.tell(), d.tell_frac())


def build_cases():
    cases = []
    diag = {}
    seq = 0

    def add(label, n, k, seed=0):
        nonlocal seq
        c = Case("p%d" % seq, label, rand_bytes(64, 30000 + seed), n, k)
        merge(diag, c.diag)
        cases.append(c)
        seq += 1
        return c

    # 位宽区间各取一例，标签里带上码字总数便于核对
    n31, k31, v31 = find_pair(lambda v: v <= 0x7FFFFFFF)
    add(f"小码本 V={v31} (N={n31},K={k31})", n31, k31, 1)

    n32, k32, v32 = find_pair(lambda v: v > 0x7FFFFFFF and v <= 0xFFFFFFFF)
    add(f"越过 Int32 的码本 V={v32} (N={n32},K={k32})", n32, k32, 2)

    n64, k64, v64 = find_pair(lambda v: v > 0xFFFFFFFF)
    add(f"超出 32 bits 上限 V={v64} (N={n64},K={k64})", n64, k64, 3)

    # 常见组合：短带到长带
    for n, k in [(1, 1), (8, 0), (8, 3), (12, 6), (48, 4), (176, 2), (176, 5),
                 (176, 0), (20, 8)]:
        add(f"N={n} K={k} V={pvq_v(n, k)}", n, k, 10 + seq)

    need = ["p_calls", "p_k_zero", "p_ft_32bit", "p_ft_over32"]
    missing = [k for k in need if k not in diag]
    if missing:
        raise SystemExit(f"pvq coverage incomplete: {missing}")
    return cases, diag


def fmt_bytes(data):
    return 'b"' + "".join("\\x%02x" % b for b in data) + '"'


def fmt_arr(vals):
    return "[" + ", ".join(str(int(v)) for v in vals) + "]"


def emit_case(case):
    rng, val, tell, tf_frac = case.state
    out = ["", "///|",
           f"fn play_{case.name}(dec : RangeDecoder) -> Unit raise " + "{"]
    out.append(f"  // 载荷见 PVQ_{case.name.upper()}_BITS；期望值由")
    out.append("  // tools/gen_pvq_goldens.py 的独立参考端算出。")
    out.append("  let got = " + case.call)
    out.append(f'  expect_pulses(got, {fmt_arr(case.result)}, "{case.name}")')
    out.append(f'  expect_dec_state(dec, "{case.name}", {rng}L, {val}L, '
               f"{tell}, {tf_frac})")
    out.append("}")
    out.append("")
    return "\n".join(out)


def emit_test(case):
    return "\n".join([
        "",
        "///|",
        f'test "金标：PVQ 脉冲 · {case.label}" {{',
        f"  let dec = RangeDecoder::new(PVQ_{case.name.upper()}_BITS)",
        f"  play_{case.name}(dec)",
        "}",
        "",
    ])


def main():
    cases, diag = build_cases()
    lines = [
        "\n".join([
            "// 由 tools/gen_pvq_goldens.py 生成，请勿手改。",
            "//",
            "// PVQ 脉冲解码（RFC 6716 §4.3.4.2）金标：载荷与期望向量由本脚本",
            "// 内的独立参考端算出（V 用带缓存的递归，与实现端的动态规划不同",
            "// 法），MoonBit 端重放后逐项比对。",
            "//",
            "// 用例按码字总数 V(N,K) 的区间挑选，覆盖 Int32 之内、之外以及",
            "// 超出 §4.3.4.4 的 32 bits 上限三种情况。",
            "",
            "///|",
            "",
        ]),
    ]
    for case in cases:
        lines.append("\n".join([
            "",
            "///|",
            f"const PVQ_{case.name.upper()}_BITS : Bytes = "
            f"{fmt_bytes(case.data)}",
            "",
        ]))
        lines.append(emit_case(case))
        lines.append(emit_test(case))
    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "pvq_goldens_wbtest.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("".join(lines))
    keys = " ".join(f"{k}={v}" for k, v in sorted(diag.items()))
    print(f"[ok] {len(cases)} cases -> pvq_goldens_wbtest.mbt")
    print(f"[cov] {keys}")
    moon_fmt()


if __name__ == "__main__":
    main()
