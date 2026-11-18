// updater/aria2.swift —— 与 Formula/aria2.rb 一一同名的检查器入口

import Foundation

@main
struct Aria2Check {
    static func main() {
        runCheck(CheckConfig(formula: "aria2", brewName: "aria2"))
    }
}
