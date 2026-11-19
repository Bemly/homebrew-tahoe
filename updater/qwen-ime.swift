// updater/qwen-ime.swift —— 与 Casks/qwen-ime.rb 一一同名的检查器入口
// 版本/下载链接来自上游 buwang API（download.qianwen.com/pcdownload/qwenimemac），
// 旧 CDN 域名 umcdn.qianwen.com 按官网逻辑换成 pc-download.qianwen.com。
// 不钉死版本：每次检查取 API 当前返回的最新 Mac dmg，从文件名解析版本。

import Foundation

@main
struct QwenImeCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "qwen-ime",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                let api = "https://download.qianwen.com/pcdownload/qwenimemac?ch=pcqwenime%40homepage_official&platform=mac&from=sdk_web"
                let (status, body) = curlText(api)
                guard status == 0,
                      let json = (try? JSONSerialization.jsonObject(with: Data(body.utf8))) as? [String: Any],
                      let data = json["data"] as? [String: Any],
                      let rawURL = data["url"] as? String,
                      rawURL.contains("QwenimeMac_V") else { return nil }
                let url = rawURL.replacingOccurrences(of: "https://umcdn.qianwen.com",
                                                      with: "https://pc-download.qianwen.com")
                let pattern = #"QwenimeMac_V(\d+(?:\.\d+)+)_mac"#
                let re = try! NSRegularExpression(pattern: pattern)
                let range = NSRange(url.startIndex..<url.endIndex, in: url)
                guard let m = re.firstMatch(in: url, range: range),
                      let vr = Range(m.range(at: 1), in: url) else { return nil }
                return UpstreamRelease(version: String(url[vr]), downloadURL: url, sha256: nil)
            },
            uploadRelease: true
        ))
    }
}
