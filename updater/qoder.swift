// updater/qoder.swift —— 与 Casks/qoder.rb 一一同名的检查器入口
//
// Qoder CN（qoder.cn，国内版；core 的 cask "qoder" 是 qoder.com 国际版）。
// 上游下载页给的是浮动安装器 latest 链接，没有版本号；但官方更新日志
//（https://changelog.qoder.cn/qoder）按发布时间倒序列出版本，首个
// `<a id="x.y.z">` 锚点即最新版。版本判据走 customRelease 抓该锚点，
// 下载直链用版本化真身 DMG
//（https://static.qoder.com.cn/qoder-app/releases/<ver>/Qoder-CN-mac-x64.dmg，
// 安装器里的 installer-manifest.json 同版本，真身 thin x86_64、公证签名）。
//
// 若日志先于安装包发布，HEAD 探测版本化 DMG 会 404 → 核心发
// status=upstream-missing 开 issue，不会写出坏文件。
// 上游无 checksums 清单 → 有更新时下载 dmg 本地实算（约 322MB，仅新版本时
// 发生），并按本 tap 政策上传本仓 Release（tag qoder-<ver>，资产名沿用上游
// basename），cask url 指 Release。
// cask 无 bottle 机制，watcher 更新 cask 后不触发 bottle.yml。
//
// 运行：swiftc updater/UpdaterCore.swift updater/qoder.swift -o /tmp/check-qoder && /tmp/check-qoder
// （须在仓库根目录执行）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致
//（customRelease < uploadRelease）。

import Foundation

@main
struct QoderCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "qoder",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                let (status, html) = curlText("https://changelog.qoder.cn/qoder")
                guard status == 0,
                      let regex = try? NSRegularExpression(
                          pattern: #"<a id="([0-9]+\.[0-9]+\.[0-9]+)""#) else { return nil }
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                guard let m = regex.firstMatch(in: html, options: [], range: range),
                      let r = Range(m.range(at: 1), in: html) else { return nil }
                let version = String(html[r])
                return UpstreamRelease(
                    version: version,
                    downloadURL: "https://static.qoder.com.cn/qoder-app/releases/\(version)/Qoder-CN-mac-x64.dmg",
                    sha256: nil
                )
            },
            uploadRelease: true
        ))
    }
}
