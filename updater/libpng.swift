// updater/libpng.swift —— 与 Formula/libpng.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/libpng.swift -o /tmp/check-libpng && /tmp/check-libpng
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// brew JSON 全量流：版本 / 上游直链 / sha256 全部取自 formulae.brew.sh JSON 的
// urls.stable（即 core 公式 url 行指向的真实上游，上游换镜像自动跟随，免维护模板）。

import Foundation

@main
struct LibpngCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libpng", brewName: "libpng"))
    }
}
