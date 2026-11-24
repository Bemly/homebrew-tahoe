// updater/nasm.swift —— 官方 NASM macOS Intel 预编译包检查器

import Foundation

@main
struct NasmCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "nasm",
            customRelease: {
                let (status, html) = curlText("https://www.nasm.us/pub/nasm/releasebuilds/")
                guard status == 0,
                      let regex = try? NSRegularExpression(pattern: #"href="v?([0-9]+(?:\.[0-9]+)+)/""#) else {
                    return nil
                }
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                let versions = regex.matches(in: html, range: range).compactMap { match -> String? in
                    guard let value = Range(match.range(at: 1), in: html) else { return nil }
                    return String(html[value])
                }
                guard let latest = versions.max(by: {
                    $0.split(separator: ".").compactMap { Int($0) }
                        .lexicographicallyPrecedes($1.split(separator: ".").compactMap { Int($0) })
                }) else { return nil }
                return UpstreamRelease(
                    version: latest,
                    downloadURL: "https://www.nasm.us/pub/nasm/releasebuilds/\(latest)/macosx/nasm-\(latest)-macosx.zip",
                    sha256: nil)
            }
        ))
    }
}
