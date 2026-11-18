// updater/fork-glib.swift —— 与 Formula/fork-glib.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `glib`。

import Foundation

@main
struct ForkGlibCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-glib", brewName: "glib"))
    }
}
