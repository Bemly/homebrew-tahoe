// updater/workbuddy.swift —— 与 Casks/workbuddy.rb 一一同名的检查器入口
//
// WorkBuddy（腾讯 AI 办公工作台，Electron 桌面 app）不在 brew core，
// 走 CheckConfig.customRelease 自定义版本来源 + isCask 模式。
// 版本源用它的客户端自动更新接口：已装出去的 app 全靠它升级，官网前端
// 怎么改版这个接口都得活着，比解析网页稳（SPA + minified JS，抓不到也绝不
// 依赖压缩后的标识符/chunk 文件名）。
//
// 接口（普通 curl 即可，无需特殊 header）：
//   curl -fsSL "https://www.workbuddy.cn/v2/update?platform=workbuddy-darwin-x64"
//   → {"version":"5.4.7.37521366","url":"...WorkBuddy-darwin-x64-<ver>-<buildhash>.zip",
//      "sha256hash":"..."}
//
// 实测要点（2026-09-03，版本 5.4.7.37521366）：
// - 官网下载按钮的 .dmg 就是把 url 的 .zip 后缀换成 .dmg（COS 上两者都在，HTTP 200 验证）；
// - sha256hash 实测是 **dmg** 的 sha256，与 zip 实算**不符**——所以本入口把 sha256 置 nil，
//   让核心在有更新时下载 zip 本地实算（约 465MB，仅在检测到新版本时发生）；
// - 不用 dmg 做原料：brew 6.0.21 的 DmgUnpackStrategy 遇到 dmg 里指向
//   /Applications 的符号链接会调不存在的 MacOS.system_dir? 直接崩（上游 bug），
//   zip 解包不走该路径；
// - 产物文件名带版本号 + git 哈希（-b148bd1d），每次部署都变 → URL 整条动态获取，
//   公式改写也必须整条替换（UpdaterCore.rewriteFormula 已如此实现）；
// - app 内 CFBundleShortVersionString 只有三段（5.4.7），构建号 .37521366 不在 plist 里；
// - 主二进制 Contents/MacOS/Electron（未改名），x86_64 thin，已签名（runtime 标记）；
// - 其他 platform 值：arm64 = "workbuddy-darwin-arm64"，Windows = "workbuddy-win32-x64-user"。
//
// cask 分发：核心在检测到更新后，把 zip 上传到本仓 GitHub Release（tag 为
// workbuddy-<version>），cask url 取 Release 资产地址——这样即使上游 COS 删档，
// 本仓 Release 里还有一份；且 cask 的 url 是普通 HTTPS，无需 GHCR 的 docker registry
// 认证（文档核实：cask 无 bottle 机制，不能走 GHCR）。

import Foundation

@main
struct WorkbuddyCheck {
    static func main() {
        let config = CheckConfig(
            formula: "workbuddy",
            formulaPath: "Casks",
            isCask: true,
            uploadRelease: true,
            customRelease: {
                guard let json = fetchJSON(
                    "https://www.workbuddy.cn/v2/update?platform=workbuddy-darwin-x64"),
                    let version = json["version"] as? String, !version.isEmpty,
                    let zipURL = json["url"] as? String, !zipURL.isEmpty else {
                    return nil
                }
                // sha256hash 是 dmg 的、对 zip 无效 → 置 nil，核心回退下载实算
                return UpstreamRelease(version: version, downloadURL: zipURL, sha256: nil)
            }
        )
        runCheck(config)
    }
}
