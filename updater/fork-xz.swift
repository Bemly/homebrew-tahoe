// updater/fork-xz.swift —— 与 Formula/fork-xz.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `xz`。

import Foundation

@main
struct ForkXzCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-xz", brewName: "xz"))
    }
}
