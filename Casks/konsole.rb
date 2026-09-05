cask "konsole" do
  arch arm: "arm64", intel: "x86_64"

  version "5277"
  sha256 arm:   "3c9c1be5f3d88cc00928207206a0e50db86a87e1b99aabe45f1e92283cacef84",
         intel: "e36f05bf25af6aa82d3f4cc809635c03d4599da0331a0bcd27de0cf6ab282789"

  # KDE CI 每日构建只保留最新一天（直链几天即 404，5276 已死），故镜像到
  # 本仓 Release（tag konsole-<构建号>），cask 永远指 Release
  # （workbuddy/doubao-ime 同机制）。
  # 由 updater/konsole.swift 抓取双架构 listing 交集最大构建号，下载双包、
  # 上传 Release、改写本文件；旧快照自动清理。
  # url 用 #{version} 插值，否则 audit 会因"URL 无版本"要求 sha256 :no_check。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/konsole-#{version}/konsole-master-#{version}-macos-clang-#{arch}.dmg"
  name "Konsole"
  desc "KDE terminal emulator"
  homepage "https://konsole.kde.org/"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  depends_on macos: :tahoe

  app "konsole.app"

  uninstall quit: "org.kde.konsole"
end
