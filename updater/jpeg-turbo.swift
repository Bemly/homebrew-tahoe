// updater/jpeg-turbo.swift —— 与 Formula/jpeg-turbo.rb 一一同名的检查器入口
// 跟踪官方 GitHub Release 的 macOS universal2 DMG，不再走 core 源码公式。

import Foundation

@main
struct JpegTurboCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "jpeg-turbo",
            downloadURL: {
                "https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/\($0)/libjpeg-turbo-\($0).dmg"
            },
            githubRepo: "libjpeg-turbo/libjpeg-turbo",
            githubTagPrefix: ""
        ))
    }
}
