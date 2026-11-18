// updater/bash.swift —— 与 Formula/bash.rb 一一同名的检查器入口

import Foundation

@main
struct BashCheck {
    static func main() {
        runCheck(CheckConfig(formula: "bash", brewName: "bash"))
    }
}
