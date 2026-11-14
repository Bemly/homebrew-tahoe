// updater/chisel.swift —— 与 Formula/chisel.rb 一一同名的检查器入口
//
// chisel（jpillora/chisel）不在 homebrew/core（core 里同名的 chisel 是 Facebook
// 的 LLDB 命令集，与此无关），走 UpdaterCore 的 github 流：版本判据是
// releases/latest 的跳转目标 tag（HEAD 取 Location，不消耗 GitHub API 限额）。
// tag 带 "v" 前缀（如 v1.12.0），默认 githubTagPrefix "v" 剥离后即版本号。
//
// 资产稳定：chisel_<ver>_darwin_amd64.gz（单文件 gzip，gunzip 还原为 chisel）。
// sha 取同 release 的 chisel_<ver>_checksums.txt（约 8KB，按资产名精确匹配，
// 仅新版本时拉取）。改写：url 里版本出现两处（tag 目录 + 文件名），
// 版本子串替换一次全换。
//
// 运行：swiftc updater/UpdaterCore.swift updater/chisel.swift -o /tmp/check-chisel && /tmp/check-chisel
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致
//（asset/downloadURL/checksumsURL 在 githubRepo 之前）。

import Foundation

@main
struct ChiselCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "chisel",
            asset: { version in "chisel_\(version)_darwin_amd64.gz" },
            downloadURL: { version in
                "https://github.com/jpillora/chisel/releases/download/v\(version)/chisel_\(version)_darwin_amd64.gz"
            },
            checksumsURL: { version in
                "https://github.com/jpillora/chisel/releases/download/v\(version)/chisel_\(version)_checksums.txt"
            },
            githubRepo: "jpillora/chisel"
        ))
    }
}
