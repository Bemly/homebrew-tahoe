// updater/fork-libpsl.swift —— 与 Formula/fork-libpsl.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `libpsl`。

import Foundation

@main
struct ForkLibpslCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-libpsl", brewName: "libpsl"))
    }
}
