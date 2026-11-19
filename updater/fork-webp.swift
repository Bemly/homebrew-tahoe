// updater/fork-webp.swift —— 与 Formula/fork-webp.rb 一一同名的检查器入口

import Foundation

@main
struct ForkWebpCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-webp", brewName: "webp"))
    }
}
