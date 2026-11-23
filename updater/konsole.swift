// updater/konsole.swift —— 与 Casks/konsole.rb 一一同名的检查器入口
// KDE CI 的 ARM / Intel 目录独立出包，版本号可能不同；分别取各自最新构建号，
// 镜像到本仓 Release 后改写 on_arm / on_intel 块，不再取双架构交集。

import Foundation

@main
struct KonsoleCheck {
    static func main() {
        let config = CheckConfig(
            formula: "konsole",
            formulaPath: "Casks",
            isCask: true,
            uploadRelease: true,
            archArtifacts: ["arm64", "x86_64"],
            customReleaseByArch: { arch in
                let (status, html) = curlText("https://cdn.kde.org/ci-builds/utilities/konsole/master/macos-\(arch)/")
                guard status == 0, !html.isEmpty else { return nil }
                let pattern = "konsole-master-(\\d+)-macos-clang-\(arch)\\.dmg"
                guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                let builds = regex.matches(in: html, range: range).compactMap {
                    Range($0.range(at: 1), in: html).flatMap { Int(html[$0]) }
                }
                guard let latest = builds.max() else { return nil }
                let version = String(latest)
                return UpstreamRelease(
                    version: version,
                    downloadURL: "https://cdn.kde.org/ci-builds/utilities/konsole/master/macos-\(arch)/konsole-master-\(version)-macos-clang-\(arch).dmg",
                    sha256: nil)
            }
        )
        runCheck(config)
    }
}
