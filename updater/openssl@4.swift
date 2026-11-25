// updater/openssl@4.swift —— 与 Formula/openssl@4.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `openssl@4`。

import Foundation

@main
struct OpensslAT4Check {
    static func main() {
        runCheck(CheckConfig(formula: "openssl@4", brewName: "openssl@4"))
    }
}
