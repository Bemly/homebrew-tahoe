// updater/fork-brotli.swift —— 与 Formula/fork-brotli.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `brotli`。

import Foundation

@main
struct ForkBrotliCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-brotli", brewName: "brotli"))
    }
}
