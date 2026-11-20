// updater/antigravity-cli.swift —— 与 Formula/antigravity-cli.rb 一一同名的检查器入口
// 版本/直链来自官方 CLI 的 darwin_amd64 manifest；官方给的是 SHA-512，
// 交给核心下载后实算 SHA-256。不钉死版本。

import Foundation

@main
struct AntigravityCliCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "antigravity-cli",
            customRelease: {
                let api = "https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/darwin_amd64.json"
                let (status, body) = curlText(api)
                guard status == 0,
                      let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [String: Any],
                      let version = json["version"] as? String,
                      let url = json["url"] as? String,
                      let sha512 = json["sha512"] as? String,
                      url.contains("darwin-x64"),
                      sha512.range(of: #"^[0-9a-f]{128}$"#, options: .regularExpression) != nil else { return nil }
                return UpstreamRelease(version: version, downloadURL: url, sha256: nil)
            }
        ))
    }
}
