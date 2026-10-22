// updater/llvm-mingw.swift —— 与 Formula/llvm-mingw.rb 一一同名的检查器入口
//
// mstorsjo/llvm-mingw 的 macOS universal 预编译（x86_64+arm64 双切片，Intel 走 x86_64 切片），
// 不在 homebrew/core，走 UpdaterCore 的 github 流：版本判据是
// mstorsjo/llvm-mingw 的 releases/latest 跳转目标 tag（日期如 20261020，无 v 前缀）。
// 本 tap 只收 ucrt-macos-universal 段（winX64/winA64 双 target 一包，宿主 universal）。
// 下载源是版本化直链（releases/download/<ver>/llvm-mingw-<ver>-ucrt-macos-universal.tar.xz）；
// 上游无 checksums 清单，checksumsURL 置 nil，有更新时下载实算（约 124MB，仅新版本时发生）。
// 改写：文件名含版本，版本子串替换；公式无 version 行（brew 从 URL 扫描，x86_64 尾缀不致盲，见 11.19）。
//
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致.

import Foundation

@main
struct LlvmMingwCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "llvm-mingw",
            asset: { version in
                "llvm-mingw-\(version)-ucrt-macos-universal.tar.xz"
            },
            downloadURL: { version in
                "https://github.com/mstorsjo/llvm-mingw/releases/download/\(version)/llvm-mingw-\(version)-ucrt-macos-universal.tar.xz"
            },
            checksumsURL: nil,
            githubRepo: "mstorsjo/llvm-mingw",
            githubTagPrefix: ""
        ))
    }
}
