cask "brewui" do
  version "0.4.2"
  sha256 "54bbbfe849256b7e4747379510a20c6badf8df43818d60b83feb630a55ed8c91"

  # 镜像到本仓 Release（tag brewui-<ver>，资产名沿用上游）：
  # 本 tap 政策是所有 cask 都镜像最新版（直引只做过渡）；
  # url 用 #{version} 插值，否则 audit 会因"URL 无版本"要求 sha256 :no_check。
  # 版本更新由 updater/brewui.swift 跟 GitHub release（UpdaterCore github 流），
  # 有更新时下载、上传 Release、改写本文件。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/brewui-0.4.2/Homebrew-0.4.2.zip"
  name "BrewUI"
  desc "Official graphical interface for Homebrew"
  homepage "https://github.com/Homebrew/BrewUI"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  # Universal 包（x86_64+arm64 双切片，实测），单包覆盖双架构，无需 arch 分包。
  depends_on macos: :tahoe

  app "Homebrew.app"

  uninstall quit: "sh.brew.app"
end
