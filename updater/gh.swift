// updater/gh.swift —— 与 Formula/gh.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/gh.swift -o /tmp/check-gh && /tmp/check-gh
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// 发布包结构见 AGENTS.md 第 6 节：gh_<ver>_macOS_amd64.zip，release tag 带 v 前缀，
// 上游提供汇总 checksums.txt（约 2KB）。

import Foundation

@main
struct GhCheck {
    static func main() {
        let config = CheckConfig(
            formula: "gh",
            brewName: "gh",
            asset: { version in "gh_\(version)_macOS_amd64.zip" },
            downloadURL: { version in
                "https://github.com/cli/cli/releases/download/v\(version)/gh_\(version)_macOS_amd64.zip"
            },
            checksumsURL: { version in
                "https://github.com/cli/cli/releases/download/v\(version)/gh_\(version)_checksums.txt"
            }
        )
        runCheck(config)
    }
}
