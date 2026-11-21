// updater/libgpg-error.swift —— 与 Formula/libgpg-error.rb 一一同名的检查器入口

import Foundation

@main
struct LibgpgErrorCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libgpg-error", brewName: "libgpg-error"))
    }
}
