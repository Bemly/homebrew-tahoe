// updater/dsh-gui.swift —— 与 Casks/dsh-gui.rb 一一同名的检查器入口
//
// DeepSeek Harness 桌面端（与本 tap 的 deepseek-harness 公式/npm CLI 版同源不同物）。
// 版本信号来自上游 nightly feed：
//   https://download.deepseek.com/dsh-desk/feeds/mac-x64/nightly-mac.yml
// 里面有 version 与 sha512（zip 的），Intel dmg 的同版本直链按固定模板拼：
//   .../dsh-desk/bin/mac-x64/deepseek-harness-<ver>-mac-x64.dmg
// 不再用浮动直链（dsh-latest-*.dmg）+ 镜像日期 + alwaysUpdate；现在与其他包一样
// 按版本判新，只有 feed 版本更新时才下载实算 sha、镜像到本仓 Release 并改写 cask。
//
// 运行：swiftc updater/UpdaterCore.swift updater/dsh-gui.swift -o /tmp/check-dsh-gui && /tmp/check-dsh-gui
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）

import Foundation

@main
struct DshGuiCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "dsh-gui",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                let feed = "https://download.deepseek.com/dsh-desk/feeds/mac-x64/nightly-mac.yml"
                let (status, body) = curlText(feed)
                guard status == 0, !body.isEmpty else { return nil }
                var version: String?
                for raw in body.components(separatedBy: CharacterSet.newlines) {
                    let line = raw.trimmingCharacters(in: .whitespaces)
                    guard line.hasPrefix("version:") else { continue }
                    let v = line.dropFirst("version:".count)
                        .trimmingCharacters(in: .whitespaces)
                    if !v.isEmpty { version = v; break }
                }
                guard let v = version else { return nil }
                return UpstreamRelease(
                    version: v,
                    downloadURL: "https://download.deepseek.com/dsh-desk/bin/mac-x64/deepseek-harness-\(v)-mac-x64.dmg",
                    sha256: nil)
            },
            uploadRelease: true
        ))
    }
}
