// updater/ncurses.swift —— 与 Formula/ncurses.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `ncurses`。

import Foundation

@main
struct NcursesCheck {
    static func main() {
        runCheck(CheckConfig(formula: "ncurses", brewName: "ncurses"))
    }
}
