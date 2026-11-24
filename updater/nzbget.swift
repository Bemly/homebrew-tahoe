// updater/nzbget.swift —— 与 Formula/nzbget.rb 一一同名的检查器入口

import Foundation

@main
struct NzbgetCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "nzbget",
            downloadURL: {
                "https://github.com/nzbgetcom/nzbget/releases/download/v\($0)/nzbget-\($0)-bin-macos-x64.zip"
            },
            githubRepo: "nzbgetcom/nzbget",
            githubTagPrefix: "v"
        ))
    }
}
