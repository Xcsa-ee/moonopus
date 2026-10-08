# -*- coding: utf-8 -*-
"""对 band 级量化解码（§4.3.4）做变异验证：注入一处错误 -> 跑 moon test -> 还原。

判据是「测试必须变红」。若某个变异跑完仍是绿的，说明对应的实现细节
没有被任何测试覆盖，需要补测试。
"""
import io
import subprocess
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

MUT = [
    ("celt_quant_band.mbt",
     "if rem >= 1 << CEL_BITRES {",
     "if rem > 0 {",
     "n=1 符号位读取门槛从 8 收到 1"),
    ("celt_quant_band.mbt",
     "x[0] = if sign != 0 { -1.0 } else { 1.0 }",
     "x[0] = 1.0",
     "n=1 符号位极性被抹平"),
    ("celt_quant_band.mbt",
     "f = cel_bit_interleave[f & 0xF] | (cel_bit_interleave[f >> 4] << 2)",
     "f = cel_bit_interleave[f & 0x7] | (cel_bit_interleave[f >> 4] << 2)",
     "fill 交织表索引掩码 0xF 改 0x7"),
    ("celt_quant_band.mbt",
     "c = c | (c >> bb)",
     "c = c & (c >> bb)",
     "cm 展开从或运算改成与运算"),
    ("celt_quant_band.mbt",
     "c & ((1 << bb) - 1)",
     "c & ((1 << (bb + 1)) - 1)",
     "cm 最终掩蔽位宽多 1 位"),
    ("celt_quant_band.mbt",
     "    celt_tf_forward(lowband, n, blocks, tf_change)",
     "    if false {\n      celt_tf_forward(lowband, n, blocks, tf_change)\n    }",
     "折叠源的前向 TF 变换被跳过"),
    ("celt_quant_band.mbt",
     "has_lowband: lowband.length() > 0,",
     "has_lowband: false,",
     "折叠源判定被钉死为无"),
    ("celt_quant_band.mbt",
     "    lay.b_end,\n    fill_tf,",
     "    blocks,\n    fill_tf,",
     "下传 partition 的 B 用带级原值而非 TF 调整后的值"),
    ("celt_quant_band.mbt",
     "let s = @math.pow(n.to_double(), 0.5)",
     "let s = @math.pow(n.to_double(), 0.25)",
     "lowband_out 的 sqrt(N0) 缩放改成四次方根"),
    ("celt_partition.mbt",
     "(iv >> 20).to_double()",
     "(iv >> 19).to_double()",
     "噪声样本的右移 20 改 19"),
    ("celt_partition.mbt",
     "mask = mask | (1 << i)",
     "mask = mask | (1 << (i + 1))",
     "塌缩位图的块序号左移多 1 位"),
    ("celt_partition.mbt",
     "let g = gain / @math.pow(yy, 0.5)",
     "let g = gain / @math.pow(yy, 1.0)",
     "叶归一化的 √Σy² 改成 Σy²"),
    ("celt_partition.mbt",
     "ctx.x[x_off + j] = pulses[j].to_double() * g",
     "ctx.x[x_off + j] = pulses[j].to_double()",
     "叶归一化丢掉增益 g"),
    ("celt_partition.mbt",
     "celt_rotate_band(ctx.x, x_off, n, blocks, k, ctx.spread)",
     "celt_rotate_band(ctx.x, x_off, n, blocks, k + 1, ctx.spread)",
     "旋转的脉冲数 k 多 1"),
    ("celt_partition.mbt",
     "ctx.x[x_off + j] = 0.0",
     "ctx.x[x_off + j] = 1.0",
     "fill=0 清零写成 1"),
    ("celt_partition.mbt",
     "0.00390625",
     "0.0078125",
     "折叠微扰 1/256 加倍"),
    ("celt_partition.mbt",
     "(ctx.seed[0] & 0x8000L) != 0L {",
     "(ctx.seed[0] & 0x8000L) == 0L {",
     "折叠微扰符号判定取反"),
    ("celt_partition.mbt",
     "ctx.x[x_off + j] = celt_fill_sample(ctx.seed[0])",
     "ctx.x[x_off + j] = celt_fill_sample(ctx.seed[0] ^ 0x100000L)",
     "噪声样本取错 seed 位段（bit20 翻转）"),
    ("celt_partition.mbt",
     "      leaf_cm = f\n",
     "      leaf_cm = 0\n",
     "折叠路径的 cm 丢掉 fill 位"),
]


def run_test():
    r = subprocess.run(
        ["moon", "test"], capture_output=True, text=True, encoding="utf-8",
        errors="replace")
    return (r.stdout or "") + (r.stderr or "")


def main():
    results = []
    for path, old, new, desc in MUT:
        src = io.open(path, encoding="utf-8").read()
        if old not in src:
            results.append(("SKIP", desc, "锚点未找到"))
            continue
        try:
            io.open(path, "w", encoding="utf-8", newline="").write(
                src.replace(old, new, 1))
            out = run_test()
        finally:
            io.open(path, "w", encoding="utf-8", newline="").write(src)
        line = ""
        for l in out.splitlines():
            if "Total tests" in l:
                line = l.strip()
        if "failed: 0" in out and "Total tests" in out:
            results.append(("GREEN", desc, line))
        elif "Total tests" in out:
            results.append(("RED  ", desc, line))
        else:
            results.append(("COMPILE", desc, out.strip().splitlines()[-1][:110]
                            if out.strip() else ""))
    width = max(len(d) for _, d, _ in results)
    for status, desc, info in results:
        print(f"{status:8} {desc:<{width}}  {info}")
    bad = [d for s, d, _ in results if s == "GREEN"]
    if bad:
        print("\n未被抓住的变异：", bad)
        raise SystemExit(1)
    print("\n全部变异均被测试捕获。")


if __name__ == "__main__":
    main()
