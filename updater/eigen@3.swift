// updater/eigen@3.swift —— 与 Formula/eigen@3.rb 一一同名的检查器入口

import Foundation

@main
struct EigenAT3Check {
    static func main() {
        runCheck(CheckConfig(formula: "eigen@3", brewName: "eigen@3"))
    }
}
