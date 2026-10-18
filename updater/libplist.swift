// updater/libplist.swift —— 与 Formula/libplist.rb 一一同名的检查器入口
//
// 代编译模式（qemu 链）：url 与 sha256 直取 formulae.brew.sh JSON 的
// urls.stable（即 core 公式 url 行指向的真实上游与 Homebrew 维护的校验和），
// 上游换镜像自动跟随，免维护模板。
//
// 运行：swiftc updater/UpdaterCore.swift updater/libplist.swift -o /tmp/check-libplist && /tmp/check-libplist
// （须在仓库根目录执行）

import Foundation

@main
struct LibplistCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libplist", brewName: "libplist"))
    }
}
