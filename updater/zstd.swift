// updater/zstd.swift —— 与 Formula/zstd.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `zstd`。

import Foundation

@main
struct ZstdCheck {
    static func main() {
        runCheck(CheckConfig(formula: "zstd", brewName: "zstd"))
    }
}
