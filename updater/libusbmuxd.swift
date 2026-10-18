// updater/libusbmuxd.swift —— 与 Formula/libusbmuxd.rb 一一同名的检查器入口
//
// 代编译模式（qemu 链）：url 与 sha256 直取 formulae.brew.sh JSON 的 urls.stable。
//
// 运行：swiftc updater/UpdaterCore.swift updater/libusbmuxd.swift -o /tmp/check-libusbmuxd && /tmp/check-libusbmuxd
// （须在仓库根目录执行）

import Foundation

@main
struct LibusbmuxdCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libusbmuxd", brewName: "libusbmuxd"))
    }
}
