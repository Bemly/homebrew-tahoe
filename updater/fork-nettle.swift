// updater/fork-nettle.swift —— 与 Formula/fork-nettle.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `nettle`。

import Foundation

@main
struct ForkNettleCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-nettle", brewName: "nettle"))
    }
}
