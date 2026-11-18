// updater/fork-jpeg-turbo.swift —— 与 Formula/fork-jpeg-turbo.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `jpeg-turbo`。

import Foundation

@main
struct ForkJpegTurboCheck {
    static func main() {
        runCheck(CheckConfig(formula: "fork-jpeg-turbo", brewName: "jpeg-turbo"))
    }
}
