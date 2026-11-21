// updater/libgcrypt.swift —— 与 Formula/libgcrypt.rb 一一同名的检查器入口

import Foundation

@main
struct LibgcryptCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libgcrypt", brewName: "libgcrypt"))
    }
}
