// updater/bison.swift —— 与 Formula/bison.rb 一一同名的检查器入口

import Foundation

@main
struct BisonCheck {
    static func main() {
        runCheck(CheckConfig(formula: "bison", brewName: "bison"))
    }
}
