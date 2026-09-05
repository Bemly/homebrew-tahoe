// updater/git-lfs.swift —— 与 Formula/git-lfs.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/git-lfs.swift -o /tmp/check-git-lfs && /tmp/check-git-lfs
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// 上游官方 darwin-amd64 zip（git-lfs-darwin-amd64-v<ver>.zip）。release 虽带
// sha256sums.asc，但文件名带 `*` 前缀（binary 模式），核心按 `$2==asset`
// 精确匹配对不上（docker/compose 同例，见 11.21.3）→ checksumsURL 置 nil，
// 有更新时回退下载 zip 本地实算（约 6MB，仅检测到新版本时发生）。

import Foundation

@main
struct GitLfsCheck {
    static func main() {
        let config = CheckConfig(
            formula: "git-lfs",
            brewName: "git-lfs",
            asset: { version in "git-lfs-darwin-amd64-v\(version).zip" },
            downloadURL: { version in
                "https://github.com/git-lfs/git-lfs/releases/download/v\(version)/git-lfs-darwin-amd64-v\(version).zip"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
