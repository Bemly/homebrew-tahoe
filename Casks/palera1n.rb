cask "palera1n" do
  version "3.0.0-beta.2"
  sha256 "8cfb4c843317c09c43a3fe3edeb7f03e736ff436fff4f3fb4f587d9346168881"

  # 上游 universal dmg（x86_64 + arm64 双切片，实测），一个包同时覆盖
  # Intel 与 Apple Silicon，无需 arch 分包。镜像到本仓 Release
  # （tag palera1n-<ver>，资产名沿用上游）：本 tap 政策是所有 cask 都镜像
  # 最新版（直引只做过渡）；url 用 #{version} 插值（tag 带版本），否则
  # audit 会因"URL 无版本"要求 sha256 :no_check。
  # 本 cask 锁定该版本、永不检查更新（无 updater/palera1n.swift）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/palera1n-#{version}/palera1n-macos-universal.dmg"
  name "palera1n"
  desc "Jailbreak tool for checkm8-vulnerable Apple devices"
  homepage "https://palera.in/"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  depends_on macos: :tahoe

  app "palera1n.app"

  uninstall quit: "palera1n"

  caveats <<~EOS
    palera1n 未签名，首次启动会被 Gatekeeper 拦截：
      在 /Applications 里右键 palera1n.app → 打开 → 仍要打开，
      之后即可正常启动。
  EOS
end
