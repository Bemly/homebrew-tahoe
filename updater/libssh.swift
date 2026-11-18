// updater/libssh.swift —— 与 Formula/libssh.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `libssh`。

import Foundation

@main
struct LibsshCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libssh", brewName: "libssh"))
    }
}
