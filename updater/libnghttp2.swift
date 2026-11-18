// updater/libnghttp2.swift —— 与 Formula/libnghttp2.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `libnghttp2`。

import Foundation

@main
struct Libnghttp2Check {
    static func main() {
        runCheck(CheckConfig(formula: "libnghttp2", brewName: "libnghttp2"))
    }
}
