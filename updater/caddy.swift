// updater/caddy.swift —— 与 Formula/caddy.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/caddy.swift -o /tmp/check-caddy && /tmp/check-caddy
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// 上游官方 mac_amd64 tar 包（caddy_<ver>_mac_amd64.tar.gz）。
// release 附带的 checksums 文件已从 SHA-256 换成 SHA-512（2026-10-09 实测：
// 全部 128 位，核心解析命中但 64 位校验拒收）——checksumsURL 置 nil，
// 有更新时回退下载 tar 包（约 18MB）本地实算（buildx/frida 同例）。

import Foundation

@main
struct CaddyCheck {
    static func main() {
        let config = CheckConfig(
            formula: "caddy",
            brewName: "caddy",
            asset: { version in "caddy_\(version)_mac_amd64.tar.gz" },
            downloadURL: { version in
                "https://github.com/caddyserver/caddy/releases/download/v\(version)/caddy_\(version)_mac_amd64.tar.gz"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
