// updater/xcodes.swift —— 与 Formula/xcodes.rb 一一同名的检查器入口
//
// xcodes 在 homebrew/core 有同名公式且只提供 arm64_tahoe 瓶，Intel 端升级会
// 源码编译；本 tap 直接引用上游 XcodesOrg/xcodes 的官方 universal 预编译包。
// 版本判据走 github 流：releases/latest 的跳转目标 tag（不跟随、不耗 API 限额），
// tag 无 v 前缀（如 2.2.1），githubTagPrefix 置 ""。
// 下载源是版本化直链（releases/download/<ver>/xcodes.zip，文件名无版本）；
// 上游无 checksums 清单 → checksumsURL 省略，核心回退下载实算（~7.5MB，仅新版本时）。
// 改写：url 里版本只在路径段（文件名无版本），版本子串替换换路径段即可；
// 公式无显式 version 行——brew 从 URL 扫描能拿到 2.2.1（实测 Version.parse）。
//
// 运行：swiftc -O updater/UpdaterCore.swift updater/xcodes.swift -o /tmp/check-xcodes && /tmp/check-xcodes
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md §9）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct XcodesCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "xcodes",
            downloadURL: { version in
                "https://github.com/XcodesOrg/xcodes/releases/download/\(version)/xcodes.zip"
            },
            githubRepo: "XcodesOrg/xcodes",
            githubTagPrefix: ""
        ))
    }
}
