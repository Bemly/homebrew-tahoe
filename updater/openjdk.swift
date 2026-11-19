// updater/openjdk.swift —— 与 Formula/openjdk.rb 一一同名的检查器入口
// 版本锁在 OpenJDK 26 维护线（jdk26u 仓库的 GA tag），不会跟 core 的 arm64-only openjdk 27。

import Foundation

@main
struct OpenjdkCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "openjdk",
            customRelease: {
                let api = "https://api.github.com/repos/openjdk/jdk26u/tags?per_page=100"
                let (status, body) = curlText(api)
                guard status == 0,
                      let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [[String: Any]],
                      let tag = json.compactMap({ $0["name"] as? String })
                        .first(where: { $0.hasPrefix("jdk-26") && $0.hasSuffix("-ga") }) else { return nil }
                let v = tag.replacingOccurrences(of: "jdk-", with: "")
                           .replacingOccurrences(of: "-ga", with: "")
                guard !v.isEmpty else { return nil }
                return UpstreamRelease(version: v,
                    downloadURL: "https://github.com/openjdk/jdk26u/archive/refs/tags/\(tag).tar.gz",
                    sha256: nil)
            }
        ))
    }
}
