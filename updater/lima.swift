// updater/lima.swift —— 与 Formula/lima.rb 一一同名的检查器入口

import Foundation

@main
struct LimaCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "lima",
            asset: { "lima-\($0)-Darwin-x86_64.tar.gz" },
            downloadURL: { "https://github.com/lima-vm/lima/releases/download/v\($0)/lima-\($0)-Darwin-x86_64.tar.gz" },
            checksumsURL: { "https://github.com/lima-vm/lima/releases/download/v\($0)/SHA256SUMS" },
            githubRepo: "lima-vm/lima"))
    }
}
