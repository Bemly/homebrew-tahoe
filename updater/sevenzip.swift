// updater/sevenzip.swift —— 官方 7-Zip macOS Intel 预编译包检查器

import Foundation

@main
struct SevenzipCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "sevenzip",
            downloadURL: {
                let compact = $0.replacingOccurrences(of: ".", with: "")
                return "https://github.com/ip7z/7zip/releases/download/\($0)/7z\(compact)-mac-x64.tar.xz"
            },
            githubRepo: "ip7z/7zip",
            githubTagPrefix: ""
        ))
    }
}
