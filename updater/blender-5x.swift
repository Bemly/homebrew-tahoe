// updater/blender-5x.swift —— 与 Casks/blender-5x.rb 一一同名的检查器入口
//
// jaguarus83 的 Blender 5.x Intel Mac 构建，不在 homebrew/core，走 UpdaterCore
// 的 github 流：版本判据是 releases/latest 的跳转目标 tag（HEAD 取 Location，
// 不消耗 GitHub API 限额），tag 前缀 "v" 剥离后即版本号。
//
// 上游资产名不稳定（5.0.1 是 Blender-5.0.1-x86_64.dmg，5.2.x 是
// Blender-<ver>-macOS-x86_64-AMD.dmg）：downloadURL 模板按最新形态写；
// 上游若改名，HEAD 探测 404 即报 upstream-missing 开 issue（不写坏文件），
// 到时人工同步模板与资产名。
//
// 上游无 checksums 文件 → 有更新时回退下载 dmg 本地实算（约 400MB，仅检测到
// 新版本时发生），并按本 tap 政策上传本仓 Release（tag blender-5x-<ver>，
// 资产名沿用上游 basename），cask url 指 Release（brewui 同机制）。
// cask 无 bottle 机制，watcher 更新 cask 后不触发 bottle.yml。
//
// 运行：swiftc updater/UpdaterCore.swift updater/blender-5x.swift -o /tmp/check-blender-5x && /tmp/check-blender-5x
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct Blender5xCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "blender-5x",
            formulaPath: "Casks",
            isCask: true,
            downloadURL: { version in
                "https://github.com/jaguarus83/blender-5x-intel-mac-builds/releases/download/v\(version)/Blender-\(version)-macOS-x86_64-AMD.dmg"
            },
            checksumsURL: nil,
            uploadRelease: true,
            githubRepo: "jaguarus83/blender-5x-intel-mac-builds"
        ))
    }
}
