// updater/bun.swift —— 与 Formula/bun.rb 一一同名的检查器入口

import Foundation

@main
struct BunCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "bun",
            asset: { _ in "bun-darwin-x64.zip" },
            downloadURL: { "https://github.com/oven-sh/bun/releases/download/bun-v\($0)/bun-darwin-x64.zip" },
            checksumsURL: { "https://github.com/oven-sh/bun/releases/download/bun-v\($0)/SHASUMS256.txt" },
            githubRepo: "oven-sh/bun",
            githubTagPrefix: "bun-v"))
    }
}
