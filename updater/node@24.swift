// updater/node@24.swift —— 与 Formula/node@24.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift "updater/node@24.swift" -o /tmp/check-node@24 && /tmp/check-node@24
// （须在仓库根目录执行；node@24 在 homebrew/core，走 brew 流，见 AGENTS.md 9.3）
//
// Node.js 官方每个版本目录都带 SHASUMS256.txt（全平台清单，几十 KB），
// 其中 node-v<ver>-darwin-x64.tar.gz 行的第二列即资产名，直接命中核心的解析逻辑。

import Foundation

@main
struct NodeAT24Check {
    static func main() {
        let config = CheckConfig(
            formula: "node@24",
            brewName: "node@24",
            asset: { version in "node-v\(version)-darwin-x64.tar.gz" },
            downloadURL: { version in
                "https://nodejs.org/dist/v\(version)/node-v\(version)-darwin-x64.tar.gz"
            },
            checksumsURL: { version in
                "https://nodejs.org/dist/v\(version)/SHASUMS256.txt"
            }
        )
        runCheck(config)
    }
}
