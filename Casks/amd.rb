cask "amd" do
  version "2026.09.18"
  sha256 "ea31c73e95ef8cc5023eecb609d221c29187c9d4e99b7cd4ed3981d8889997ba"

  # 本地构建一次性镜像到本仓 Release（上游只有源码 tag、无 release 资产；
  # 与 workbuddy/doubao-ime 同镜像机制，但来源是本地 xcodebuild 产物而非上游
  # 直链，故由人工发版；winstart 同例）。
  # Universal 包（x86_64+arm64 双切片，实测 `lipo -archs`），单包覆盖双架构，
  # 无需 arch 分包。url 用 #{version} 插值，否则 audit 会因"URL 无版本"
  # 要求 sha256 :no_check。
  # 本 cask 锁定该版本、永不检查更新（无 updater/amd.swift）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/amd-#{version}/amd-#{version}.zip"
  name "AMD-Pastis-Bartender"
  desc "Lyrics downloader with Chinese translations"
  homepage "https://github.com/Bemly/AMD-Pastis-Bartender"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件；双架构故无 arch 门槛。
  depends_on macos: :tahoe

  app "AMD-Pastis-Bartender.app"
  # 同构 CLI（上游 AMD Cli scheme 产物，随包附带；wireshark 的 tshark 同例）。
  binary "obcli"

  uninstall quit: "amd.bemly.moe"

  caveats <<~EOS
    应用为 ad-hoc 签名，首次启动可能被 Gatekeeper 拦截：
      在 /Applications 里右键 AMD-Pastis-Bartender.app → 打开 → 仍要打开，
      之后即可正常启动。

    附带命令行工具 obcli（`obcli --help` 查看用法）。
  EOS
end
