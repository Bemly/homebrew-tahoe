// updater/zig.swift —— 与 Formula/zig.rb 一一同名的检查器入口
//
// zig 在 homebrew/core，走 brew 流：版本判据是 formulae.brew.sh 的 versions.stable。
// 本 tap 取上游 ziglang.org 的 macOS x86_64 预编译（thin x86_64，零依赖），
// core 的 url 是源码 tar.xz 不能直接用，必须由 downloadURL 模板给出 x64 二进制直链。
// 上游无 checksums 清单，checksumsURL 置 nil，有更新时下载实算（约 59MB，仅新版本时发生）。
// 改写：文件名含版本，版本子串替换；公式无 version 行（brew 从 URL 扫描正确）。
//
// 运行：swiftc updater/UpdaterCore.swift updater/zig.swift -o /tmp/check-zig && /tmp/check-zig
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致.

import Foundation

@main
struct ZigCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "zig",
            brewName: "zig",
            asset: { version in
                "zig-x86_64-macos-\(version).tar.xz"
            },
            downloadURL: { version in
                "https://ziglang.org/download/\(version)/zig-x86_64-macos-\(version).tar.xz"
            },
            checksumsURL: nil
        ))
    }
}
