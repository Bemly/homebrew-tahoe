// updater/jadx.swift —— 与 Formula/jadx.rb 一一同名的检查器入口

import Foundation

@main
struct JadxCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "jadx",
            downloadURL: { "https://github.com/skylot/jadx/releases/download/v\($0)/jadx-\($0).zip" },
            githubRepo: "skylot/jadx"))
    }
}
