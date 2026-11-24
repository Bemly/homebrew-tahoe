// updater/fork-bison.swift —— 与 Formula/fork-bison.rb 一一同名的检查器入口

import Foundation

@main
struct ForkBisonCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-bison", brewName: "bison"))
    }
}
