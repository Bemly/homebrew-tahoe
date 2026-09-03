// updater/brewui.swift —— 与 Casks/brewui.rb 一一同名的检查器入口
//
// BrewUI（Homebrew 官方图形界面）不在 homebrew/core，走 UpdaterCore 的
// github 流：版本判据是 releases/latest 的跳转目标 tag（HEAD 取 Location，
// 不消耗 GitHub API 限额），tag 前缀 "v" 剥离后即版本号。
//
// 上游 release 只有 dSYMs/pkg/zip 三个资产、无 checksums 文件 →
// checksumsURL 置 nil，核心在有更新时回退下载 zip 本地实算
//（约 8MB，仅检测到新版本时发生）。
// 直引上游版本化链接，不上传本仓 Release（uploadRelease 保持 false，zcode 同例）。
// cask 无 bottle 机制，watcher 更新 cask 后不触发 bottle.yml。
//
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct BrewuiCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "brewui",
            formulaPath: "Casks",
            isCask: true,
            downloadURL: { version in
                "https://github.com/Homebrew/BrewUI/releases/download/v\(version)/Homebrew-\(version).zip"
            },
            checksumsURL: nil,
            githubRepo: "Homebrew/BrewUI"
        ))
    }
}
