// updater/opencode.swift —— 与 Formula/opencode.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/opencode.swift -o /tmp/check-opencode && /tmp/check-opencode
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// raw 流-双架构：版本判据是 anomalyco/homebrew-tap 的 opencode.rb（GoReleaser 产物），
// 不走 homebrew/core（core 的 opencode 是 npm 版，版本与此处无关）。
// 核心按 GoReleaser 结构解析 version + mac 双块的 url/sha256（rawDualArch），
// 改写本公式内双 `if Hardware::CPU` 块；sha 直接取自源文件。

import Foundation

@main
struct OpencodeCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "opencode",
            rawFormulaURL: "https://raw.githubusercontent.com/anomalyco/homebrew-tap/master/opencode.rb",
            rawDualArch: true
        ))
    }
}
