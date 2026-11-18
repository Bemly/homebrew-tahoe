// updater/bun.swift —— 与 Formula/bun.rb 一一同名的检查器入口

import Foundation

@main
struct BunCheck {
    static func main() {
        runCheck(CheckConfig(formula: "bun", brewName: "bun"))
    }
}
