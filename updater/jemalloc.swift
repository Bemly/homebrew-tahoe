// updater/jemalloc.swift —— 与 Formula/jemalloc.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `jemalloc`。

import Foundation

@main
struct JemallocCheck {
    static func main() {
        runCheck(CheckConfig(formula: "jemalloc", brewName: "jemalloc"))
    }
}
