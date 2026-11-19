// updater/openjdk.swift —— 与 Formula/openjdk.rb 一一同名的检查器入口
// 版本锁在 OpenJDK 26 GA 线：从 jdk.java.net/archive 抓 Mac/x64 预编译包与官方 sha256。

import Foundation

@main
struct OpenjdkCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "openjdk",
            customRelease: {
                let (status, body) = curlText("https://jdk.java.net/archive/")
                guard status == 0, !body.isEmpty else { return nil }
                let verRe = try! NSRegularExpression(pattern: #"26\.0\.[0-9.]+"#)
                let range = NSRange(body.startIndex..<body.endIndex, in: body)
                guard let vm = verRe.firstMatch(in: body, range: range),
                      let vr = Range(vm.range, in: body) else { return nil }
                let v = String(body[vr])
                let chunk = String(body[vr.lowerBound...].prefix(8000))
                let urlRe = try! NSRegularExpression(pattern: #"href=\"(https://download\.java\.net/java/GA/[^\"]*macos-x64_bin\.tar\.gz)\""#)
                let shaRe = try! NSRegularExpression(pattern: #"href=\"(https://download\.java\.net/java/GA/[^\"]*macos-x64_bin\.tar\.gz\.sha256)\""#)
                let cr = NSRange(chunk.startIndex..<chunk.endIndex, in: chunk)
                guard let um = urlRe.firstMatch(in: chunk, range: cr),
                      let ur = Range(um.range(at: 1), in: chunk),
                      let sm = shaRe.firstMatch(in: chunk, range: cr),
                      let sr = Range(sm.range(at: 1), in: chunk) else { return nil }
                let downloadURL = String(chunk[ur])
                let (shaStatus, shaBody) = curlText(String(chunk[sr]))
                guard shaStatus == 0 else { return nil }
                let hash = shaBody.trimmingCharacters(in: .whitespacesAndNewlines)
                return UpstreamRelease(version: v, downloadURL: downloadURL, sha256: hash)
            }
        ))
    }
}
