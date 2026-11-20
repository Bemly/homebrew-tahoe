// updater/dotnet.swift —— 与 Formula/dotnet.rb 一一同名的检查器入口
// 版本/下载链接来自 Microsoft 官方 dotnet release metadata，只取 osx-x64 SDK tarball。
// 官方 checksum 是 SHA-512，交给核心下载后实算 SHA-256。

import Foundation

@main
struct DotnetCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "dotnet",
            customRelease: {
                let api = "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/11.0/releases.json"
                let (status, body) = curlText(api)
                guard status == 0,
                      let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [String: Any],
                      let releases = json["releases"] as? [[String: Any]],
                      let first = releases.first,
                      let sdk = first["sdk"] as? [String: Any],
                      let version = sdk["version"] as? String,
                      let files = sdk["files"] as? [[String: Any]],
                      let file = files.first(where: { ($0["name"] as? String) == "dotnet-sdk-osx-x64.tar.gz" }),
                      let url = file["url"] as? String else { return nil }
                return UpstreamRelease(version: version, downloadURL: url, sha256: nil)
            }
        ))
    }
}
