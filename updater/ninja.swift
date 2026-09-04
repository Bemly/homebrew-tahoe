// updater/ninja.swift —— 与 Formula/ninja.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/ninja.swift -o /tmp/check-ninja && /tmp/check-ninja
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// 上游 ninja-mac.zip 是 universal 二进制（含 x86_64 切片），release 无
// checksums 文件 → checksumsURL 置 nil，核心在有更新时回退下载实算
//（约 0.3MB，仅检测到新版本时发生）。

import Foundation

@main
struct NinjaCheck {
    static func main() {
        let config = CheckConfig(
            formula: "ninja",
            brewName: "ninja",
            asset: { _ in "ninja-mac.zip" },
            downloadURL: { version in
                "https://github.com/ninja-build/ninja/releases/download/v\(version)/ninja-mac.zip"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
