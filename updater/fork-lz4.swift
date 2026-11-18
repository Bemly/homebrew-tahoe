// updater/fork-lz4.swift —— 与 Formula/fork-lz4.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `lz4`。

import Foundation

@main
struct ForkLz4Check {
    static func main() {
        runCheck(CheckConfig(formula: "fork-lz4", brewName: "lz4"))
    }
}
