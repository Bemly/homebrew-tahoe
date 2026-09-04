cask "heliport" do
  version "2.0.0-alpha"
  sha256 "751e09824c3bd0662287c42d9dd3568bed9f3e7cff920e3a47b5ef67a82975db"

  # 直引上游版本化 dmg（稳定），不镜像到本仓 Release（zcode 同例）；
  # url 用 #{version} 插值（tag 带 v 前缀、文件名无版本），否则 audit 会因
  # "URL 无版本"要求 sha256 :no_check。
  # 本 cask 锁定该版本、永不检查更新（无 updater/heliport.swift）。
  url "https://github.com/OpenIntelWireless/HeliPort/releases/download/v#{version}/HeliPort.dmg"
  name "HeliPort"
  desc "Wi-Fi client for Intel wireless adapters"
  homepage "https://github.com/OpenIntelWireless/HeliPort"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  # 实测包内为 x86_64 thin（Intel 无线网卡配套客户端）。
  depends_on macos: :tahoe

  app "HeliPort.app"

  uninstall quit: "com.OpenIntelWireless.HeliPort"

  caveats <<~EOS
    HeliPort 需要配合 itlwm 驱动使用（黑苹果 Intel 无线网卡），
    白苹果本机无 Intel 无线网卡时仅能打开界面、无法连接。

    应用未公证，首次启动可能被 Gatekeeper 拦截：
      在 /Applications 里右键 HeliPort.app → 打开 → 仍要打开，
      之后即可正常启动。
  EOS
end
