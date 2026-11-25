// updater/openssl@3.swift —— 与 Formula/openssl@3.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `openssl@3`。

import Foundation

@main
struct OpensslAT3Check {
    static func main() {
        runCheck(CheckConfig(formula: "openssl@3", brewName: "openssl@3"))
    }
}
