// updater/libusb.swift —— 与 Formula/libusb.rb 一一同名的检查器入口
//
// brew JSON 全量流：版本 / 上游直链 / sha256 直接取 formulae.brew.sh 的 core `libusb`。

import Foundation

@main
struct LibusbCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libusb", brewName: "libusb"))
    }
}
