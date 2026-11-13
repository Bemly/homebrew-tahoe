// updater/lceda-pro.swift —— 与 Casks/lceda-pro.rb 一一同名的检查器入口
//
// 嘉立创EDA专业版（LCEDA Pro，不在 homebrew/core），走 customRelease +
// uploadRelease 单架构镜像：版本判据是嘉立创下载页
//（https://lceda.cn/page/download?src=index）里 Mac 段 Intel(x64) 行的
// lceda-pro-mac-x64-<ver>.zip 文件名。
//
// 页面同时列出专业版/标准版、x64/arm64/linux/windows 等产物，必须用
// 产品专属前缀（lceda-pro-mac-x64-）锚定，裸扫版本必误抓。
// 上游无 checksums 文件 → 有更新时回退下载 zip 本地实算（约 373MB，仅检测到
// 新版本时发生），并按本 tap 政策上传本仓 Release（tag lceda-pro-<ver>，
// 资产名沿用上游 basename），cask url 指 Release。
// cask 无 bottle 机制，watcher 更新 cask 后不触发 bottle.yml。
//
// 运行：swiftc updater/UpdaterCore.swift updater/lceda-pro.swift -o /tmp/check-lceda-pro && /tmp/check-lceda-pro
// （须在仓库根目录执行；新增软件照抄本文件改配置即可，见 AGENTS.md 9.3）
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致
//（customRelease < uploadRelease，grok-bot.swift 同例）。

import Foundation

@main
struct LcedaProCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "lceda-pro",
            formulaPath: "Casks",
            isCask: true,
            customRelease: {
                let (status, html) = curlText("https://lceda.cn/page/download?src=index")
                guard status == 0, !html.isEmpty else { return nil }
                // 锚定产品专属文件名：lceda-pro-mac-x64-<ver>.zip
                let pattern = "/files/(lceda-pro-mac-x64-([0-9]+(?:\\.[0-9]+)+)\\.zip)"
                guard let regex = try? NSRegularExpression(pattern: pattern),
                      let m = regex.firstMatch(
                          in: html,
                          range: NSRange(html.startIndex..<html.endIndex, in: html)),
                      let fr = Range(m.range(at: 1), in: html),
                      let vr = Range(m.range(at: 2), in: html) else { return nil }
                let filename = String(html[fr])
                let version = String(html[vr])
                return UpstreamRelease(
                    version: version,
                    downloadURL: "https://image.lceda.cn/files/\(filename)",
                    sha256: nil)
            },
            uploadRelease: true
        ))
    }
}
