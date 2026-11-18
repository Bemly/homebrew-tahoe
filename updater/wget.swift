// updater/wget.swift —— 与 Formula/wget.rb 一一同名的检查器入口

import Foundation

@main
struct WgetCheck {
    static func main() {
        runCheck(CheckConfig(formula: "wget", brewName: "wget"))
    }
}
