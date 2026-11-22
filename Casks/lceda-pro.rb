cask "lceda-pro" do
  version "4.1.105"
  sha256 "2dd4f1880b1be25836ef980db8bc5127ad8215c438d066c86b253dbd2e23040a"

  # 镜像到本仓 Release（tag lceda-pro-<ver>，资产名沿用上游 basename）：
  # 本 tap 政策是所有 cask 都镜像最新版；url 用 #{version} 双插值（tag 与资产名
  # 都带版本），否则 audit 会因"URL 无版本"要求 sha256 :no_check。
  # 版本更新由 updater/lceda-pro.swift 跟嘉立创下载页（customRelease 抓 Intel
  # 行）——有更新时下载、上传 Release、改写本文件。注意：镜像流会把 url 整条
  # 换成字面版本，写回后须手动改回 #{version} 插值再提交，否则 audit 判 URL
  # 无版本（mirage-wallpaper 同例，见 AGENTS.md §11.5）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/lceda-pro-4.1.105/lceda-pro-mac-x64-4.1.105.zip"
  name "嘉立创EDA专业版"
  desc "Electronic design automation software (professional edition)"
  homepage "https://lceda.cn/page/download"

  # Intel-only：上游按架构分包，本包内 app 为 thin x86_64（file 实测）；
  # macos 门槛与其他 cask 一致。上游 zip 内不是 app 而是 dmg
  # （嘉立创EDA(专业版).dmg），用 cask 原生的嵌套容器机制先解 zip 再挂载 dmg。
  depends_on arch: :x86_64
  depends_on macos: :tahoe
  container nested: "嘉立创EDA(专业版).dmg"

  app "嘉立创EDA(专业版).app"

  uninstall quit: "cn.lceda.pro"
end
