cask "github-copilot-app" do
<<<<<<< Updated upstream
  # 版本形态：<宿主版本>-cn<补丁序号>，与 antigravity 同约定（AGENTS 11.61 第 9 条）。
  version "1.4.3-cn4"
  sha256 "8a0441f2345d7639b468790138c7a0c23a2093e0233df69a12b2710fbd6753e7"
=======
  version "1.4.3"
  # 上游 github/app 按架构分包：core 的 url/sha 是 darwin-arm64 的，本 tap 取
  # GitHub-Copilot-darwin-x64.dmg（主二进制 file 实测 x86_64 thin）。
  # Intel 包的 sha256 由检查器下载实算（core 那份属于另一个架构的包，不能用）。
  # 镜像到本仓 Release（tag github-copilot-app-<ver>，资产名沿用上游 basename，
  # 无空格无需换点）：本 tap 政策是所有 cask 都镜像最新版（AGENTS 11.34）；
  # url 用 #{version} 插值过 audit 的 unversioned 检查。版本判据走 core cask
  # API（api/cask/github-copilot-app.json 的 .version）；上游另有 floating
  # 短链 gh.io/copilot-app-mac-intel（releases/latest/download/...）——HEAD
  # 探测不跟随跳转，检查器只能用版本化直链。
  sha256 "9aabf8a001091557c7ff89305c2b73fdab1cd7d2d0b7425363072865b5e0a6b5"
>>>>>>> Stashed changes

  url "https://github.com/Bemly/homebrew-tahoe/releases/download/github-copilot-app-#{version}/GitHub-Copilot-darwin-x64.dmg"
  name "GitHub Copilot"
  desc "Native client for GitHub Copilot"
  homepage "https://github.com/github/app"

  auto_updates true
  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "GitHub Copilot.app"

  zap trash: [
    "~/Library/Application Support/com.github.githubapp",
    "~/Library/Caches/com.github.githubapp",
    "~/Library/Preferences/com.github.githubapp.plist",
    "~/Library/WebKit/com.github.githubapp",
  ]
end
