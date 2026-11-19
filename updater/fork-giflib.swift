// updater/fork-giflib.swift —— 与 Formula/fork-giflib.rb 一一同名的检查器入口

import Foundation

@main
struct ForkGiflibCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-giflib", brewName: "giflib"))
    }
}
