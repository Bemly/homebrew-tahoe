// updater/docker-compose.swift —— 与 Formula/docker-compose.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/docker-compose.swift -o /tmp/check-docker-compose && /tmp/check-docker-compose
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// docker/compose 官方裸二进制（docker-compose-darwin-x86_64，release tag 带 v 前缀），
// 与 homebrew/core 的 docker-compose stable 同步（当前同为 5.5.1），故版本判据走 brew 流。
// 上游 checksums.txt 虽有 darwin 行，但文件名带 `*` 前缀（binary 模式），
// 与核心的精确匹配对不上 → checksumsURL 置 nil，核心在有更新时回退下载二进制
// 本地实算（约 65MB，仅检测到新版本时发生）。

import Foundation

@main
struct DockerComposeCheck {
    static func main() {
        let config = CheckConfig(
            formula: "docker-compose",
            brewName: "docker-compose",
            asset: { _ in "docker-compose-darwin-x86_64" },
            downloadURL: { version in
                "https://github.com/docker/compose/releases/download/v\(version)/docker-compose-darwin-x86_64"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
