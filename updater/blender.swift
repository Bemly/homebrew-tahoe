// updater/blender.swift —— 与 Casks/blender.rb 一一同名的社区 Beta 检查器
//
// 版本不锁 5.x：从上游 releases.atom 按发布顺序取首个带 -beta 后缀的 tag，
// 再读 expanded_assets 页面定位实际 macOS x86_64 dmg，避免假设 beta 资产名。
// Atom 与 expanded_assets 都是公开页面，不消耗 GitHub API 限额。

import Foundation

@main
struct BlenderCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "blender",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                let repo = "jaguarus83/blender-5x-intel-mac-builds"
                let (feedStatus, feed) = curlText("https://github.com/\(repo)/releases.atom")
                guard feedStatus == 0, !feed.isEmpty else { return nil }

                let tagPattern = #"/releases/tag/(v[0-9]+(?:\.[0-9]+)+-beta(?:\.[0-9]+)?)"#
                guard let tagRegex = try? NSRegularExpression(pattern: tagPattern, options: [.caseInsensitive]),
                      let tagMatch = tagRegex.firstMatch(
                        in: feed,
                        options: [],
                        range: NSRange(feed.startIndex..<feed.endIndex, in: feed)),
                      let tagRange = Range(tagMatch.range(at: 1), in: feed) else { return nil }

                let tag = String(feed[tagRange])
                let version = String(tag.dropFirst())
                let (assetStatus, html) = curlText(
                    "https://github.com/\(repo)/releases/expanded_assets/\(tag)")
                guard assetStatus == 0, !html.isEmpty else { return nil }

                let assetPattern = "href=\"(/[^\"]+/releases/download/\(NSRegularExpression.escapedPattern(for: tag))/[^\"]+)\""
                guard let assetRegex = try? NSRegularExpression(pattern: assetPattern) else { return nil }
                let matches = assetRegex.matches(
                    in: html,
                    options: [],
                    range: NSRange(html.startIndex..<html.endIndex, in: html))
                for match in matches {
                    guard let pathRange = Range(match.range(at: 1), in: html) else { continue }
                    let path = String(html[pathRange])
                    guard path.lowercased().contains("macos-x86_64"),
                          path.lowercased().hasSuffix(".dmg") else { continue }
                    return UpstreamRelease(
                        version: version,
                        downloadURL: "https://github.com\(path)",
                        sha256: nil)
                }
                return nil
            },
            uploadRelease: true
        ))
    }
}
