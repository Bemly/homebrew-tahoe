// updater/pinentry.swift —— 与 Formula/pinentry.rb 一一同名的检查器入口

import Foundation

@main
struct PinentryCheck {
    static func main() {
        runCheck(CheckConfig(formula: "pinentry", brewName: "pinentry"))
    }
}
