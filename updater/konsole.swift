// updater/konsole.swift —— 与 Casks/konsole.rb 一一同名的检查器入口
//
// Konsole（KDE 终端）在 homebrew/core 不存在，走 customRelease + 双架构产物。
// 版本源：KDE CI 每日构建目录（Apache autoindex，每架构单文件、只保留最新一天）。
// 取双架构 listing 的构建号交集最大值——配对存在才算，避免两架构版本错位。
// cask 版本即构建号（如 5277）；plist 的 26.11 是 KDE 发布火车号，不用它。
//
// 双架构 + 镜像（uploadRelease=true）：有更新时双包下载实算、上传本仓 Release
//（tag konsole-<构建号>，资产名沿用上游 basename；旧快照自动清理），cask url
// 永远指 Release（直链几天即 404，见下）。
// 注意：KDE CI 目录只保留最新构建，直链 cask 出生几天即坏——必须走镜像，
// 不要把本文件改成直引（2026-09-04 实测：5276 已 404，仅 5277 存活）。
//
// 运行：swiftc updater/UpdaterCore.swift updater/konsole.swift -o /tmp/check-konsole && /tmp/check-konsole
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致
//（customRelease < uploadRelease < archArtifacts < downloadURLForArch）。

import Foundation

@main
struct KonsoleCheck {
    static func main() {
        let config = CheckConfig(
            formula: "konsole",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                // 纯 Foundation 同步抓取（无 curl 重试；失败返回 nil 由核心 fail 明示）
                func buildNumbers(_ arch: String) -> [Int] {
                    guard let url = URL(string: "https://cdn.kde.org/ci-builds/utilities/konsole/master/macos-\(arch)/"),
                          let html = try? String(contentsOf: url, encoding: .utf8) else { return [] }
                    let pattern = "konsole-master-(\\d+)-macos-clang-\(arch)\\.dmg"
                    guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
                    let range = NSRange(html.startIndex..<html.endIndex, in: html)
                    return regex.matches(in: html, range: range).compactMap {
                        Range($0.range(at: 1), in: html).flatMap { Int(html[$0]) }
                    }
                }
                let common = Set(buildNumbers("arm64")).intersection(buildNumbers("x86_64"))
                guard let latest = common.max() else { return nil }
                let v = String(latest)
                // downloadURL 占位（双架构分支不用它，用 downloadURLForArch 逐个下载）
                return UpstreamRelease(version: v,
                    downloadURL: "https://cdn.kde.org/ci-builds/utilities/konsole/master/macos-x86_64/konsole-master-\(v)-macos-clang-x86_64.dmg",
                    sha256: nil)
            },
            uploadRelease: true,
            archArtifacts: ["arm64", "x86_64"],
            downloadURLForArch: { version, arch in
                "https://cdn.kde.org/ci-builds/utilities/konsole/master/macos-\(arch)/konsole-master-\(version)-macos-clang-\(arch).dmg"
            }
        )
        runCheck(config)
    }
}
