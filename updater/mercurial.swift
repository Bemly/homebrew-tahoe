// updater/mercurial.swift —— 与 Formula/mercurial.rb 一一同名的检查器入口

import Foundation

@main
struct MercurialCheck {
    static func main() {
        runCheck(CheckConfig(formula: "mercurial", brewName: "mercurial"))
    }
}
