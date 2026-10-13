// updater/scrcpy.swift —— 与 Formula/scrcpy.rb 一一同名的检查器入口
//
// scrcpy 在 homebrew/core，走 brew 流：版本判据是 formulae.brew.sh 的
// versions.stable；上游提供汇总 SHA256SUMS.txt（约 2KB，"sha  文件名" 两列，
// macos-x86_64 行可精确匹配，见 AGENTS.md 11.47）。
//
// 运行：swiftc updater/UpdaterCore.swift updater/scrcpy.swift -o /tmp/check-scrcpy && /tmp/check-scrcpy
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct ScrcpyCheck {
    static func main() {
        let config = CheckConfig(
            formula: "scrcpy",
            brewName: "scrcpy",
            asset: { version in "scrcpy-macos-x86_64-v\(version).tar.gz" },
            downloadURL: { version in
                "https://github.com/Genymobile/scrcpy/releases/download/v\(version)/scrcpy-macos-x86_64-v\(version).tar.gz"
            },
            checksumsURL: { version in
                "https://github.com/Genymobile/scrcpy/releases/download/v\(version)/SHA256SUMS.txt"
            }
        )
        runCheck(config)
    }
}
