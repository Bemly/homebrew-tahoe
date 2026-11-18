// updater/fork-lzo.swift —— 与 Formula/fork-lzo.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `lzo`。

import Foundation

@main
struct ForkLzoCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-lzo", brewName: "lzo"))
    }
}
