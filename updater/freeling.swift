// updater/freeling.swift —— 与 Formula/freeling.rb 一一同名的检查器入口

import Foundation

@main
struct FreelingCheck {
    static func main() {
        runCheck(CheckConfig(formula: "freeling", brewName: "freeling"))
    }
}
