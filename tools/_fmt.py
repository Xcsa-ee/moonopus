# -*- coding: utf-8 -*-
"""生成器收尾统一执行 moon fmt。

moon 的格式化规则（折行宽度、参数逐行展开等）没有公开接口，生成器不去
复刻它，而是在写完产物后直接调用 moon fmt——保证「生成即格式化」。否则
刚生成的文件会与 moon fmt --check（CI 的一项）不一致，必须再手动跑一遍。

用法：在各生成器 main() 的最后调用 moon_fmt()。
"""
import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def moon_num(v):
    """Double → MoonBit 字面量。

    MoonBit 的解析器不接受 `1e-6` 这种指数写法，所以 repr 里带指数时改用
    定点展开：34 位小数对 |v| ≥ 1e-16 恰好放得下 17 位有效数字，能精确
    往返。往不回去就直接报错，不静默产出变了值的字面量。
    """
    v = float(v)
    s = repr(v)
    if "e" in s or "E" in s:
        s = f"{v:.34f}".rstrip("0")
        if s.endswith("."):
            s += "0"
    if float(s) != v:
        raise ValueError(f"moon_num 无法往返: {s} != {v!r}")
    return s


def moon_fmt():
    try:
        subprocess.run(
            ["moon", "fmt"],
            cwd=ROOT,
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except FileNotFoundError:
        print("[warn] moon 不在 PATH，跳过格式化；提交前请手动运行 moon fmt")
    except subprocess.CalledProcessError:
        print("[warn] moon fmt 执行失败，请检查本次生成的产物")
