// updater/iperf3.swift —— 与 Formula/iperf3.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/iperf3.swift -o /tmp/check-iperf3 && /tmp/check-iperf3
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// userdocs/iperf3-static 的 macOS 静态构建：tag 即 iperf 版本（无 v 前缀，
// 如 3.21），但资产名含 runner 世代后缀（osx-13/osx-15，随维护者换 runner
// 变化，写不死）。customRelease 做两件事：
//   1. 版本判据走 brew iperf3 stable（formulae.brew.sh，不耗 GitHub API 限额）；
//   2. 用 expanded_assets/<ver> 服务端渲染片段抓取当期 mac 资产名，取 osx
//      世代最大者；静态仓若滞后（该版本无片段）则回退猜 osx-15，交由核心
//      HEAD 探测报 upstream-missing（ffprobe 同例），不硬 fail。
// sha 置 nil：核心下载实物（约 1MB）本地实算。

import Foundation

@main
struct Iperf3Check {
    static func main() {
        let config = CheckConfig(
            formula: "iperf3",
            customRelease: {
                guard let json = fetchJSON("https://formulae.brew.sh/api/formula/iperf3.json"),
                      let versions = json["versions"] as? [String: Any],
                      let stable = versions["stable"] as? String, !stable.isEmpty else {
                    return nil
                }
                var suffix = "osx-15"
                let (status, html) = curlText(
                    "https://github.com/userdocs/iperf3-static/releases/expanded_assets/\(stable)")
                if status == 0 {
                    let pattern = "iperf3-amd64-(osx-([0-9]+))"
                    if let regex = try? NSRegularExpression(pattern: pattern),
                       !html.isEmpty {
                        let range = NSRange(html.startIndex..<html.endIndex, in: html)
                        let gens = regex.matches(in: html, range: range).compactMap { m -> Int? in
                            guard let r = Range(m.range(at: 2), in: html) else { return nil }
                            return Int(html[r])
                        }
                        if let best = gens.max() { suffix = "osx-\(best)" }
                    }
                }
                return UpstreamRelease(
                    version: stable,
                    downloadURL: "https://github.com/userdocs/iperf3-static/releases/download/\(stable)/iperf3-amd64-\(suffix)",
                    sha256: nil)
            }
        )
        runCheck(config)
    }
}
