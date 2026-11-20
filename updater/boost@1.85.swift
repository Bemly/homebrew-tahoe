// updater/boost@1.85.swift —— 与 Formula/boost@1.85.rb 一一同名的检查器入口
// 版本跟 core 的 boost@1.85；原料用预编译 macOS x86 tarball。

import Foundation

@main
struct BoostAT185Check {
    static func main() {
        runCheck(CheckConfig(
            formula: "boost@1.85",
            brewName: "boost@1.85",
            downloadURL: { "https://github.com/MarkusJx/prebuilt-boost/releases/download/\($0)/boost-\($0)-macos-13-clang-static%2Bshared-x86.tar.gz" }))
    }
}
