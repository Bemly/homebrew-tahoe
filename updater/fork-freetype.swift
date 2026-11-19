// updater/fork-freetype.swift —— 与 Formula/fork-freetype.rb 一一同名的检查器入口

import Foundation

@main
struct ForkFreetypeCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-freetype", brewName: "freetype"))
    }
}
