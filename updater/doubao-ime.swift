// updater/doubao-ime.swift —— 与 Casks/doubao-ime.rb 一一同名的检查器入口
//
// 豆包输入法（桌面输入法，不在 brew core），走 CheckConfig.customRelease
// 自定义版本来源 + isCask 模式（与 workbuddy.swift 同构）。
// 版本源用它的官方下载接口：返回 version_name / 直链（无 sha，由核心下载实算）。
//
// 接口（普通 curl 即可，无需特殊 header）：
//   curl -fsSL "https://shurufa.doubao.com/api/v1/app/download_url?platform=macos"
//   → {"code":0,"data":{"url":".../DoubaoImeInstaller_v90703_release.zip",
//      "version_code":1002008,"version_name":"V0.9.7"},"msg":"success"}
//
// 实测要点（2026-09-04，版本 0.9.7 / v90703）：
// - version_name 带 "V" 前缀（V0.9.7），cask 版本去 V（与真身 plist 的
//   CFBundleShortVersionString 0.9.7 一致）；条件去前缀，上游哪天不带 V 也兼容；
// - 接口不给 sha → sha256 置 nil，核心在有更新时下载 zip 本地实算
//   （约 190MB，仅在检测到新版本时发生，同 workbuddy 的 465MB 模式）；
// - 上游发布的是安装器（外层 DoubaoImeInstaller_v90703.app），真身是其内部
//   DoubaoIme.zip 里的 DoubaoIme.app（universal x86_64+arm64，已签名），
//   由 cask 的 installer script 自动跑官方 install.sh 装进 /Library/Input Methods；
// - 外层文件名/目录名含构建号（v90703），每次部署都变 → URL 整条动态获取，
//   公式改写也必须整条替换（UpdaterCore.rewriteFormula 已如此实现）；
// - cask 的 installer 可执行路径经 preflight 固定名，不受构建号 churn 影响。
//
// cask 分发：核心在检测到更新后，把 zip 上传到本仓 GitHub Release（tag 为
// doubao-ime-<version>），cask url 取 Release 资产地址；发版后除本次 tag 外，
// 其余 doubao-ime-* 旧 release 全删（核心 deleteOldCaskReleases 已实现）。

import Foundation

@main
struct DoubaoImeCheck {
    static func main() {
        let config = CheckConfig(
            formula: "doubao-ime",
            formulaPath: "Casks",
            isCask: true,
            uploadRelease: true,
            customRelease: {
                guard let json = fetchJSON(
                    "https://shurufa.doubao.com/api/v1/app/download_url?platform=macos"),
                    let code = json["code"] as? Int, code == 0,
                    let data = json["data"] as? [String: Any],
                    let rawVersion = data["version_name"] as? String, !rawVersion.isEmpty,
                    let zipURL = data["url"] as? String, !zipURL.isEmpty else {
                    return nil
                }
                // 去首字母 V（V0.9.7 → 0.9.7，与 plist 一致）；无 V 则原样
                var version = rawVersion
                if version.hasPrefix("V") || version.hasPrefix("v") {
                    version = String(version.dropFirst())
                }
                // 接口不给可用 sha → 置 nil，核心回退下载实算
                return UpstreamRelease(version: version, downloadURL: zipURL, sha256: nil)
            }
        )
        runCheck(config)
    }
}
