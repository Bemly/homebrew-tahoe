// updater/xcodegen.swift —— 与 Formula/xcodegen.rb 一一同名的检查器入口

import Foundation

@main
struct XcodegenCheck {
    static func main() {
        runCheck(CheckConfig(formula: "xcodegen", brewName: "xcodegen"))
    }
}
