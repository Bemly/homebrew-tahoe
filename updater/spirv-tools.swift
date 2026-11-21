// updater/spirv-tools.swift —— 与 Formula/spirv-tools.rb 一一同名的检查器入口

import Foundation

@main
struct SpirvToolsCheck {
    static func main() {
        runCheck(CheckConfig(formula: "spirv-tools", brewName: "spirv-tools"))
    }
}
