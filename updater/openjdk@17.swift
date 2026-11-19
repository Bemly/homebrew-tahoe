// updater/openjdk@17.swift —— 与 Formula/openjdk@17.rb 一一同名的检查器入口
// 跟随 Eclipse Temurin 的 macOS x64 JDK（Adoptium API），不钉死版本。

import Foundation

@main
struct OpenjdkAT17Check {
    static func main() {
        runCheck(CheckConfig(
            formula: "openjdk@17",
            customRelease: {
                let api = "https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=mac&vendor=eclipse"
                let (status, body) = curlText(api)
                guard status == 0,
                      let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [[String: Any]],
                      let first = json.first,
                      let verObj = first["version"] as? [String: Any],
                      let semver = verObj["semver"] as? String,
                      let bin = first["binary"] as? [String: Any],
                      let pkg = bin["package"] as? [String: Any],
                      let link = pkg["link"] as? String,
                      let checksum = pkg["checksum"] as? String else { return nil }
                let v = semver.split(separator: "+").first.map(String.init) ?? ""
                guard !v.isEmpty else { return nil }
                return UpstreamRelease(version: v, downloadURL: link, sha256: checksum)
            }
        ))
    }
}
