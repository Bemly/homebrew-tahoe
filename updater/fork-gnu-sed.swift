// updater/fork-gnu-sed.swift —— 与 Formula/fork-gnu-sed.rb 一一同名的检查器入口

import Foundation

@main
struct ForkGnuSedCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-gnu-sed", brewName: "gnu-sed"))
    }
}
