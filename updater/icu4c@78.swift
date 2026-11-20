// updater/icu4c@78.swift —— 与 Formula/icu4c@78.rb 一一同名的检查器入口

import Foundation

@main
struct Icu4cAT78Check {
    static func main() {
        runCheck(CheckConfig(formula: "icu4c@78", brewName: "icu4c@78"))
    }
}
