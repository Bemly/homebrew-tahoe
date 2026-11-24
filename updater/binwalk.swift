// updater/binwalk.swift —— 与 Formula/binwalk.rb 一一同名的检查器入口

import Foundation

@main
struct BinwalkCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "binwalk",
            downloadURL: {
                "https://github.com/ReFirmLabs/binwalk/archive/refs/tags/v\($0).tar.gz"
            },
            githubRepo: "ReFirmLabs/binwalk",
            githubTagPrefix: "v"
        ))
    }
}
