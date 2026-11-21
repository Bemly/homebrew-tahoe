// updater/libassuan.swift —— 与 Formula/libassuan.rb 一一同名的检查器入口

import Foundation

@main
struct LibassuanCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libassuan", brewName: "libassuan"))
    }
}
