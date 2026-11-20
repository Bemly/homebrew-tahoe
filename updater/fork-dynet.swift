// updater/fork-dynet.swift —— 与 Formula/fork-dynet.rb 一一同名的检查器入口

import Foundation

@main
struct ForkDynetCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-dynet", brewName: "dynet"))
    }
}
