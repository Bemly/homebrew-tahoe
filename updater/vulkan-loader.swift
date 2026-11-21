// updater/vulkan-loader.swift —— 与 Formula/vulkan-loader.rb 一一同名的检查器入口

import Foundation

@main
struct VulkanLoaderCheck {
    static func main() {
        runCheck(CheckConfig(formula: "vulkan-loader", brewName: "vulkan-loader"))
    }
}
