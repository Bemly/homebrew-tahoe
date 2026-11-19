// updater/fork-little-cms2.swift —— 与 Formula/fork-little-cms2.rb 一一同名的检查器入口

import Foundation

@main
struct ForkLittleCms2Check {
    static func main() {
        runCheck(CheckConfig(formula: "fork-little-cms2", brewName: "little-cms2"))
    }
}
