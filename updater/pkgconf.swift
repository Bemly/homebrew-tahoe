// updater/pkgconf.swift —— 与 Formula/pkgconf.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `pkgconf`。

import Foundation

@main
struct PkgconfCheck {
    static func main() {
        runCheck(CheckConfig(formula: "pkgconf", brewName: "pkgconf"))
    }
}
