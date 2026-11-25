// updater/readline.swift —— 与 Formula/readline.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `readline`。

import Foundation

@main
struct ReadlineCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "readline",
            brewName: "readline",
            manualSyncReason: "Formula/readline.rb 通过 patch_checksum_pairs 跟踪小版本补丁，请从 core 同步新增补丁与 version"
        ))
    }
}
