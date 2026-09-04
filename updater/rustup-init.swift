// updater/rustup-init.swift —— 与 Formula/rustup-init.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/rustup-init.swift -o /tmp/check-rustup-init && /tmp/check-rustup-init
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// 版本源用 Rust 官方自更新通道清单 release-stable.toml（version = 'x.y.z'）：
// 不走 github 流——rust-lang/rustup 的 releases/latest 跳到 /releases 列表页
// 而非 /releases/tag/<tag>，Location 里没有 tag（2026-09-05 实测）。
// 原料取 static.rust-lang.org 的版本化归档（/archive/<ver>/...），不取
// floating 的 dist 直链。sha 置 nil：核心下载裸二进制（约 30MB）本地实算。

import Foundation

@main
struct RustupInitCheck {
    static func main() {
        let config = CheckConfig(
            formula: "rustup-init",
            customRelease: {
                let (status, toml) = curlText(
                    "https://static.rust-lang.org/rustup/release-stable.toml")
                guard status == 0, !toml.isEmpty,
                      let regex = try? NSRegularExpression(
                        pattern: #"(?m)^version\s*=\s*['"]([^'"]+)['"]"#),
                      let m = regex.firstMatch(
                        in: toml, range: NSRange(toml.startIndex..<toml.endIndex, in: toml)),
                      let vr = Range(m.range(at: 1), in: toml) else {
                    return nil
                }
                let stable = String(toml[vr])
                return UpstreamRelease(
                    version: stable,
                    downloadURL: "https://static.rust-lang.org/rustup/archive/\(stable)/x86_64-apple-darwin/rustup-init",
                    sha256: nil)
            }
        )
        runCheck(config)
    }
}
