// updater/ipsw.swift —— 与 Formula/ipsw.rb 一一同名的检查器入口

import Foundation

@main
struct IpswCheck {
    static func main() {
        runCheck(CheckConfig(formula: "ipsw", brewName: "ipsw"))
    }
}
