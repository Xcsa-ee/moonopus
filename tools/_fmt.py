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
