// updater/gettext.swift —— 与 Formula/gettext.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `gettext`。

import Foundation

@main
struct GettextCheck {
    static func main() {
        runCheck(CheckConfig(formula: "gettext", brewName: "gettext"))
    }
}
