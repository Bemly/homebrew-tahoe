// updater/sqlite.swift —— 与 Formula/sqlite.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `sqlite`。

import Foundation

@main
struct SqliteCheck {
    static func main() {
        runCheck(CheckConfig(formula: "sqlite", brewName: "sqlite"))
    }
}
