// updater/ripgrep.swift —— 与 Formula/ripgrep.rb 一一同名的检查器入口
// 跟踪官方 GitHub Release 的 macOS 双架构预编译包，不再走 core 源码公式。

import Foundation

@main
struct RipgrepCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "ripgrep",
            downloadURL: {
                "https://github.com/BurntSushi/ripgrep/releases/download/\($0)/ripgrep-\($0)-x86_64-apple-darwin.tar.gz"
            },
            githubRepo: "BurntSushi/ripgrep",
            githubTagPrefix: "",
            archArtifacts: ["arm64", "x86_64"],
            downloadURLForArch: { version, arch in
                let token = arch == "arm64" ? "aarch64" : arch
                return "https://github.com/BurntSushi/ripgrep/releases/download/\(version)/ripgrep-\(version)-\(token)-apple-darwin.tar.gz"
            }
        ))
    }
}
