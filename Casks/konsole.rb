cask "konsole" do
  # KDE CI 的两个架构独立出包，版本号可能不同；各自维护 version/sha/url。
  # 每个架构镜像到本仓 Release（tag konsole-<该架构版本>），旧快照按架构清理。
  on_arm do
    version "5504"
    sha256 "64e07392635d3464d7789e3912292031911359a6c6f589ea0b84558f943afdd0"
    url "https://github.com/Bemly/homebrew-tahoe/releases/download/konsole-5504/konsole-master-5504-macos-clang-arm64.dmg"
  end

  on_intel do
    version "5504"
    sha256 "f0fd77ce1e1af3525fb7c00d2c89d43d6ce3dd96a9a3e33af87851667227633c"
    url "https://github.com/Bemly/homebrew-tahoe/releases/download/konsole-5504/konsole-master-5504-macos-clang-x86_64.dmg"
  end

  name "Konsole"
  desc "KDE terminal emulator"
  homepage "https://konsole.kde.org/"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  depends_on macos: :tahoe

  app "konsole.app"

  uninstall quit: "org.kde.konsole"
end
