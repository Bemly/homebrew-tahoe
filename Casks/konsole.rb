cask "konsole" do
  # KDE CI 的两个架构独立出包，版本号可能不同；各自维护 version/sha/url。
  # 每个架构镜像到本仓 Release（tag konsole-<该架构版本>），旧快照按架构清理。
  on_arm do
    version "5493"
    sha256 "503794fa163aca94971c5f4c7afc2a56ee32b0e426691db1a82ccbd25b7c9725"
    url "https://github.com/Bemly/homebrew-tahoe/releases/download/konsole-5493/konsole-master-5493-macos-clang-arm64.dmg"
  end

  on_intel do
    version "5493"
    sha256 "bdd346ee2d9bb7fe1a8da924284d760358a9d7abcf533f32f1a68ae6f6f11899"
    url "https://github.com/Bemly/homebrew-tahoe/releases/download/konsole-5493/konsole-master-5493-macos-clang-x86_64.dmg"
  end

  name "Konsole"
  desc "KDE terminal emulator"
  homepage "https://konsole.kde.org/"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  depends_on macos: :tahoe

  app "konsole.app"

  uninstall quit: "org.kde.konsole"
end
