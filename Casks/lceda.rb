cask "lceda" do
  version "6.5.61"
  sha256 "53ba10cd29b8a4be1feed80dfc39338362fde65edc7bd0f4d1b4eb5f6d941b42"

  # 镜像到本仓 Release（tag lceda-<ver>，资产名沿用上游 basename）：
  # 本 tap 政策是所有 cask 都镜像最新版；url 用 #{version} 双插值（tag 与资产名
  # 都带版本），否则 audit 会因"URL 无版本"要求 sha256 :no_check。
  # 版本更新由 updater/lceda.swift 跟嘉立创下载页（customRelease 抓 Intel 行）——
  # 有更新时下载、上传 Release、改写本文件。注意：镜像流会把 url 整条换成字面
  # 版本，写回后须手动改回 #{version} 插值再提交，否则 audit 判 URL 无版本
  # （mirage-wallpaper 同例，见 AGENTS 11.26）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/lceda-#{version}/lceda-mac-x64-#{version}.zip"
  name "嘉立创EDA标准版"
  desc "Electronic design automation software (standard edition)"
  homepage "https://lceda.cn/page/download"

  # Intel-only：上游按架构分包，本包内 app 为 thin x86_64（file 实测）；
  # macos 门槛与其他 cask 一致。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 上游 zip 解包后是单顶层目录 lceda-mac-x64-<ver>/，app 在目录内
  # （brew 的 cask 解包不会自动下降进顶层目录，故 app 路径带上目录名）。
  app "lceda-mac-x64-#{version}/嘉立创EDA.app"

  uninstall quit: "cn.lceda"
end
