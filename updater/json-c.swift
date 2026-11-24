// updater/json-c.swift —— 与 Formula/json-c.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `json-c`。

import Foundation

@main
struct JsonCCheck {
    static func main() {
        runCheck(CheckConfig(formula: "json-c", brewName: "json-c"))
    }
}
