// updater/z3.swift —— 与 Formula/z3.rb 一一同名的检查器入口
//
// z3 在 homebrew/core，走 UpdaterCore 的 brew 流全量式：只给 brewName，
// url 与 sha256 直取 formulae.brew.sh JSON 的 urls.stable.url / .checksum
//（llvm 的求解器依赖，扇入 11 全小众工具+llvm/lldb，无枢纽，libplist 同例）。
// 本 tap 自瓶原因有二：core 无 Intel Tahoe 瓶；裸名会让 llvm 的递归依赖同时
// 含 bemly/tahoe/cmake 与 homebrew/core/cmake（后者经 z3 构建依赖进来），
// uniq! 按 full_name 去重留俩，同进程 flock 双开自锁（见 AGENTS.md 11.51）。
// 构建依赖 cmake 走本 tap 全名瓶，python 退到 3.14（runner 旧 core 不认 3.15）。
//
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致.

import Foundation

@main
struct Z3Check {
    static func main() {
        runCheck(CheckConfig(
            formula: "z3",
            brewName: "z3"
        ))
    }
}
