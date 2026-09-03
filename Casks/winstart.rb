cask "winstart" do
  version "0.13.6"
  sha256 "9e806fa6840930f33b551200e7f6b7798d0c1ef785c0bdd4a4e96f8612794942"

  # 本地包一次性镜像到本仓 Release（上游无公开下载链接；与 workbuddy/doubao-ime
  # 同机制，但来源是本地文件而非上游直链，故由人工发版，url 指向 Release 资产；
  # url 用 #{version} 插值，否则 audit 会因"URL 无版本"要求 sha256 :no_check）。
  # Universal 包（x86_64+arm64 双切片，实测），单包覆盖双架构，无需 arch 分包。
  # 永不检查更新（无 updater/winstart.swift）。
  url "https://github.com/Bemly/homebrew-tahoe-intel/releases/download/winstart-#{version}/WinStart.#{version}.zip"
  name "WinStart"
  desc "Metro-style app launcher"
  homepage "https://space.bilibili.com/3690976784681729"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  depends_on macos: :tahoe

  app "WinStart.app"

  uninstall quit: "qixiaoyu.MyMetroLauncher"

  caveats <<~EOS
    应用为 ad-hoc 签名，首次启动可能被 Gatekeeper 拦截：
      在 /Applications 里右键 WinStart.app → 打开 → 仍要打开，
      之后即可正常启动。
  EOS
end
