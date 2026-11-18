// updater/git.swift —— 与 Formula/git.rb 一一同名的检查器入口

import Foundation

@main
struct GitCheck {
    static func main() {
        runCheck(CheckConfig(formula: "git", brewName: "git"))
    }
}
