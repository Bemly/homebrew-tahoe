// updater/ffmpeg.swift —— 与 Formula/ffmpeg.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/ffmpeg.swift -o /tmp/check-ffmpeg && /tmp/check-ffmpeg
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// evermeet 静态发行版：版本化 zip（ffmpeg-<ver>.zip），release 即 FFmpeg 版本，
// 与 homebrew/core 的 ffmpeg stable 同步（当前同为 9.0.1），故版本判据走 brew 流。
// 上游不提供 checksums 汇总文件 → checksumsURL 置 nil，核心在有更新时回退下载
// zip 本地实算（约 26MB，仅检测到新版本时发生）。
// 不用 getrelease 的 7z：brew 解 7z 需要 p7zip（core 在 Intel Tahoe 无瓶），
// 公式用 zip（见 Formula/ffmpeg.rb 头注），检查器模板与公式 url 保持一致。

import Foundation

@main
struct FfmpegCheck {
    static func main() {
        let config = CheckConfig(
            formula: "ffmpeg",
            brewName: "ffmpeg",
            asset: { version in "ffmpeg-\(version).zip" },
            downloadURL: { version in
                "https://evermeet.cx/ffmpeg/ffmpeg-\(version).zip"
            },
            checksumsURL: nil
        )
        runCheck(config)
    }
}
