// updater/openjdk@17.swift —— 与 Formula/openjdk@17.rb 一一同名的检查器入口
// 跟随 Eclipse Temurin 的 macOS x64 JDK（Adoptium API），不钉死版本；
// 额外校验 arch/os/image_type 与链接形态，避免误取 arm64 或非 JDK 资产。

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
                      let arch = bin["architecture"] as? String,
                      let os = bin["os"] as? String,
                      let imageType = bin["image_type"] as? String,
                      let pkg = bin["package"] as? [String: Any],
                      let link = pkg["link"] as? String,
                      let checksum = pkg["checksum"] as? String else { return nil }
                let v = semver.split(separator: "+").first.map(String.init) ?? ""
                guard arch == "x64", os == "mac", imageType == "jdk",
                      link.contains("x64_mac"),
                      v.hasPrefix("17."),
                      checksum.range(of: #"^[0-9a-f]{64}$"#, options: .regularExpression) != nil else { return nil }
                return UpstreamRelease(version: v, downloadURL: link, sha256: checksum)
            }
        ))
    }
}
