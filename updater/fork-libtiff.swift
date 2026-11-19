// updater/fork-libtiff.swift —— 与 Formula/fork-libtiff.rb 一一同名的检查器入口

import Foundation

@main
struct ForkLibtiffCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-libtiff", brewName: "libtiff"))
    }
}
