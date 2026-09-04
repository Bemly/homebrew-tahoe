// updater/h2spec.swift —— 与 Formula/h2spec.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/h2spec.swift -o /tmp/check-h2spec && /tmp/check-h2spec
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// 上游 release 无 checksums 汇总文件 → checksumsURL 置 nil，
// 核心在有更新时回退下载 tar 包本地实算（约 5MB，仅检测到新版本时发生）。

import Foundation

@main
struct H2specCheck {
    static func main() {
        let config = CheckConfig(
            formula: "h2spec",
            brewName: "h2spec",
            asset: { version in "h2spec_darwin_amd64.tar.gz" },
            downloadURL: { version in
                "https://github.com/summerwind/h2spec/releases/download/v\(version)/h2spec_darwin_amd64.tar.gz"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
