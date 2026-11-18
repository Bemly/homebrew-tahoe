// updater/fork-libpng.swift —— 与 Formula/fork-libpng.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `libpng`。

import Foundation

@main
struct ForkLibpngCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-libpng", brewName: "libpng"))
    }
}
