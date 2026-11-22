// updater/git.swift —— 与 Formula/git.rb 一一同名的检查器入口

import Foundation

@main
struct GitCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "git",
            brewName: "git",
            manualSyncReason: "Formula/git.rb 含版本耦合的 html/man resource（install 强校验版本一致），请从 core 同步主包与 html/man resource"
        ))
    }
}
