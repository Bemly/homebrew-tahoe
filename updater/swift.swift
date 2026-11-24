// updater/swift.swift —— 与 Formula/swift.rb 一一同名的检查器入口
// 版本来自 swift.org 官方 releases API，macOS x86_64 工具链用固定 URL 模板；
// 不钉死版本，上游发新版后由核心 HEAD 探测 + 下载实算 sha 后镜像。

import Foundation

@main
struct SwiftCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "swift",
            downloadURL: { "https://download.swift.org/swift-\($0)-release/xcode/swift-\($0)-RELEASE/swift-\($0)-RELEASE-osx.pkg" },
            customRelease: {
                let (status, body) = curlText("https://www.swift.org/api/v1/install/releases.json")
                guard status == 0,
                      let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [[String: Any]],
                      let last = json.last,
                      let v = last["name"] as? String, !v.isEmpty else { return nil }
                let url = "https://download.swift.org/swift-\(v)-release/xcode/swift-\(v)-RELEASE/swift-\(v)-RELEASE-osx.pkg"
                return UpstreamRelease(version: v, downloadURL: url, sha256: nil)
            }
        ))
    }
}
