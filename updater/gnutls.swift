// updater/gnutls.swift —— 与 Formula/gnutls.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `gnutls`。

import Foundation

@main
struct GnutlsCheck {
    static func main() {
        runCheck(CheckConfig(formula: "gnutls", brewName: "gnutls"))
    }
}
