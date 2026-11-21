// updater/dynet.swift —— 与 Formula/dynet.rb 一一同名的检查器入口

import Foundation

@main
struct DynetCheck {
    static func main() {
        runCheck(CheckConfig(formula: "dynet", brewName: "dynet"))
    }
}
