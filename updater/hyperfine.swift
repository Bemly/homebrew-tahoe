// updater/hyperfine.swift —— 与 Formula/hyperfine.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/hyperfine.swift -o /tmp/check-hyperfine && /tmp/check-hyperfine
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// 上游 release 无 checksums 汇总文件 → checksumsURL 置 nil，
// 核心在有更新时回退下载 tar 包本地实算（约 0.6MB，仅检测到新版本时发生）。

import Foundation

@main
struct HyperfineCheck {
    static func main() {
        let config = CheckConfig(
            formula: "hyperfine",
            brewName: "hyperfine",
            asset: { version in "hyperfine-v\(version)-x86_64-apple-darwin.tar.gz" },
            downloadURL: { version in
                "https://github.com/sharkdp/hyperfine/releases/download/v\(version)/hyperfine-v\(version)-x86_64-apple-darwin.tar.gz"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
