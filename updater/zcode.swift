// updater/zcode.swift —— 与 Casks/zcode.rb 一一同名的检查器入口
//
// ZCode（z.ai 的 AI 辅助开发环境，Electron 桌面 app）在 homebrew/core 里是 **cask**，
// core 那份是 macos-arm64 的 dmg；本 tap 取上游 CDN 的双架构 dmg（x64 + arm64）。
//
// 版本判据：formulae.brew.sh 的 cask API（api/cask/zcode.json 的 .version），
// 走 UpdaterCore 的 brewCask 分支——不是公式的 .versions.stable。
// 双架构产物（archArtifacts + downloadURLForArch，走 runDualArchCheck）：
// 有更新时两个包都下载实算 sha，改写 cask 的 version 行 + 双 sha 行；
// url 行不动（#{version}/#{arch} 插值已覆盖新版本）。
// 两处必须自己给，不能沿用 core 的值：
//   - 直链：core 的 url 是 arm64 的，必须由 downloadURLForArch 模板拼出双直链；
//   - sha256：core 那份属于 arm64 包，对 x64 无效 → 双双实算。
//
// 直引上游 CDN、链接规律（路径与文件名都随版本变化）→ uploadRelease 保持 false：
// 不上传本仓 Release，也不把 url 改写为 Release 地址（与 workbuddy/doubao-ime 不同）。
// cask 无 bottle 机制，watcher 更新 cask 后不触发 bottle.yml。
//
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct ZcodeCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "zcode",
            formulaPath: "Casks",
            isCask: true,
            brewName: "zcode",
            brewCask: true,
            archArtifacts: ["arm64", "x64"],
            downloadURLForArch: { version, arch in
                "https://cdn-zcode.z.ai/zcode/electron/releases/\(version)/macos-\(arch)/ZCode-\(version)-mac-\(arch).dmg"
            }
        ))
    }
}
