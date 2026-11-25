// updater/libunistring.swift —— 与 Formula/libunistring.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `libunistring`。

import Foundation

@main
struct LibunistringCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libunistring", brewName: "libunistring"))
    }
}
