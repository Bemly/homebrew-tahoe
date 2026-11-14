// updater/exiftool.swift —— 与 Formula/exiftool.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/exiftool.swift -o /tmp/check-exiftool && /tmp/check-exiftool
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// brew JSON 全量流：exiftool 在 homebrew/core（同名，core 版带 brotli/xz + CPAN
// XS 资源树，本 tap 精简为纯 Perl 直装），版本判据取 formulae.brew.sh 的
// versions.stable；url 与 sha256 直取 JSON 的 urls.stable.url / .checksum——
// 都是 core 公式指向的那份 Image-ExifTool-<ver>.tar.gz，免下载实算（hintSHA）。
// 公式 url 行整条替换为 JSON 直链（SourceForge），mirror 行（CPAN）按旧版本号
// 子串同步改写；两条都是同一 tarball、同一 sha256（见 AGENTS.md 11.55）。
// 上游直链是 302 跳转，curlHeadOK 不带 -L，HEAD 拿到 302 即算可达。

import Foundation

@main
struct ExiftoolCheck {
    static func main() {
        runCheck(CheckConfig(formula: "exiftool", brewName: "exiftool"))
    }
}
