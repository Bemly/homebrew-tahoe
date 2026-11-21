// updater/xcodegen.swift —— 与 Formula/xcodegen.rb 一一同名的检查器入口

import Foundation

@main
struct XcodegenCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "xcodegen",
            downloadURL: { "https://github.com/yonaskolb/XcodeGen/releases/download/\($0)/xcodegen.zip" },
            githubRepo: "yonaskolb/XcodeGen",
            githubTagPrefix: ""))
    }
}
