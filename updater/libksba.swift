// updater/libksba.swift —— 与 Formula/libksba.rb 一一同名的检查器入口

import Foundation

@main
struct LibksbaCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libksba", brewName: "libksba"))
    }
}
