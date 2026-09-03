// updater/docker-buildx.swift —— 与 Formula/docker-buildx.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/docker-buildx.swift -o /tmp/check-docker-buildx && /tmp/check-docker-buildx
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// docker/buildx 官方裸二进制（buildx-v<ver>.darwin-amd64，release tag 带 v 前缀），
// 与 homebrew/core 的 docker-buildx stable 同步（当前同为 0.37.0），故版本判据走 brew 流。
// 上游 checksums.txt 无 darwin 条目（实测只有 freebsd/linux/netbsd/openbsd）→
// checksumsURL 置 nil，核心在有更新时回退下载二进制本地实算
//（约 68MB，仅检测到新版本时发生）。

import Foundation

@main
struct DockerBuildxCheck {
    static func main() {
        let config = CheckConfig(
            formula: "docker-buildx",
            brewName: "docker-buildx",
            asset: { version in "buildx-v\(version).darwin-amd64" },
            downloadURL: { version in
                "https://github.com/docker/buildx/releases/download/v\(version)/buildx-v\(version).darwin-amd64"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
