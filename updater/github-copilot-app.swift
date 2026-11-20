// updater/github-copilot-app.swift —— GitHub Copilot 桌面版中文补丁包的版本检查器。
//
// 与 antigravity 同形态：产物不是「下载上游再镜像」，而是 CI（patched.yml）里
// Widgets/github-copilot-cn/build.sh 在官方 Intel 包上注入补丁后重打的 dmg，
// 所以**不开 uploadRelease**，只做三件事：
//   1. 判新：版本源取 homebrew/core 的 github-copilot-app cask（.version），
//      拼本包补丁序号 -cn<REVISION>（与 build.sh 的 --revision 默认值同步）；
//   2. 取 sha：读构建随包上传的 .sha256 sidecar（避免 ~270MB 实算）；
//   3. sidecar 不存在 = 补丁包还没构建 → 故意返回 sha256 nil，让核心 HEAD 探测 404
//      报 upstream-missing 并开 issue，而不是把指向空资产的 url 写进 cask。
//
// 同宿主版本重打补丁时人工把 build.sh 的 --revision 提到 2 并手改 cask；此时本
// 检查器算出的 -cn1 小于本地 -cn2 → newer-than-brew 不动文件（防回退，符合预期）。
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct GithubCopilotAppCheck {
    static func main() {
        // 与 build.sh 的 REVISION 默认值保持一致（新宿主版本的第一个补丁包）。
        let revision = "cn1"
        runCheck(CheckConfig(
            formula: "github-copilot-app",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                guard let core = fetchJSON("https://formulae.brew.sh/api/cask/github-copilot-app.json"),
                      let raw = core["version"] as? String, !raw.isEmpty else { return nil }

                let version = raw + "-" + revision
                let asset = "GitHub-Copilot-" + version + ".dmg"
                let url = "https://github.com/Bemly/homebrew-tahoe/releases/download/github-copilot-app-"
                    + version + "/" + asset

                var sha: String?
                let (status, body) = curlText(url + ".sha256")
                if status == 0 {
                    let token = body.trimmingCharacters(in: .whitespacesAndNewlines)
                        .split(separator: " ").first.map(String.init) ?? ""
                    let hex = token.lowercased()
                    if hex.count == 64 && hex.allSatisfy({ $0.isHexDigit }) { sha = hex }
                }

                return UpstreamRelease(version: version, downloadURL: url, sha256: sha)
            }
        ))
    }
}
