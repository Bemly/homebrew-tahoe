// updater/fish.swift —— 与 Formula/fish.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/fish.swift -o /tmp/check-fish && /tmp/check-fish
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// fish-shell 官方 .app.zip（fish-<ver>.app.zip），release tag 即 fish 版本，
// 与 homebrew/core 的 fish stable 同步（当前同为 4.9.0），故版本判据走 brew 流。
// 上游 release 不提供 SHA256SUMS（实测 404）→ checksumsURL 置 nil，
// 核心在有更新时回退下载 zip 本地实算（约 25MB，仅检测到新版本时发生）。

import Foundation

@main
struct FishCheck {
    static func main() {
        let config = CheckConfig(
            formula: "fish",
            brewName: "fish",
            asset: { version in "fish-\(version).app.zip" },
            downloadURL: { version in
                "https://github.com/fish-shell/fish-shell/releases/download/\(version)/fish-\(version).app.zip"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
