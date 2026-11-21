// updater/c-ares.swift —— 与 Formula/c-ares.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `c-ares`。

import Foundation

@main
struct CAresCheck {
    static func main() {
        runCheck(CheckConfig(formula: "c-ares", brewName: "c-ares"))
    }
}
