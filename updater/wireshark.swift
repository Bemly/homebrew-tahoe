// updater/wireshark.swift —— 与 Casks/wireshark.rb 一一同名的检查器入口
//
// 运行：swiftc updater/UpdaterCore.swift updater/wireshark.swift -o /tmp/check-wireshark && /tmp/check-wireshark
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：swiftc 只允许 main.swift 含顶层代码，所以入口用 @main 而不是裸语句。
//
// 上游 Intel 构建停在 4.4 系（4.6+ 无 Intel dmg），版本不能跟 brew（core
// stable 是 4.6.8）。customRelease 解析官方 Sparkle appcast：
//   https://www.wireshark.org/update/0/Wireshark/0.0.0/macOS/x86-64/en-US/stable.xml
// 取 enclosure url 含 "Intel%2064.dmg"（URL 编码后形态；编码前是 "Intel 64.dmg"）
// 的那一项：sparkle:shortVersionString 即版本，同项注释里的 SHA256 即校验和
// （官方给出，无需下载 66MB 实算）。appcast 的 enclosure host 是 dl 镜像
// （2.na.dl.wireshark.org），归一化到 www 主站同路径（实测同文件，长度一致）。

import Foundation

@main
struct WiresharkCheck {
    static func main() {
        let config = CheckConfig(
            formula: "wireshark",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                let (status, xml) = curlText(
                    "https://www.wireshark.org/update/0/Wireshark/0.0.0/macOS/x86-64/en-US/stable.xml")
                guard status == 0, !xml.isEmpty else { return nil }
                // enclosure 行（url 含 Intel 64）+ 紧随的 SHA256 注释
                let pattern = #"url="([^"]*Intel%2064\.dmg)"[^>]*sparkle:shortVersionString="([^"]+)".*?<!--\s*SHA256:\s*([0-9a-fA-F]{64})"#
                guard let regex = try? NSRegularExpression(
                    pattern: pattern, options: [.dotMatchesLineSeparators]),
                    let m = regex.firstMatch(
                        in: xml, range: NSRange(xml.startIndex..<xml.endIndex, in: xml)),
                    let ur = Range(m.range(at: 1), in: xml),
                    let vr = Range(m.range(at: 2), in: xml),
                    let sr = Range(m.range(at: 3), in: xml) else {
                    return nil
                }
                var url = String(xml[ur])
                // dl 镜像 host 归一化到 www 主站（同路径同文件）
                if let hostRange = url.range(of: #"https://[^/]+\.dl\.wireshark\.org/"#,
                                             options: .regularExpression) {
                    url.replaceSubrange(hostRange, with: "https://www.wireshark.org/download/")
                }
                return UpstreamRelease(version: String(xml[vr]),
                                       downloadURL: url,
                                       sha256: String(xml[sr]).lowercased())
            }
        )
        runCheck(config)
    }
}
