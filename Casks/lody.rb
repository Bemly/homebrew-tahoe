cask "lody" do
  version "0.112.0"
  sha256 "3cf968cadd19d3dea36e38cddd084c37a98864547ac33236366fc92b568fe6de"

  # 镜像到本仓 Release（tag lody-<ver>，资产名沿用上游 basename）：
  # 本 tap 政策是所有 cask 都镜像最新版；url 用 #{version} 双插值（tag 与资产名
  # 都带版本），否则 audit 会因"URL 无版本"要求 sha256 :no_check。
  # 上游按架构分包，core cask 默认 URL 是 arm64；本 tap 只取 Intel x64 dmg。
  # 版本更新由 updater/lody.swift 跟 core cask 版本（brewCask 流），有更新时
  # 下载、上传 Release、改写本文件。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/lody-#{version}/Lody-#{version}-x64.dmg"
  name "Lody"
  desc "Share coding agent sessions across desktop and mobile"
  homepage "https://lody.ai/"

  auto_updates true
  # Intel-only：主二进制为 thin x86_64，包内 Sparkle 框架为 universal。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "Lody.app"

  zap trash: [
    "~/.lody",
    "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/ai.lody.desktop.sfl*",
    "~/Library/Application Support/Lody",
    "~/Library/Caches/ai.lody.desktop",
    "~/Library/HTTPStorages/ai.lody.desktop",
    "~/Library/Preferences/ai.lody.desktop.plist",
    "~/Library/Preferences/lody-desktop-nodejs",
  ]
end
