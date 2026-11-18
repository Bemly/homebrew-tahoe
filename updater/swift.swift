// updater/swift.swift —— 与 Formula/swift.rb 一一同名的检查器入口

import Foundation

@main
struct SwiftCheck {
    static func main() {
        runCheck(CheckConfig(formula: "swift", brewName: "swift"))
    }
}
