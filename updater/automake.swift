// updater/automake.swift —— 与 Formula/automake.rb 一一同名的检查器入口

import Foundation

@main
struct AutomakeCheck {
    static func main() {
        runCheck(CheckConfig(formula: "automake", brewName: "automake"))
    }
}
