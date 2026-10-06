// updater/dsh-gui.swift —— 与 Casks/dsh-gui.rb 一一同名的检查器入口
//
// DeepSeek Harness 桌面端（与本 tap 的 deepseek-harness 公式/npm CLI 版同源不同物），
// 上游只有浮动直链（dsh-latest-macos-x64.dmg，无版本信号、无 checksums 文件），
// 走 customRelease + uploadRelease + alwaysUpdate：
//   - 版本取检查日（UTC）：浮动内容配如实日期版本，单调递增；
//   - alwaysUpdate：每次检查必走完全链路（下载 386MB 实算 sha → 上传本仓 Release →
//     改写 cask），内容变化不体现在版本号上也能刷进镜像（Watcher 手动触发，代价可控）；
//   - 镜像到本仓 Release（tag dsh-gui-<ver>，资产名沿用上游），cask url 指 Release。
// cask 无 bottle 机制，watcher 更新 cask 后不触发 bottle.yml。
//
// 运行：swiftc updater/UpdaterCore.swift updater/dsh-gui.swift -o /tmp/check-dsh-gui && /tmp/check-dsh-gui
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致
//（customRelease < uploadRelease < ... < alwaysUpdate，末位追加）。

import Foundation

@main
struct DshGuiCheck {
    static func main() {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy.MM.dd"
        let today = formatter.string(from: Date())
        runCheck(CheckConfig(
            formula: "dsh-gui",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                UpstreamRelease(version: today,
                    downloadURL: "https://download.deepseek.com/desktop/dsh-latest-macos-x64.dmg",
                    sha256: nil)
            },
            uploadRelease: true,
            alwaysUpdate: true
        ))
    }
}
