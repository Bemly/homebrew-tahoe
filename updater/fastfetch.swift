// updater/fastfetch.swift —— 与 Formula/fastfetch.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/fastfetch.swift -o /tmp/check-fastfetch && /tmp/check-fastfetch
// （须在仓库根目录执行；新增软件照抄 gh.swift 改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// fastfetch 的 macOS 发布不提供汇总 checksums 文件 → checksumsURL 置 nil，
// 核心会回退为下载 tar.gz（约 2MB）后本地计算 sha256。release tag 无 v 前缀。

import Foundation

@main
struct FastfetchCheck {
    static func main() {
        let config = CheckConfig(
            formula: "fastfetch",
            brewName: "fastfetch",
            asset: { _ in "fastfetch-macos-amd64.tar.gz" },
            downloadURL: { version in
                "https://github.com/fastfetch-cli/fastfetch/releases/download/\(version)/fastfetch-macos-amd64.tar.gz"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
