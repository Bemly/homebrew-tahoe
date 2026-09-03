cask "zcode" do
  version "3.10.2"
  sha256 "4b22cbf0f9b86176e52bff20de90a411451925bb9abd5e266a66407c61ed04f0"

  # 直引上游 CDN 的 x64 dmg（core 的 zcode cask 给的是 macos-arm64 版）。
  # url 三段都随版本变化且完全规则（路径 /<ver>/ + 文件名 ZCode-<ver>-mac-x64.dmg），
  # 故用 #{version} 插值——版本升级时 url 自动跟随，audit 的
  # "Use `sha256 :no_check` when URL is unversioned" 也不会触发。
  # （对比 workbuddy / doubao-ime：url 含构建哈希无法插值，只能写死后由 watcher
  #  整条替换，那两个 cask 会保留 audit 的这条提示——属本 tap 的预期偏差。）
  # 注：dmg 内含 Applications -> /Applications 符号链接，公式的 DmgUnpackStrategy
  # 会崩（AGENTS 11.8），cask 走自己的挂载流程不受影响——这也是它做成 cask 的原因。
  url "https://cdn-zcode.z.ai/zcode/electron/releases/#{version}/macos-x64/ZCode-#{version}-mac-x64.dmg"
  name "ZCode"
  desc "AI-assisted development environment"
  homepage "https://zcode.z.ai/en/"

  auto_updates true
  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
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
