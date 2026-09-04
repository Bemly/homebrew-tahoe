// updater/curl3.swift —— 与 Formula/curl3.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/curl3.swift -o /tmp/check-curl3 && /tmp/check-curl3
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// brew JSON 全量流：版本判据是 core curl 的 stable；url/sha 直取 JSON 的
// urls.stable（本公式与 core curl 同源，tarball 一致，上游换镜像自动跟随）。

import Foundation

@main
struct Curl3Check {
    static func main() {
        runCheck(CheckConfig(formula: "curl3", brewName: "curl"))
    }
}
