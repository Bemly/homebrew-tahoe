// updater/fork-python@3.14.swift —— 与 Formula/fork-python@3.14.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `python@3.14`。

import Foundation

@main
struct ForkPythonAT314Check {
    static func main() {
        runCheck(CheckConfig(formula: "fork-python@3.14", brewName: "python@3.14"))
    }
}
