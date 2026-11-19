// updater/openjdk@21.swift —— 与 Formula/openjdk@21.rb 一一同名的检查器入口

import Foundation

@main
struct OpenjdkAT21Check {
    static func main() {
        runCheck(CheckConfig(formula: "openjdk@21", brewName: "openjdk@21"))
    }
}
