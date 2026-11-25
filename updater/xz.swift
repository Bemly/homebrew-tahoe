// updater/xz.swift —— 与 Formula/xz.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `xz`。

import Foundation

@main
struct XzCheck {
    static func main() {
        runCheck(CheckConfig(formula: "xz", brewName: "xz"))
    }
}
