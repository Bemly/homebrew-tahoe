// updater/wimlib.swift —— 与 Formula/wimlib.rb 一一同名的检查器入口

import Foundation

@main
struct WimlibCheck {
    static func main() {
        runCheck(CheckConfig(formula: "wimlib", brewName: "wimlib"))
    }
}
