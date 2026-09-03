// updater/mufetch.swift —— 与 Formula/mufetch.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/mufetch.swift -o /tmp/check-mufetch && /tmp/check-mufetch
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// brew 流模板式：版本判据取 formulae.brew.sh 的 versions.stable（mufetch 在 core 里，
// 但 core 用的是源码归档，本 tap 取 release 里的 darwin x86_64 预编译包）。
// 资产名 mufetch_darwin_x86_64.tar.gz；sha 取自 release 的 checksums.txt（约 2KB，
// 标准 `sha  filename` 格式，与核心的解析逻辑一致）。

import Foundation

@main
struct MufetchCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "mufetch",
            brewName: "mufetch",
            asset: { _ in "mufetch_darwin_x86_64.tar.gz" },
            downloadURL: { version in
                "https://github.com/ashish0kumar/mufetch/releases/download/v\(version)/mufetch_darwin_x86_64.tar.gz"
            },
            checksumsURL: { version in
                "https://github.com/ashish0kumar/mufetch/releases/download/v\(version)/checksums.txt"
            }
        ))
    }
}
