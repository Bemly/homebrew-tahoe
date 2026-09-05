cask "zcode" do
  arch arm: "arm64", intel: "x64"

  version "3.11.2"
  # 上游按架构分包（core 的 zcode cask 给的只是 macos-arm64 版）。
  # 镜像到本仓 Release（tag zcode-<ver>，双资产名沿用上游
  # ZCode-<ver>-mac-<arch>.dmg）：本 tap 政策是所有 cask 都镜像最新版；
  # url 三段都用 #{version}/#{arch} 双插值——版本升级时 url 自动跟随，
  # audit 的 "Use `sha256 :no_check` when URL is unversioned" 也不会触发。
  # 有更新时 updater/zcode.swift 下载双包、上传 Release、改写 sha 行
  # （url 行插值已覆盖新版本，不动）。
  # 注：dmg 内含 Applications -> /Applications 符号链接，公式的 DmgUnpackStrategy
  # 会崩（AGENTS 11.8），cask 走自己的挂载流程不受影响——这也是它做成 cask 的原因。
  sha256 arm:   "cfa43b90ec74732ee3ee1262803d775658a3c954cc4cc0a9a1bec0f9c6dcbf98",
         intel: "12cf306271a6bfb5f4100b9c735e07a22912051d27af845f98064495e41fd736"

  url "https://github.com/Bemly/homebrew-tahoe/releases/download/zcode-#{version}/ZCode-#{version}-mac-#{arch}.dmg"
  name "ZCode"
  desc "AI-assisted development environment"
  homepage "https://zcode.z.ai/en/"

  auto_updates true
  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制；
  # arm 段为 Apple Silicon 同包顺带覆盖（universal 时代前的分包形态）。
  depends_on macos: :tahoe

  app "ZCode.app"

  uninstall quit: "dev.zcode.app"

  zap trash: [
        "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/dev.zcode.app.sfl*",
        "~/Library/Application Support/ZCode",
        "~/Library/Caches/@zcodedesktop-updater",
        "~/Library/Preferences/dev.zcode.app.plist",
        "~/Library/Services/Open in ZCode.workflow",
      ],
      rmdir: "~/.zcode"
end
