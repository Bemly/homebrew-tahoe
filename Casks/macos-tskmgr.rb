cask "macos-tskmgr" do
  arch arm: "arm64", intel: "x86_64"

  version "1.1.1"
  # 上游按架构分包（两个 runtime zip，实测与文件名架构一致），cask 用 arch
  # 插值各取各的，sha256 直接按架构给（不要只为 sha256 套 on_arm/on_intel，
  # 会被 style 的 OnSystemConditionals 判违规）。镜像到本仓 Release
  # （tag macos-tskmgr-<ver>，双资产名沿用上游）：本 tap 政策是所有 cask
  # 都镜像最新版（直引只做过渡）。
  # 本 cask 锁定该版本、永不检查更新（无 updater/macos-tskmgr.swift）。
  sha256 arm:   "9b2685a09a5af5d969106574e4ac88af8e2eb5c7ffa84b17fab32a3366439d3a",
         intel: "ac52d3fea47c47e7e467fe7f7b3fe135c81daf967f62a8485ba5c91ceb21b6f5"

  url "https://github.com/Bemly/homebrew-tahoe/releases/download/macos-tskmgr-#{version}/MacOSTSKMGR-#{arch}-runtime.zip"
  name "MacOS Task Manager"
  desc "Task manager app"
  homepage "https://github.com/JOHN-decm/MacOS-TSKMGR"

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的软件。
  depends_on macos: :tahoe

  app "MacOSTSKMGR-#{arch}.app"

  # 上游 adhoc 签名已破（改包后未重签，codesign 报 invalid Info.plist），
  # 残留 quarantine 会被 Gatekeeper 判"已损坏"且右键也绕不过；
  # brew 不清 cask 产物的隔离属性，此处手动清除（包体 sha256 已校验过，
  # 完整性不依赖 Gatekeeper）。只清 quarantine，不碰其他属性。
  postflight do
    system_command "/usr/bin/xattr",
                   args:         ["-d", "-r", "com.apple.quarantine",
                                  Dir["#{appdir}/MacOSTSKMGR-*.app"].fetch(0)],
                   print_stderr: false
  end

  uninstall quit: "com.linqin.MacOSTSKMGR"

  caveats <<~EOS
    安装时已自动清除隔离属性（上游 adhoc 签名已破，不清会被判"已损坏"），
    双击即可启动；如仍被拦截，在 /Applications 里右键打开一次即可。
  EOS
end
