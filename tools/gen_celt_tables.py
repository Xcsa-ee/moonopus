# -*- coding: utf-8 -*-
"""从 libopus 参考实现提取 RFC 6716 未列出的表数据，生成 MoonBit 常量。

RFC 6716 §4.3.3 明确要求比特分配 bit-exact，而 caps 表等数据 RFC 只给
索引方法、不给数值，要求实现者"直接使用同一表数据"（原文见 §4.3.3）。
本脚本从 xiph/opus（BSD-3-Clause）的源文件里机械提取这些表，避免手工
转录引入错误。

提取的表：
  - e_prob_model     能量粗量化的 Laplace 参数（quant_bands.c）
  - pred_coef 等     能量预测系数（quant_bands.c，float 构建）
  - cache_caps50     比特分配 caps 表（static_modes_float.h）
  - small_energy_icdf
并输出 RFC 表格（Table 55/57/58/59/60-63）的转录部分。

用法：python tools/gen_celt_tables.py
输出：celt_tables.mbt（生产源文件，解码实现与测试共用）
"""
import os
import math
import re
import sys

from _fmt import moon_fmt  # noqa: E402

SRC = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "..", "_research", "libopus",
)


def read_src(name):
    path = os.path.join(SRC, name)
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read()


def read_rfc():
    path = os.path.join(SRC, "..", "rfc6716.txt")
    if not os.path.exists(path):
        raise SystemExit(f"RFC 6716 not found at {path}")
    with open(path, encoding="utf-8", errors="replace") as f:
        return f.read()


def parse_rfc_tables(text):
    """从 RFC 6716 文本直接解析表格，避免手工转录出错。

    只解析结构特征明确、可用行数断言校验的表；行数或顺序不符即报错。
    """
    lines = text.split("\n")

    # Table 55: MDCT bins per band，21 行，形如
    #   | 0      |      1 |    2 |     4 |     8 |        0 Hz |     200 Hz |
    band_pat = re.compile(
        r"^\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|\s*"
        r"(\d+)\s*\|\s*\d+ Hz\s*\|\s*\d+ Hz\s*\|")
    band_rows = []
    for ln in lines:
        m = band_pat.match(ln)
        if m:
            band_rows.append(tuple(int(m.group(i)) for i in range(1, 6)))
    if len(band_rows) != 21:
        raise SystemExit(f"Table 55: got {len(band_rows)} rows, want 21")
    if [r[0] for r in band_rows] != list(range(21)):
        raise SystemExit("Table 55: band indices not 0..20")

    # Table 57: static allocation，21 行 × 11 列
    alloc_pat = re.compile(r"^\s*\|\s*(\d+(?:\s*\|\s*\d+){10})\s*\|\s*$")
    alloc_rows = []
    for ln in lines:
        m = alloc_pat.match(ln)
        if m:
            vals = [int(x) for x in re.findall(r"\d+", m.group(1))]
            if len(vals) == 11:
                alloc_rows.append(vals)
    # 表头 `| 0 | 1 | ... | 10 |` 的形状与数据行完全一致，必须剔除
    alloc_rows = [r for r in alloc_rows if r != list(range(11))]
    if len(alloc_rows) != 21:
        raise SystemExit(f"Table 57: got {len(alloc_rows)} rows, want 21")

    # Table 60-63: TF 调整，四组各 4 行（2.5/5/10/20 ms × tf_select 0/1）
    tf_pat = re.compile(
        r"^\s*\|\s*(2\.5|5|10|20)\s*\|\s*(-?\d+)\s*\|\s*(-?\d+)\s*\|\s*$")
    tf_rows = []
    for ln in lines:
        m = tf_pat.match(ln)
        if m:
            tf_rows.append((float(m.group(1)), int(m.group(2)), int(m.group(3))))
    if len(tf_rows) != 16:
        # SILK 章节里存在形状完全相同的行，全篇扫描会混进杂项。按预期
        # 顺序（四组 2.5/5/10/20 ms）取出第一段连续 16 行，取不到即失败。
        seq = [2.5, 5, 10, 20] * 4
        run = next(
            (tf_rows[s:s + 16] for s in range(len(tf_rows))
             if [r[0] for r in tf_rows[s:s + 16]] == seq),
            None,
        )
        if run is None:
            raise SystemExit(
                f"Table 60-63: no contiguous 16-row run in {len(tf_rows)} hits")
        tf_rows = run
    if [r[0] for r in tf_rows] != [2.5, 5, 10, 20] * 4:
        raise SystemExit(f"Table 60-63: frame-size order wrong: "
                         f"{[r[0] for r in tf_rows]}")

    # Table 58: allocation trim 的 PDF，取表题之前最近的一个 {…}/N
    trim_idx = None
    for i, ln in enumerate(lines):
        if "Table 58" in ln and "Trim" in ln:
            trim_idx = i
            break
    if trim_idx is None:
        raise SystemExit("Table 58 not found")
    trim_pdf = trim_den = None
    for ln in reversed(lines[:trim_idx]):
        m = re.search(r"\{\s*([\d,\s]+)\}\s*/\s*(\d+)", ln)
        if m:
            trim_pdf = [int(x) for x in m.group(1).split(",")]
            trim_den = int(m.group(2))
            break
    if not trim_pdf or len(trim_pdf) != 11 or trim_den != 128:
        raise SystemExit(f"Table 58 bad: {trim_pdf}/{trim_den}")

    return {
        # 21 bands × 4 帧长（2.5/5/10/20 ms）
        "band_bins": [[r[1], r[2], r[3], r[4]] for r in band_rows],
        # 21 bands × 11 quality（单位 1/32 bit per MDCT bin）
        "alloc": alloc_rows,
        # 四组 TF 调整：non-transient/tf0, non-transient/tf1,
        #              transient/tf0, transient/tf1
        "tf": tf_rows,
        # Table 58：allocation trim 的 PDF（11 项，分母 128）
        "trim_pdf": trim_pdf,
        "trim_den": trim_den,
    }


def brace_body(text, open_pos):
    """从 open_pos 处的 '{' 做括号配平，返回其内部文本。"""
    depth = 0
    i = open_pos
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[open_pos + 1 : i]
        i += 1
    raise SystemExit("unbalanced braces")


def extract_array(text, name, prefer_frac=False):
    """提取 C 数组字面量的内容（支持嵌套大括号），返回扁平数值列表。

    只处理我们已知的这几张表，不做通用 C 解析——出现意外格式直接报错，
    宁可失败也不要悄悄产出错误数据。

    quant_bands.c 里 pred_coef/beta_coef 有 FIXED_POINT 与 float 两组定义，
    `prefer_frac=True` 选**自身数组体**含 `/` 的 float 组（本项目走浮点
    解码，与 soundfile/libopus 的 float 构建一致）。
    """
    pat = re.compile(
        r"(?:static\s+)?(?:const\s+)?[\w\s\*]+?\b" + re.escape(name) +
        r"\s*(?:\[[^\]]*\]\s*)+=\s*\{", re.S)
    matches = list(pat.finditer(text))
    if not matches:
        raise SystemExit(f"table {name} not found")
    # 先对每个候选配平取 body，再按需筛选——避免用固定窗口误判跨到相邻定义
    candidates = [(m, brace_body(text, m.end() - 1)) for m in matches]
    if prefer_frac:
        frac = [(m, b) for m, b in candidates if "/" in b]
        if not frac:
            raise SystemExit(f"table {name}: no fractional (float) definition")
        m, raw_body = frac[0]
    else:
        m, raw_body = candidates[0]
    body = raw_body
    # 去掉注释
    body = re.sub(r"/\*.*?\*/", " ", body, flags=re.S)
    body = re.sub(r"//[^\n]*", " ", body)
    # 收集所有数值字面量（含 0x、负号、小数点、科学计数、除法表达式）
    vals = []
    for tok in re.finditer(
        # 分数分支必须排在最前，否则 `29440/32768.` 会被拆成两个 token
        r"[-+]?(?:\d+/\d+\.?|\d+/\d+|0[xX][0-9a-fA-F]+|\d+\.?\d*(?:[eE][-+]?\d+)?)",
        body,
    ):
        t = tok.group(0)
        if "/" in t:
            # 形如 29440/32768. 的浮点常量
            a, b = t.rstrip(".").split("/")
            vals.append(float(a) / float(b))
        elif t.lower().startswith("0x"):
            vals.append(int(t, 16))
        elif "." in t or "e" in t.lower():
            vals.append(float(t))
        else:
            vals.append(int(t))
    if not vals:
        raise SystemExit(f"table {name}: no values parsed")
    return vals


def extract_scalar(text, name):
    """提取标量常量（如 `beta_intra = 4915/32768.;`），支持分数表达式。

    同名可能有 FIXED_POINT 与 float 两份定义，取含 `/` 的 float 版本。
    """
    pat = re.compile(
        r"\b" + re.escape(name) + r"\s*=\s*([^;]+);")
    cands = [m.group(1).strip() for m in pat.finditer(text)]
    frac = [c for c in cands if "/" in c]
    expr = frac[0] if frac else (cands[0] if cands else None)
    if expr is None:
        raise SystemExit(f"scalar {name} not found")
    # 形如 "4915/32768." 或纯数字
    m = re.fullmatch(r"([-+]?\d+)\s*/\s*([\d.]+)", expr)
    if m:
        return float(m.group(1)) / float(m.group(2))
    if re.fullmatch(r"[-+]?(\d+\.?\d*|\d*\.\d+)", expr):
        return float(expr)
    raise SystemExit(f"scalar {name}: unhandled expression {expr!r}")


def main():
    qb = read_src("celt_quant_bands.c")
    smf = read_src("celt_static_modes_float.h")

    e_prob = extract_array(qb, "e_prob_model")
    pred = extract_array(qb, "pred_coef", prefer_frac=True)
    beta = extract_array(qb, "beta_coef", prefer_frac=True)
    beta_intra = extract_scalar(qb, "beta_intra")
    small_icdf = extract_array(qb, "small_energy_icdf")
    caps = extract_array(smf, "cache_caps50")

    # 结构断言——形状错了后面的解码必然错，先在这里拦住
    assert len(e_prob) == 4 * 2 * 42, f"e_prob_model {len(e_prob)} != 336"
    assert len(pred) == 4, f"pred_coef {len(pred)}"
    assert len(beta) == 4, f"beta_coef {len(beta)}"
    assert len(caps) == 168, f"cache_caps50 {len(caps)} != 168"
    assert all(0 <= v <= 255 for v in e_prob), "e_prob_model out of range"
    assert all(0 <= v <= 255 for v in caps), "cache_caps50 out of range"
    # 预测系数是 Q15 小数（float 构建）
    assert all(0.0 < v < 1.0 for v in pred), f"pred_coef {pred}"
    assert all(0.0 < v < 1.0 for v in beta), f"beta_coef {beta}"
    assert 0.0 < beta_intra < 1.0, f"beta_intra {beta_intra}"
    # 三者在 float 构建里都是 k/32768（精确可表示的二进制分数）；若提取到
    # 的不是这种形式，说明取错了分支，而小数位截断会引入能量预测误差并
    # 可能翻转 bit-exact 的比特分配——所以既断言形状，也断言可精确往返。
    q15 = pred + beta + [beta_intra]
    assert all(v * 32768.0 == int(v * 32768.0) for v in q15), f"not Q15: {q15}"
    assert all(repr(float(v)) and float(repr(v)) == v for v in q15), "repr lossy"

    # 比特分配（§4.3.3）要用的两张表，各自与 RFC 正文做交叉核对——两边
    # 来源不同（RFC 正文 vs 参考实现源码），对不上说明有一侧读错了。
    rfc = parse_rfc_tables(read_rfc())
    alloc_vectors = extract_array(read_src("celt_modes.c"), "band_allocation")
    log_n = extract_array(read_src("celt_static_modes_float.h"), "logN400")
    assert len(alloc_vectors) == 11 * 21, f"band_allocation {len(alloc_vectors)}"
    assert len(log_n) == 21, f"logN400 {len(log_n)}"
    # RFC Table 57 是「带 × q」，band_allocation 是「q × 带」，转置后逐项
    # 必须相等（本模式 Fs=400×120=48000 命中参考实现的 standard mode 分支，
    # allocVectors 即 band_allocation 原样使用，不做插值）。
    for b in range(21):
        for q in range(11):
            assert rfc["alloc"][b][q] == alloc_vectors[q * 21 + b], (
                f"Table 57 mismatch at band {b} q {q}: "
                f"{rfc['alloc'][b][q]} != {alloc_vectors[q * 21 + b]}")
    # logN 是 log2(带宽) 的 8 倍向上取整；带宽取自 RFC Table 55 的 2.5ms
    # 列，故这条断言把 logN 也锚在了规范正文上。
    for i in range(21):
        n = rfc["band_bins"][i][0]
        assert log_n[i] == math.ceil(8 * math.log2(n)), (
            f"logN[{i}]={log_n[i]} != ceil(8*log2({n}))")
    # Table 58 的 PDF 累积后取补，即 ec_dec_icdf 用的表；必须与参考实现的
    # trim_icdf 逐项相等（两边来源不同：RFC 正文 vs celt_celt.h）。
    trim_icdf = extract_array(read_src("celt_celt.h"), "trim_icdf")
    assert len(trim_icdf) == 11, f"trim_icdf {len(trim_icdf)}"
    derived, acc = [], 0
    for p in rfc["trim_pdf"]:
        acc += p
        derived.append(rfc["trim_den"] - acc)
    assert derived == trim_icdf, f"Table 58 vs trim_icdf: {derived} != {trim_icdf}"

    lines = [
        "// 由 tools/gen_celt_tables.py 生成，请勿手改。",
        "//",
        "// 以下表数据提取自 xiph/opus 参考实现：RFC 6716 §4.3.3 要求比特",
        "// 分配 bit-exact，并明文要求实现者「直接使用同一表数据」，但未在",
        "// 正文中列出这些数值。提取由脚本机械完成并附结构断言。",
        "//",
        "// 版权归属（BSD-3-Clause，见仓库 LICENSE-LIBOPUS）：",
        "// Copyright 2001-2023 Xiph.Org, Skype Limited, Octasic,",
        "// Jean-Marc Valin, Timothy B. Terriberry, CSIRO, Gregory Maxwell,",
        "// Mark Borgerding, Erik de Castro Lopo, Mozilla, Amazon",
        "// 来源文件 celt/quant_bands.c 自带的声明：",
        "// Copyright (c) 2007-2008 CSIRO",
        "// Copyright (c) 2007-2009 Xiph.Org Foundation",
        "// Written by Jean-Marc Valin",
        "",
    ]

    def emit_flat(name, vals, kind, doc):
        lines.append("///|")
        lines.append(f"/// {doc}")
        if kind == "byte":
            body = ", ".join(str(int(v)) for v in vals)
            lines.append(f"let {name} : Array[Byte] = [{body}]")
        elif kind == "int":
            # icdf 表要喂给 RangeDecoder::decode_icdf(Array[Int], ftb)
            body = ", ".join(str(int(v)) for v in vals)
            lines.append(f"let {name} : Array[Int] = [{body}]")
        else:
            # 用 repr 而非定点格式：Q15 值（k/32768）的十进制展开可能超过
            # 6 位，定点截断会改变数值本身（如 0.8984375 → 0.898438）。
            body = ", ".join(repr(float(v)) for v in vals)
            lines.append(f"let {name} : Array[Double] = [{body}]")
        lines.append("")

    emit_flat(
        "cel_e_prob_model", e_prob, "byte",
        "能量粗量化 Laplace 参数（4 LM × 2 intra/inter × 42=21 带 × 2）。",
    )
    emit_flat(
        "cel_pred_coef", pred, "float",
        "帧间能量预测系数 alpha（按 LM 索引，Q15 已归一化为小数）。",
    )
    emit_flat(
        "cel_beta_coef", beta, "float",
        "帧内能量预测系数 beta（按 LM 索引）。",
    )
    lines.append("///|")
    lines.append("/// 帧内能量预测的固定 beta（§4.3.2.1 的 beta=4915/32768）。")
    lines.append(f"const CEL_BETA_INTRA : Double = {float(beta_intra)!r}")
    lines.append("")
    lines.append("///|")
    lines.append("/// 小能量细化的 icdf 表（quant_bands.c small_energy_icdf）。")
    lines.append(
        "let cel_small_energy_icdf : Array[Int] = ["
        + ", ".join(str(int(v)) for v in small_icdf) + "]"
    )
    lines.append("")
    emit_flat(
        "cel_cache_caps50", caps, "byte",
        "比特分配 caps 表 [168]（§4.3.3 指定直接使用的表数据）。",
    )
    emit_flat(
        "cel_alloc_vectors", alloc_vectors, "int",
        "静态分配表（§4.3.3 Table 57），按 q 主序 × 21 带展开的 11×21；"
        "单位 1/32 bit per MDCT bin。与 RFC 正文转置后逐项相等（见上）。",
    )
    emit_flat(
        "cel_log_n", log_n, "int",
        "log2(带宽)×8 向上取整（21 项），逐项等于由 RFC Table 55 带宽推出的值。",
    )
    emit_flat(
        "cel_trim_icdf", derived, "int",
        "allocation trim 的 icdf（11 项 → 0..10），由 RFC Table 58 的 PDF "
        "累积取补得到，与参考实现的 trim_icdf 逐项相等。",
    )

    out = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "celt_tables.mbt",
    )
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    print(
        f"[ok] e_prob={len(e_prob)} pred={len(pred)} beta={len(beta)} "
        f"caps={len(caps)} small_icdf={len(small_icdf)} -> celt_tables.mbt"
    )

    # RFC 正文表格单独落到测试侧文件：数据来自 RFC 文本，与从 libopus
    # 源码手写的实现（celt_mode.mbt 的 eband5ms 等）分属两条来源，
    # 测试拿两边一比就能抓住任一侧的读取错误。
    #
    # Table 57（静态分配）与 Table 60-63（TF 调整）在这里一并解析并断言
    # 结构，但要等比特分配 / 瞬态解码落地后才会有消费方，故暂不输出，
    # 免得留下未使用的顶层值。
    band_bins = [v for row in rfc["band_bins"] for v in row]
    assert len(band_bins) == 21 * 4, len(band_bins)
    rfc_out = [
        "// 由 tools/gen_celt_tables.py 生成，请勿手改。",
        "//",
        "// RFC 6716 Table 55 的每带 MDCT bin 数，按「带 × 帧长(2.5/5/10/20",
        "// ms)」展开成 84 项。",
        "//",
        "// 这份数据直接解析自 RFC 正文，与实现侧从 libopus eband5ms 推出的",
        "// celt_band_bins 分属两条来源；测试把两边逐项比对，任一侧读错都会",
        "// 立刻暴露。",
        "",
        "///|",
        "let cel_rfc_band_bins : Array[Int] = [",
        "  " + ", ".join(str(v) for v in band_bins),
        "]",
        "",
    ]
    rfc_path = os.path.join(
        os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
        "celt_rfc_goldens_wbtest.mbt",
    )
    with open(rfc_path, "w", encoding="utf-8") as f:
        f.write("\n".join(rfc_out))
    print(f"[ok] rfc band_bins={len(band_bins)} -> celt_rfc_goldens_wbtest.mbt")
    moon_fmt()


if __name__ == "__main__":
    main()
