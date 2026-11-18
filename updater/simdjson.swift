// updater/simdjson.swift —— 与 Formula/simdjson.rb 一一同名的检查器入口

import Foundation

@main
struct SimdjsonCheck {
    static func main() {
        runCheck(CheckConfig(formula: "simdjson", brewName: "simdjson"))
    }
}
