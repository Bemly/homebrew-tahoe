// updater/fork-sqlite.swift —— 与 Formula/fork-sqlite.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `sqlite`。

import Foundation

@main
struct ForkSqliteCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-sqlite", brewName: "sqlite"))
    }
}
