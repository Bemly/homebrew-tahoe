// updater/llvm.swift —— 与 Formula/llvm.rb 一一同名的检查器入口
//
// llvm 在 homebrew/core，走 UpdaterCore 的 brew 流全量式：只给 brewName，
// url 与 sha256 直取 formulae.brew.sh JSON 的 urls.stable.url / .checksum
//（即 core 公式 stable 块指向的真实上游源码 + Homebrew 维护的校验和，
// 上游换镜像自动跟随，见 AGENTS.md 6 节「qemu 代编译模式」）。
// 上游只发源码、无 macOS 预编译（23.x 起连 Intel 预编译都砍了，
// 19.1.7 是最后一个 macOS-X64 包），本 tap 走代编译模式：
// CI 在 macos-26-intel 现编出瓶；构建依赖 cmake/ninja 走本 tap 全名瓶，
// python@3.15/z3/zstd 枢纽留 core 裸名（见 Formula/llvm.rb）。
// core 的 unofficial patch 已 vendor 到本仓 Patches/llvm/ 下（LocalPatch 按
// tap 根解析，brew install 时能找到，无需改动公式 patch 块）。
//
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致.

import Foundation

@main
struct LlvmCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "llvm",
            brewName: "llvm"
        ))
    }
}
