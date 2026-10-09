cask "grok-bot" do
  version "0.68.1"
  sha256 "1caeb3f8d343666b24b32f6284eb8fd21ed185507a68326d404327d333754ca5"

  # 镜像到本仓 Release（tag grok-bot-<ver>，资产名沿用上游 basename）：
  # 本 tap 政策是所有 cask 都镜像最新版；url 用 #{version} 双插值（tag 与资产名
  # 都带版本），否则 audit 会因"URL 无版本"要求 sha256 :no_check（文件名尾部的
  # _x64 同 darwin-amd64 一样会致盲版本检测，见 11.42）。
  # 版本更新由 updater/grok-bot.swift 跟 cursor 下载页（customRelease 抓取），
  # 有更新时下载、上传 Release、改写本文件。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/grok-bot-#{version}/Grok_Bot_#{version}_x64.dmg"
  name "Grok Bot"
  desc "AI teammates you can give real work to"
  homepage "https://cursor.com/cn/download/bot"

  # Intel-only：包内主二进制为 thin x86_64；macos 门槛与其他 cask 一致。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "Grok Bot.app"

  uninstall quit: "com.anysphere.sand"
end
