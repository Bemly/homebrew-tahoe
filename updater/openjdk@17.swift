// updater/openjdk@17.swift —— 与 Formula/openjdk@17.rb 一一同名的检查器入口

import Foundation

@main
struct OpenjdkAT17Check {
    static func main() {
        runCheck(CheckConfig(formula: "openjdk@17", brewName: "openjdk@17"))
    }
}
