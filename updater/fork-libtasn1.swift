// updater/fork-libtasn1.swift —— 与 Formula/fork-libtasn1.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `libtasn1`。

import Foundation

@main
struct ForkLibtasn1Check {
    static func main() {
        runCheck(CheckConfig(formula: "fork-libtasn1", brewName: "libtasn1"))
    }
}
