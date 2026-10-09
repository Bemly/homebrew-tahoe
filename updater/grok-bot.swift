// updater/grok-bot.swift —— 与 Casks/grok-bot.rb 一一同名的检查器入口
//
// Grok Bot（Cursor 桌面 agent，不在 homebrew/core），走 customRelease +
// uploadRelease 单架构镜像：版本判据是 cursor 下载页
//（https://cursor.com/cn/download/bot）上 Mac (Intel) 行的直链版本号。
//
// 页面里还有 0.814.049 之类无关版本（另个产品），故必须锚定
// `darwin-x64/<ver>/Grok_Bot_` 取版本号，裸扫版本必误抓。
// 上游无 checksums 文件 → 有更新时回退下载 dmg 本地实算（约 155MB，仅检测到
// 新版本时发生），并按本 tap 政策上传本仓 Release（tag grok-bot-<ver>，
// 资产名沿用上游 basename），cask url 指 Release。
// cask 无 bottle 机制，watcher 更新 cask 后不触发 bottle.yml。
//
// 运行：swiftc updater/UpdaterCore.swift updater/grok-bot.swift -o /tmp/check-grok-bot && /tmp/check-grok-bot
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致
//（customRelease < uploadRelease，konsole.swift 同例）。

import Foundation

@main
struct GrokBotCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "grok-bot",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                // 纯 Foundation 同步抓取（无 curl 重试；失败返回 nil 由核心 fail 明示）
                guard let url = URL(string: "https://cursor.com/cn/download/bot"),
                      let html = try? String(contentsOf: url, encoding: .utf8) else { return nil }
                let pattern = "darwin-x64/([0-9]+\\.[0-9]+\\.[0-9]+)/Grok_Bot_"
                guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
                let range = NSRange(html.startIndex..<html.endIndex, in: html)
                guard let m = regex.firstMatch(in: html, options: [], range: range),
                      let vr = Range(m.range(at: 1), in: html) else { return nil }
                let v = String(html[vr])
                return UpstreamRelease(version: v,
                    downloadURL: "https://downloads.cursor.com/grokbot/stable/darwin-x64/\(v)/Grok_Bot_\(v)_x64.dmg",
                    sha256: nil)
            },
            uploadRelease: true
        ))
    }
}
