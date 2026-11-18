cask "dsh-gui" do
  # 版本来自上游 nightly feed（dsh-desk/feeds/mac-x64/nightly-mac.yml），
  # 不再用浮动直链的镜像日期；检查器与其他包一样按版本判新。
  version "0.2.1-rc.4"
  sha256 "08dcbdd520ddff62e302909c9dccc61d1b6fcdf0520cf63b2c7c5af0e15dbbfc"

  # 镜像到本仓 Release（tag dsh-gui-<ver>，资产名沿用上游版本化 dmg）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/dsh-gui-#{version}/deepseek-harness-#{version}-mac-x64.dmg"
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
