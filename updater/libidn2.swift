// updater/libidn2.swift —— 与 Formula/libidn2.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `libidn2`。

import Foundation

@main
struct Libidn2Check {
    static func main() {
        runCheck(CheckConfig(formula: "libidn2", brewName: "libidn2"))
    }
}
