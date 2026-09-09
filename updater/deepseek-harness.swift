// updater/deepseek-harness.swift —— 与 Formula/deepseek-harness.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/deepseek-harness.swift -o /tmp/check-dsh && /tmp/check-dsh
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// DeepSeek Harness（@deepseek-ai/dsh）不在 brew core，走 customRelease 自定义流。
// 版本源用 npm registry 的 latest 文档（约 2KB，不耗 GitHub API 限额）：
//   curl -fsSL "https://registry.npmjs.org/@deepseek-ai/dsh/latest"
//   → {"version":"0.1.2-rc.1","dist":{"tarball":".../dsh-0.1.2-rc.1.tgz",...}}
// version + tarball 直链一次拿全；sha 置 nil，核心回退下载 tarball 本地实算
// （registry 只给 sha512 integrity，没有 sha256）。
//
// 版本政策（2026-09-09）：跟 `latest` dist-tag，不跟全量最大版本——上游处 preview 期，
// latest 指向作者认定的可用线（如 0.1.2-rc.1），而全量最大可能是 alpha
// （如 0.1.5-alpha.1）。latest 动了再升，alpha 不追。
//
// 版本号形态注意：全是预发布（0.1.1-rc.2 / 0.1.2-rc.1），url 文件名含完整版本。
// 核心侧配套：currentVersion 的 url 回退解析带预发布后缀（关键词限定），
// compareVersions 里预发布 < 正式版（rc→final 不丢更新），见 UpdaterCore。

import Foundation

@main
struct DeepseekHarnessCheck {
    static func main() {
        let config = CheckConfig(
            formula: "deepseek-harness",
            customRelease: {
                guard let json = fetchJSON(
                    "https://registry.npmjs.org/@deepseek-ai/dsh/latest"),
                    let version = json["version"] as? String, !version.isEmpty,
                    let dist = json["dist"] as? [String: Any],
                    let tarball = dist["tarball"] as? String, !tarball.isEmpty else {
                    return nil
                }
                // registry 不提供 sha256 → 置 nil，核心下载 tarball 本地实算
                return UpstreamRelease(version: version, downloadURL: tarball, sha256: nil)
            }
        )
        runCheck(config)
    }
}
