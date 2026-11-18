// updater/svt-av1.swift —— 与 Formula/svt-av1.rb 一一同名的检查器入口

import Foundation

@main
struct SvtAv1Check {
    static func main() {
        runCheck(CheckConfig(formula: "svt-av1", brewName: "svt-av1"))
    }
}
