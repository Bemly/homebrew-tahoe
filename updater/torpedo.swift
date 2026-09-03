// updater/torpedo.swift —— 与 Formula/torpedo.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/torpedo.swift -o /tmp/check-torpedo && /tmp/check-torpedo
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// raw 流：版本判据是 anomalyco/homebrew-tap 的 torpedo.rb（GoReleaser 产物），
// torpedo 不在 homebrew/core，只能走源仓库 raw。
// 注意源文件里 arm 块在前、intel 块在后，核心解析只认 intel 标记后的 url（见 UpdaterCore）。

import Foundation

@main
struct TorpedoCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "torpedo",
            rawFormulaURL: "https://raw.githubusercontent.com/anomalyco/homebrew-tap/master/torpedo.rb"
        ))
    }
}
