import Foundation

// Antigravity 中文补丁版的版本检查器。
//
// 产物不是「下载上游再镜像」，而是 build.sh 在官方 darwin-x64 包上打补丁后重打 dmg。
// 这里不开启 uploadRelease，只负责：
//   1. 从官方下载页动态解析当前 macOS Intel 的「版本-构建号」，不锁死版本；
//   2. 读取本仓已发布产物的 .sha256 sidecar；
//   3. 产物尚不存在时检查 Silas-02/antigravity-desktop-cn 是否已有对应 tag，
//      已就绪则触发 patched.yml，未就绪则 waiting-upstream。
@main
struct AntigravityCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "antigravity",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                let (status, body) = curlText("https://antigravity.google/download")
                guard status == 0, !body.isEmpty else { return nil }
                let pattern = #"https://storage\.googleapis\.com/antigravity-public/antigravity-hub/(\d+(?:\.\d+)+)-(\d+)/darwin-x64/Antigravity\.dmg"#
                guard let regex = try? NSRegularExpression(pattern: pattern),
                      let match = regex.firstMatch(in: body, range: NSRange(body.startIndex..<body.endIndex, in: body)),
                      let appRange = Range(match.range(at: 1), in: body),
                      let buildRange = Range(match.range(at: 2), in: body) else { return nil }
                let host = "\(body[appRange])-\(body[buildRange])"
                let version = host + "-cn1"

                let asset = "Antigravity-" + version + ".dmg"
                let url = "https://github.com/Bemly/homebrew-tahoe/releases/download/antigravity-"
                    + version + "/" + asset

                var sha: String?
                let (sidecarStatus, sidecarBody) = curlText(url + ".sha256")
                if sidecarStatus == 0 {
                    let token = sidecarBody.trimmingCharacters(in: .whitespacesAndNewlines)
                        .split(separator: " ").first.map(String.init) ?? ""
                    let hex = token.lowercased()
                    if hex.count == 64 && hex.allSatisfy({ $0.isHexDigit }) { sha = hex }
                }

                return UpstreamRelease(version: version, downloadURL: url, sha256: sha)
            },
            patchedReadinessCheck: { targetVersion in
                let appVersion = targetVersion.split(separator: "-", maxSplits: 1).first.map(String.init) ?? ""
                guard !appVersion.isEmpty else {
                    return .checkFailed("无法从目标版本解析宿主版本号：\(targetVersion)")
                }
                guard let tags = gitRemoteTags(repo: "Silas-02/antigravity-desktop-cn") else {
                    return .checkFailed("无法拉取 Silas-02/antigravity-desktop-cn 的 tag 列表")
                }
                let exact = "v" + appVersion
                let prefix = exact + "."
                if tags.contains(where: { $0 == exact || $0.hasPrefix(prefix) }) {
                    return .ready
                }
                return .waiting("Silas-02/antigravity-desktop-cn 尚未发布 \(exact) 适配 tag")
            }
        ))
    }
}
