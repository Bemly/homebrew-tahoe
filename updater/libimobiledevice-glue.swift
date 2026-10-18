// updater/libimobiledevice-glue.swift —— 与 Formula/libimobiledevice-glue.rb 一一同名的检查器入口
//
// 代编译模式（qemu 链）：url 与 sha256 直取 formulae.brew.sh JSON 的 urls.stable。
//
// 运行：swiftc updater/UpdaterCore.swift updater/libimobiledevice-glue.swift -o /tmp/check-glue && /tmp/check-glue
// （须在仓库根目录执行）

import Foundation

@main
struct LibimobiledeviceGlueCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libimobiledevice-glue", brewName: "libimobiledevice-glue"))
    }
}
