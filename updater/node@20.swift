// updater/node@20.swift —— 与 Formula/node@20.rb 一一同名的检查器入口
// 跟随 Node.js 官方 darwin-x64 tarball。

import Foundation

@main
struct NodeAT20Check {
    static func main() {
        runCheck(CheckConfig(
            formula: "node@20",
            brewName: "node@20",
            downloadURL: { "https://nodejs.org/dist/v\($0)/node-v\($0)-darwin-x64.tar.gz" }))
    }
}
