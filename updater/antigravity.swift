import Foundation

// Antigravity 中文补丁版的版本检查器。
//
// 与仓库里其它 cask 不同，本包的产物不是「下载上游再镜像」，而是本地构建脚本
// （Widgets/antigravity-niang/build.sh）在官方 darwin-x64 包上打完补丁后重打的
// dmg —— 所以这里**不**开 uploadRelease，只做三件事：
//   1. 判新：版本源取 homebrew/core 的 antigravity cask。它的版本是 Homebrew 的
//      "2.33.0,4731201358004224"（version,build）约定，逗号进 URL 麻烦，这里
//      连成 2.33.0-4731201358004224，再拼本包自己的补丁序号 -cn<REVISION>。
//      带构建号是为了让「宿主只跳构建号」的发布也能判新。
//   2. 取 sha：读构建脚本随包上传的 .sha256 sidecar（避免 250MB 实算）。
//   3. sidecar / Release dmg 尚不存在时：不直接报 upstream-missing，而是检查
//      Silas-02/antigravity-desktop-cn 是否已发布对应 v<appVersion>[.x] tag——
//      已就绪则输出 status=needs-patched-build，由 watch-updates.yml 自动触发
//      patched.yml 构建发布；尚未适配则输出 status=waiting-upstream 暂缓等待，避免误报。
//
// 同一宿主版本重打补丁时，人工把 build.sh 的 --revision 提到 2 并手改 cask 的
// version/sha256；此时本检查器算出的 ...-cn1 小于本地 ...-cn2，会判
// newer-than-brew 而不动文件（防回退，符合预期）。补丁序号在宿主大版本升级时
// 由 build.sh 默认回到 1。
@main
struct AntigravityCheck {
    static func main() {
        // 与 build.sh 的 REVISION 默认值保持一致（新宿主版本的第一个补丁包）。
        let revision = "cn1"
        runCheck(CheckConfig(
            formula: "antigravity",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                guard let core = fetchJSON("https://formulae.brew.sh/api/cask/antigravity.json"),
                      let raw = core["version"] as? String, !raw.isEmpty else { return nil }

                let pieces = raw.split(separator: ",", maxSplits: 1).map(String.init)
                let appVersion = pieces[0]
                let build = pieces.count > 1 ? pieces[1] : ""
                let host = build.isEmpty ? appVersion : appVersion + "-" + build
                let version = host + "-" + revision

                let asset = "Antigravity-" + version + ".dmg"
                let url = "https://github.com/Bemly/homebrew-tahoe/releases/download/antigravity-"
                    + version + "/" + asset

                var sha: String?
                let (status, body) = curlText(url + ".sha256")
                if status == 0 {
                    let token = body.trimmingCharacters(in: .whitespacesAndNewlines)
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
