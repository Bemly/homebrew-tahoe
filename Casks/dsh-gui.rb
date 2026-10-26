cask "dsh-gui" do
  # 版本即镜像日期（UTC）：上游是浮动直链（dsh-latest-*.dmg，无版本信号），
  # 每次检查必触发更新（updater/dsh-gui.swift 走 alwaysUpdate），日期即如实版本。
  # 首版镜像内为上游 0.2.0-rc.2。
  version "2026.10.26"
  sha256 "932c56d1c8e99f6f9b03c5c0ba71fade20c018a34029668c37522ebcf1c2a122"

  # 镜像到本仓 Release（tag dsh-gui-<ver>，资产名沿用上游）：
  # 本 tap 政策是所有 cask 都镜像最新版；url 用 #{version} 插值（版本只在 tag 段，
  # 资产名浮动无版本），否则 audit 会因"URL 无版本"要求 sha256 :no_check。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/dsh-gui-2026.10.26/dsh-latest-macos-x64.dmg"
  name "DeepSeek Harness"
  desc "DeepSeek agent harness desktop app"
  homepage "https://github.com/deepseek-ai/deepseek-harness"

  # Intel-only：包内二进制为 thin x86_64；macos 门槛与其他 cask 一致。
  # 与本 tap 的 deepseek-harness 公式（npm CLI 版）不同名、不冲突。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "DeepSeek Harness.app"

  uninstall quit: "com.deepseek.dsh"
end
