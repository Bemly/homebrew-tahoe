// updater/pkgconf.swift —— 与 Formula/pkgconf.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/pkgconf.swift -o /tmp/check-pkgconf && /tmp/check-pkgconf
// brew JSON 全量流：版本 / 上游直链 / sha256 全部取自 formulae.brew.sh JSON 的 urls.stable。

import Foundation

@main
struct PkgconfCheck {
    static func main() {
        runCheck(CheckConfig(formula: "pkgconf", brewName: "pkgconf"))
    }
}
