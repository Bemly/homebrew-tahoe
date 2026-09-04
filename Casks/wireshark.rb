cask "wireshark" do
  version "4.4.18"
  # 上游 Intel 构建停在 4.4 系（4.6+ 无 Intel dmg，只有 arm 包），故版本不跟
  # core 公式 stable（4.6.8），而是跟官方 Sparkle appcast 里带 "Intel 64" 的
  # 那一项；sha256 直接取 appcast 同项注释里的官方值，无需下载 66MB 实算。
  # url 用 #{version} 插值，否则 audit 会因"URL 无版本"要求 sha256 :no_check。
  sha256 "84140b6014fb53da2d285482796283e583bf25b0c1d4ed7faee65f1f338a8570"

  url "https://www.wireshark.org/download/osx/all-versions/Wireshark%20#{version}%20Intel%2064.dmg"
  name "Wireshark"
  desc "Network protocol analyzer"
  homepage "https://www.wireshark.org/"

  # 本 tap 只要 Intel：上游按架构分包，Intel 64 dmg 只含 x86_64。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "Wireshark.app"
  # Phase 0 要 tshark / editcap：官方 dmg 里它们在 app 包内，随包附带。
  binary "#{appdir}/Wireshark.app/Contents/MacOS/tshark", target: "tshark"
  binary "#{appdir}/Wireshark.app/Contents/MacOS/editcap", target: "editcap"

  uninstall quit: "org.wireshark.Wireshark"
end
