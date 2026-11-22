// updater/bash.swift —— 与 Formula/bash.rb 一一同名的检查器入口

import Foundation

@main
struct BashCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "bash",
            brewName: "bash",
            manualSyncReason: "Formula/bash.rb 通过 patch_checksum_pairs 跟踪小版本补丁，请从 core 同步新增补丁与 version"
        ))
    }
}
