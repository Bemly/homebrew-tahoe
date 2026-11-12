// updater/toshllm.swift —— 与 Casks/toshllm.rb 一一同名的检查器入口
//
// ToshLLM（Intel Mac + AMD GPU 的本地 LLM 运行器，不在 homebrew/core），
// 走 UpdaterCore 的 github 流：版本判据是 releases/latest 的跳转目标 tag
// （HEAD 取 Location，不消耗 GitHub API 限额），tag 前缀 "v" 剥离后即版本号。
//
// 上游资产稳定：ToshLLM-v<ver>.dmg（标准 AVX2 构建，本 tap 只收这个；
// 同 release 另有 -noavx2.dmg 与 engine zip，不取）。
// sha 取 release 的 checksums.txt（约 289B，按资产名精确匹配，仅新版本时拉取）。
// 按本 tap 政策上传本仓 Release（tag toshllm-<ver>，资产名沿用上游 basename），
// cask url 指 Release（blender-5x 同机制）。cask 无 bottle 机制，watcher
// 更新 cask 后不触发 bottle.yml。
//
// 运行：swiftc updater/UpdaterCore.swift updater/toshllm.swift -o /tmp/check-toshllm && /tmp/check-toshllm
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致
//（asset/downloadURL/checksumsURL < uploadRelease < githubRepo）。

import Foundation

@main
struct ToshLLMCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "toshllm",
            formulaPath: "Casks",
            isCask: true,
            asset: { version in "ToshLLM-v\(version).dmg" },
            downloadURL: { version in
                "https://github.com/engeldlgado/toshllm/releases/download/v\(version)/ToshLLM-v\(version).dmg"
            },
            checksumsURL: { version in
                "https://github.com/engeldlgado/toshllm/releases/download/v\(version)/checksums.txt"
            },
            uploadRelease: true,
            githubRepo: "engeldlgado/toshllm"
        ))
    }
}
