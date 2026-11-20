// updater/postgresql@13.swift —— 与 Formula/postgresql@13.rb 一一同名的检查器入口
// 版本跟 core 的 postgresql@13；原料用 EDB macOS x64 binaries zip。

import Foundation

@main
struct PostgresqlAT13Check {
    static func main() {
        runCheck(CheckConfig(
            formula: "postgresql@13",
            brewName: "postgresql@13",
            downloadURL: { "https://get.enterprisedb.com/postgresql/postgresql-\($0)-1-osx-binaries.zip" }))
    }
}
