// updater/lody.swift —— 与 Casks/lody.rb 一一同名的检查器入口
//
// Lody（lody.ai，不在本 tap 之外另做版本判断）：在 homebrew/core 里是 cask，
// 版本取 formulae.brew.sh 的 cask API（.version），走 UpdaterCore 的 brewCask 分支。
// core cask 默认 URL 是 arm64；本 tap 的 downloadURL 模板固定取 Intel x64 dmg
// （Lody-<ver>-x64.dmg，sha 回退下载实算）。
// 镜像：uploadRelease=true（全 cask 镜像政策，AGENTS 11.34）——有更新时上传
// 本仓 Release（tag lody-<ver>，资产名沿用上游 basename；旧 release 自动清理），
// cask url 指 Release。cask 无 bottle 机制，watcher 更新后不触发 bottle.yml。
//
// 运行：swiftc updater/UpdaterCore.swift updater/lody.swift -o /tmp/check-lody && /tmp/check-lody
// （须在仓库根目录执行）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct LodyCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "lody",
            formulaPath: "Casks",
            isCask: true,
            brewName: "lody",
            downloadURL: { version in
                "https://updates.lody.ai/production/Lody-\(version)-x64.dmg"
            },
            brewCask: true,
            uploadRelease: true
        ))
    }
}
