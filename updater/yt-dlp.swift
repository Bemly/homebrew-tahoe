// updater/yt-dlp.swift —— 与 Formula/yt-dlp.rb 一一同名的检查器入口
//
// yt-dlp 在 homebrew/core，走 brew 流：版本判据是 formulae.brew.sh 的
// versions.stable（日期版本号；注意 brew 取 PyPI 归一化值如 "2026.8.19"，
// 而 GitHub tag 保持补零 "2026.08.19"——模板内自行补齐月日到两位，
// HEAD 探测对不上即报 upstream-missing，绝不写坏文件）；上游提供汇总
// SHA2-256SUMS（约 8KB，"sha  文件名" 两列，yt-dlp_macos 行可精确匹配）。
//
// 注意文件名无版本：brew 从路径段（/download/<ver>/）正确扫出全版本，
// 故公式不写 version 行（写了判冗余）；检查器从 url 行解析本地版本（补零形态），
// 与 brew 的去零形态按数值判等（UpdaterCore compareVersions，见 11.48）。
//
// 运行：swiftc updater/UpdaterCore.swift updater/yt-dlp.swift -o /tmp/check-yt-dlp && /tmp/check-yt-dlp
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct YtDlpCheck {
    /// brew 的去零形态（"2026.8.19"）→ GitHub 的补零形态（"2026.08.19"）：
    /// 首段（年）不动，其余数字段补齐到两位。形态对不上则 HEAD 探测兜底。
    static func padded(_ version: String) -> String {
        var parts = version.split(separator: ".").map(String.init)
        for i in 1..<parts.count {
            if let n = Int(parts[i]), String(n) == parts[i], parts[i].count < 2 {
                parts[i] = String(format: "%02d", n)
            }
        }
        return parts.joined(separator: ".")
    }

    static func main() {
        let config = CheckConfig(
            formula: "yt-dlp",
            brewName: "yt-dlp",
            asset: { _ in "yt-dlp_macos" },
            downloadURL: { version in
                let v = padded(version)
                return "https://github.com/yt-dlp/yt-dlp/releases/download/\(v)/yt-dlp_macos"
            },
            checksumsURL: { version in
                let v = padded(version)
                return "https://github.com/yt-dlp/yt-dlp/releases/download/\(v)/SHA2-256SUMS"
            }
        )
        runCheck(config)
    }
}
