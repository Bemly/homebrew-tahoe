// updater/pixman.swift —— 与 Formula/pixman.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `pixman`。

import Foundation

@main
struct PixmanCheck {
    static func main() {
        runCheck(CheckConfig(formula: "pixman", brewName: "pixman"))
    }
}
