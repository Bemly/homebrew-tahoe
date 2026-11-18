// updater/fork-readline.swift —— 与 Formula/fork-readline.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `readline`。

import Foundation

@main
struct ForkReadlineCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-readline", brewName: "readline"))
    }
}
