// updater/npth.swift —— 与 Formula/npth.rb 一一同名的检查器入口

import Foundation

@main
struct NpthCheck {
    static func main() {
        runCheck(CheckConfig(formula: "npth", brewName: "npth"))
    }
}
