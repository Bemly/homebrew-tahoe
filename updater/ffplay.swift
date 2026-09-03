// updater/ffplay.swift —— 与 Formula/ffplay.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/ffplay.swift -o /tmp/check-ffplay && /tmp/check-ffplay
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// evermeet 把 ffplay 与 ffmpeg 同版本配套发布（当前同为 9.0.1），
// 版本判据走 brew 流的 ffmpeg stable（core 无 ffplay 公式）。
// 上游不提供 checksums 汇总文件 → checksumsURL 置 nil，核心在有更新时回退下载
// zip 本地实算（约 27MB，仅检测到新版本时发生）。

import Foundation

@main
struct FfplayCheck {
    static func main() {
        let config = CheckConfig(
            formula: "ffplay",
            brewName: "ffmpeg",
            asset: { version in "ffplay-\(version).zip" },
            downloadURL: { version in
                "https://evermeet.cx/ffmpeg/ffplay-\(version).zip"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
