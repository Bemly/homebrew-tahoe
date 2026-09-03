cask "checkra1n" do
  version "0.12.4"
  sha256 "754bb6ec4747b2e700f01307315da8c9c32c8b5816d0fe1e91d1bdfc298fe07b"

  # 直引上游：URL 路径本身就是文件 sha256（下载后天然可核对）；
  # url 用 #{version} 插值（core 同款写法），否则 audit 会因"URL 无版本"
  # 要求 sha256 :no_check（zcode 同例）。
  # core 的同名 cask 因过不了 Gatekeeper 已被 disable（2026-09-01，
  # `disable! ... because: :fails_gatekeeper_check`），core 装不上——
  # 本 tap 提供可用的安装路径（与 core 同版本同文件同 sha）。
  # 上游归档不再更新，本 cask 永不检查更新（无 updater/checkra1n.swift）。
  url "https://assets.checkra.in/downloads/macos/754bb6ec4747b2e700f01307315da8c9c32c8b5816d0fe1e91d1bdfc298fe07b/checkra1n%20beta%20#{version}.dmg"
  name "checkra1n"
  desc "Jailbreak for iPhone 5s through iPhone X, iOS 12.0 and up"
  homepage "https://checkra.in/"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  depends_on macos: :tahoe

  app "checkra1n.app"
  binary "#{appdir}/checkra1n.app/Contents/MacOS/checkra1n"

  caveats <<~EOS
    checkra1n 未经 Apple 公证，首次启动会被 Gatekeeper 拦截：
      在 /Applications 里右键 checkra1n.app → 打开 → 仍要打开，
      之后即可正常启动（`checkra1n` 命令行同样可用）。

    二进制为 Intel(x86_64) 版，Apple Silicon 需经 Rosetta 运行。

    core 的同名 cask 已被上游 disable，如装过旧版请先卸载：
      brew uninstall --cask checkra1n
  EOS
end
