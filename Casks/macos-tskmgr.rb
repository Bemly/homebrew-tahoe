cask "macos-tskmgr" do
  arch arm: "arm64", intel: "x86_64"

  version "1.1.1"
  # 上游按架构分包（两个 runtime zip，实测与文件名架构一致），cask 用 arch
  # 插值各取各的，sha256 直接按架构给（不要只为 sha256 套 on_arm/on_intel，
  # 会被 style 的 OnSystemConditionals 判违规）。直引上游版本化链接（稳定），
  # 不镜像到本仓 Release（zcode 同例）。
  # 本 cask 锁定该版本、永不检查更新（无 updater/macos-tskmgr.swift）。
  sha256 arm:   "9b2685a09a5af5d969106574e4ac88af8e2eb5c7ffa84b17fab32a3366439d3a",
         intel: "ac52d3fea47c47e7e467fe7f7b3fe135c81daf967f62a8485ba5c91ceb21b6f5"

  url "https://github.com/JOHN-decm/MacOS-TSKMGR/releases/download/#{version}/MacOSTSKMGR-#{arch}-runtime.zip"
  name "MacOS Task Manager"
  desc "Task manager app"
  homepage "https://github.com/JOHN-decm/MacOS-TSKMGR"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  depends_on macos: :tahoe

  app "MacOSTSKMGR-#{arch}.app"

  uninstall quit: "com.linqin.MacOSTSKMGR"

  caveats <<~EOS
    应用为 ad-hoc 签名，首次启动可能被 Gatekeeper 拦截：
      在 /Applications 里右键打开一次 → 仍要打开，之后即可正常启动。
  EOS
end
