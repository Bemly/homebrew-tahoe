// updater/github-copilot-app.swift —— 与 Casks/github-copilot-app.rb 一一同名的检查器入口
//
// GitHub Copilot 桌面 app（github/app）。在 homebrew/core 里是 **cask**，
// core 那份是 darwin-arm64 的 dmg（url/sha 都是 arm64 的，不能直接取）；
// 本 tap 取上游按架构分包的 GitHub-Copilot-darwin-x64.dmg。
//
// 版本判据：formulae.brew.sh 的 cask API（api/cask/github-copilot-app.json
// 的 .version），走 UpdaterCore 的 brewCask 分支。
// 下载源必须用版本化直链（releases/download/v<ver>/...）：上游还有 floating
// 链接 gh.io/copilot-app-mac-intel（releases/latest/download/...）——核心的
// HEAD 探测不跟随跳转，floating 链接的 302/直链形态不可用。
// sha256：core 那份属于 arm64 包 → 置 nil，核心回退下载实算（~268MB，
// 仅新版本时发生）。
// 镜像：uploadRelease=true（全 cask 镜像政策，AGENTS 11.34）——有更新时上传
// 本仓 Release（tag github-copilot-app-<ver>，资产名沿用上游 basename，
// 无空格无需换点；旧 release 自动清理），url 整条改写为 Release 地址。
//
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致。

import Foundation

@main
struct GithubCopilotAppCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "github-copilot-app",
            formulaPath: "Casks",
            isCask: true,
            brewName: "github-copilot-app",
            downloadURL: { version in
                "https://github.com/github/app/releases/download/v\(version)/GitHub-Copilot-darwin-x64.dmg"
            },
            brewCask: true,
            uploadRelease: true
        ))
    }
}
