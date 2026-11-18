// updater/fork-p11-kit.swift —— 与 Formula/fork-p11-kit.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `p11-kit`。

import Foundation

@main
struct ForkP11KitCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-p11-kit", brewName: "p11-kit"))
    }
}
