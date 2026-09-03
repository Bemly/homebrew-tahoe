// updater/sst.swift —— 与 Formula/sst.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/sst.swift -o /tmp/check-sst && /tmp/check-sst
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// raw 流：版本判据是 anomalyco/homebrew-tap 的 sst.rb（GoReleaser 产物），
// sst 不在 homebrew/core，只能走源仓库 raw。
// 核心按 GoReleaser 结构解析 version + Intel mac 的 url/sha256，sha 直接取自源文件。

import Foundation

@main
struct SstCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "sst",
            rawFormulaURL: "https://raw.githubusercontent.com/anomalyco/homebrew-tap/master/sst.rb"
        ))
    }
}
