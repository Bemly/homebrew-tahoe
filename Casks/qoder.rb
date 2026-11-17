cask "qoder" do
  version "0.5.13"
  sha256 "18588f8f9e61cb286ea13e4d66127b3ca0f992c484c5d1a29bf3de71461bb3c0"

  # 镜像到本仓 Release（tag qoder-<ver>，资产名沿用上游 basename）：
  # 本 tap 政策是所有 cask 都镜像最新版；url 用 #{version} 插值（版本只在 tag
  # 段，资产名 Qoder-CN-mac-x64.dmg 不带版本），否则 audit 会判 URL 无版本。
  #
  # 上游 qoder.cn 的下载页给的是「Qoder CN Installer」浮动安装器
  # （.../releases/latest/Qoder-CN-Installer-mac-x64.zip），安装器里再包着真正的
  # Qoder CN.app；本 cask 不走安装器，直接取版本化真身 DMG
  # （.../qoder-app/releases/<ver>/Qoder-CN-mac-x64.dmg，thin x86_64，公证签名）。
  # 版本更新由 updater/qoder.swift 跟 qoder.cn 更新日志（customRelease 抓最新
  # 版本锚点），有更新时下载、上传 Release、改写本文件。
  #
  # 注意：core 里的 cask "qoder" 是国际版（qoder.com，装 Qoder.app），本 tap 的
  # 同名 cask 是 Qoder CN（装 Qoder CN.app），二者共用 Caskroom/qoder，先卸一方
  # 再装另一方（同 rustup/chisel 的跨 tap 同名规则）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/qoder-#{version}/Qoder-CN-mac-x64.dmg"
  name "Qoder CN"
  desc "Agentic coding platform (China edition)"
  homepage "https://qoder.cn/"

  auto_updates true
  # Intel-only：主二进制为 thin x86_64；包内少量 arm64 预编译件为可选模块，
  # Intel 运行时用不到。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "Qoder CN.app"

  uninstall quit: "com.qodercn.app"

  caveats <<~EOS
    core 的 cask "qoder" 是国际版（装 Qoder.app），本 cask 是 Qoder CN
    （装 Qoder CN.app），二者共用 Caskroom/qoder 且不能共存：
      先 brew uninstall --cask qoder，再安装本 cask。
  EOS
end
