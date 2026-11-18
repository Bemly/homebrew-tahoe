// updater/starship.swift —— 与 Formula/starship.rb 一一同名的检查器入口

import Foundation

@main
struct StarshipCheck {
    static func main() {
        runCheck(CheckConfig(formula: "starship", brewName: "starship"))
    }
}
