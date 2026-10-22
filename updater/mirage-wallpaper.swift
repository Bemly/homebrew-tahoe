// updater/mirage-wallpaper.swift —— 与 Casks/mirage-wallpaper.rb 一一同名的检查器入口
//
// Mirage（原生动态壁纸管理器，不在 homebrew/core），走 customRelease +
// uploadRelease 单架构镜像（只要 Intel，x86_64 包，见 Casks/mirage-wallpaper.rb）。
//
// 上游按架构分包，Intel 资产名含构建号+短哈希
//（Mirage-<build>-<hash>-macOS-x86_64.zip），版本号只在 tag 路径（v1.1.5），
// 文件名本身无版本——downloadURL 模板拼不出，必须 customRelease 动态发现：
//   1. GET https://github.com/laobamac/MirageWallpaper/releases/latest（跟随跳转
//      后的 tag 页 HTML，不调 GitHub API，不耗限额），解析首个 /tag/v<ver> 得版本；
//   2. GET releases/expanded_assets/<tag> 片段（服务端渲染，iperf3 同例），
//      抓 `Mirage-*-macOS-x86_64.zip"`（尾随引号，天然排除 .sha256 sidecar）；
//   3. 拼出版本化直链；sha 取同名 .sha256 sidecar 首个 64 位 hex（实测与实物一致），
//      取不到则置 nil 由核心下载实算（约 110MB，仅新版本时）。
// 按本 tap 政策上传本仓 Release（tag mirage-wallpaper-<ver>，资产名沿用上游
// basename），cask url 指 Release（整条换，见 UpdaterCore 镜像流；写回后 tag
// 段是字面版本，须手动改回 #{version} 插值再提交，否则新版 audit 的
// unversioned 检查不过，wireshark/doubao-ime 存量漂化同例）。
// cask 无 bottle 机制，watcher 更新 cask 后不触发 bottle.yml。
//
// 运行：swiftc updater/UpdaterCore.swift updater/mirage-wallpaper.swift -o /tmp/check-mirage-wallpaper && /tmp/check-mirage-wallpaper
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致
//（customRelease < uploadRelease，grok-bot.swift 同例）。

import Foundation

@main
struct MirageWallpaperCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "mirage-wallpaper",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                // 1. 最新 tag（/latest 跟随跳转后的 HTML 里取首个 /tag/v<ver>）
                let (ls, latestHTML) = curlText("https://github.com/laobamac/MirageWallpaper/releases/latest")
                guard ls == 0, !latestHTML.isEmpty,
                      let tagRegex = try? NSRegularExpression(pattern: "/tag/(v[0-9][0-9A-Za-z.\\-]*)"),
                      let tagMatch = tagRegex.firstMatch(
                          in: latestHTML,
                          range: NSRange(latestHTML.startIndex..<latestHTML.endIndex, in: latestHTML)),
                      let tagRange = Range(tagMatch.range(at: 1), in: latestHTML) else { return nil }
                let tag = String(latestHTML[tagRange])
                let version = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag

                // 2. 当期 Intel 资产名（expanded_assets 服务端渲染片段）
                let (es, expHTML) = curlText(
                    "https://github.com/laobamac/MirageWallpaper/releases/expanded_assets/\(tag)")
                guard es == 0, !expHTML.isEmpty,
                      let assetRegex = try? NSRegularExpression(
                          pattern: "(Mirage-[^\"]*?-macOS-x86_64\\.zip)\""),
                      let assetMatch = assetRegex.firstMatch(
                          in: expHTML,
                          range: NSRange(expHTML.startIndex..<expHTML.endIndex, in: expHTML)),
                      let assetRange = Range(assetMatch.range(at: 1), in: expHTML) else { return nil }
                let filename = String(expHTML[assetRange])
                let downloadURL = "https://github.com/laobamac/MirageWallpaper/releases/download/\(tag)/\(filename)"

                // 3. sha 取上游 .sha256 sidecar（首个 64 位 hex；取不到则 nil 回退下载实算）
                var sidecarSHA: String? = nil
                let (ss, sidecar) = curlText("\(downloadURL).sha256")
                if ss == 0, !sidecar.isEmpty,
                   let shaRegex = try? NSRegularExpression(pattern: "([0-9a-fA-F]{64})"),
                   let shaMatch = shaRegex.firstMatch(
                       in: sidecar,
                       range: NSRange(sidecar.startIndex..<sidecar.endIndex, in: sidecar)),
                   let shaRange = Range(shaMatch.range(at: 1), in: sidecar) {
                    sidecarSHA = String(sidecar[shaRange]).lowercased()
                }
                return UpstreamRelease(version: version,
                                       downloadURL: downloadURL,
                                       sha256: sidecarSHA)
            },
            uploadRelease: true
        ))
    }
}
