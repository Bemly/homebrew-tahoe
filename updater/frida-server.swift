// updater/frida-server.swift —— 与 Formula/frida-server.rb 一一同名的检查器入口
//
// frida-server 不在 homebrew/core，走 UpdaterCore 的 github 流：版本判据是
// frida/frida 的 releases/latest 跳转目标 tag（不跟随、不耗 GitHub API 限额）。
// frida 的 tag 无 v 前缀（如 17.17.0），githubTagPrefix 置 ""。
// 下载源是版本化直链（releases/download/<ver>/frida-server-<ver>-macos-x86_64.xz）；
// 上游无 checksums 清单 → checksumsURL 省略，核心回退下载实算（~9MB，仅新版本时）。
// 改写：url 里版本出现两处（tag 目录 + 文件名），版本子串替换一次全换；
// 公式无显式 version 行——audit 实测 URL（tag 目录在前）能扫对 17.17.0，
// 不触发 node 式的 x64 致盲（11.15：是否声明以 audit 为准，不要凭字面猜）。
//
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct FridaServerCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "frida-server",
            downloadURL: { version in
                "https://github.com/frida/frida/releases/download/\(version)/frida-server-\(version)-macos-x86_64.xz"
            },
            githubRepo: "frida/frida",
            githubTagPrefix: ""
        ))
    }
}
