// updater/cmake.swift —— 与 Formula/cmake.rb 一一同名的检查器入口
//
// CMake 在 homebrew/core，走 brew 流：版本判据是 formulae.brew.sh 的
// versions.stable；上游 cmake.org 提供汇总 SHA-256.txt（约 5KB，按
// "<sha>  <文件名>" 两列，可精确匹配）。
//
// 上游目录按主次版本分（/files/v4.4/，补丁升级不换目录），模板内自行截取；
// 公式 url 行虽带版本目录段，brew 仍能从文件名正确扫出全版本（实测 stable
// 即 4.4.4），故公式不写 version 行，检查器从 url 行解析本地版本。
//
// 运行：swiftc updater/UpdaterCore.swift updater/cmake.swift -o /tmp/check-cmake && /tmp/check-cmake
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct CmakeCheck {
    static func main() {
        func minorDir(_ version: String) -> String {
            let parts = version.split(separator: ".")
            guard parts.count >= 2 else { return "v\(version)" }
            return "v\(parts[0]).\(parts[1])"
        }
        let config = CheckConfig(
            formula: "cmake",
            brewName: "cmake",
            asset: { version in "cmake-\(version)-macos-universal.tar.gz" },
            downloadURL: { version in
                "https://cmake.org/files/\(minorDir(version))/cmake-\(version)-macos-universal.tar.gz"
            },
            checksumsURL: { version in
                "https://cmake.org/files/\(minorDir(version))/cmake-\(version)-SHA-256.txt"
            }
        )
        runCheck(config)
    }
}
