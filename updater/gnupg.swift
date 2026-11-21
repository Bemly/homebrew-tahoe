// updater/gnupg.swift —— 与 Formula/gnupg.rb 一一同名的检查器入口

import Foundation

@main
struct GnupgCheck {
    static func main() {
        runCheck(CheckConfig(formula: "gnupg", brewName: "gnupg"))
    }
}
