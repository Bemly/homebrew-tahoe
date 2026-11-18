// updater/fork-pcre2.swift —— 与 Formula/fork-pcre2.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `pcre2`。

import Foundation

@main
struct ForkPcre2Check {
    static func main() {
        runCheck(CheckConfig(formula: "fork-pcre2", brewName: "pcre2"))
    }
}
