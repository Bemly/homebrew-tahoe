// updater/gnu-sed.swift —— 与 Formula/gnu-sed.rb 一一同名的检查器入口

import Foundation

@main
struct GnuSedCheck {
    static func main() {
        runCheck(CheckConfig(formula: "gnu-sed", brewName: "gnu-sed"))
    }
}
