cask "brewui" do
  version "0.2.1"
  sha256 "cbc44feb39106db06de89dec6452d20ff15086bbe7cb1a9729cf3956ed31a0a8"

  # 直引上游版本化 zip（稳定），不镜像到本仓 Release（zcode 同例）；
  # url 用 #{version} 插值（tag 带 v 前缀、文件名不带），否则 audit 会因
  # "URL 无版本"要求 sha256 :no_check。
  # 版本更新由 updater/brewui.swift 跟 GitHub release（UpdaterCore github 流）。
  url "https://github.com/Homebrew/BrewUI/releases/download/v#{version}/Homebrew-#{version}.zip"
  name "BrewUI"
  desc "Official graphical interface for Homebrew"
  homepage "https://github.com/Homebrew/BrewUI"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  # Universal 包（x86_64+arm64 双切片，实测），单包覆盖双架构，无需 arch 分包。
  depends_on macos: :tahoe

  app "Homebrew.app"

  uninstall quit: "sh.brew.app"
end
