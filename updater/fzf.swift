// updater/fzf.swift —— 与 Formula/fzf.rb 一一同名的检查器入口

import Foundation

@main
struct FzfCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fzf", brewName: "fzf"))
    }
}
