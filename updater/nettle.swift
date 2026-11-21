// updater/nettle.swift —— 与 Formula/nettle.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `nettle`。

import Foundation

@main
struct NettleCheck {
    static func main() {
        runCheck(CheckConfig(formula: "nettle", brewName: "nettle"))
    }
}
