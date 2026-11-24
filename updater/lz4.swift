// updater/lz4.swift —— 与 Formula/lz4.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `lz4`。

import Foundation

@main
struct Lz4Check {
    static func main() {
        runCheck(CheckConfig(formula: "lz4", brewName: "lz4"))
    }
}
