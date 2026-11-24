// updater/bdw-gc.swift —— 与 Formula/bdw-gc.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `bdw-gc`。

import Foundation

@main
struct BdwGcCheck {
    static func main() {
        runCheck(CheckConfig(formula: "bdw-gc", brewName: "bdw-gc"))
    }
}
