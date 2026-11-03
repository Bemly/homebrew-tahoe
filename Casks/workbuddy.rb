cask "workbuddy" do
  version "5.9.3.42398134"
  sha256 "e093e214cb77b01d821451ee19b67b0e0b2bdb63f87dcea3aacbccb21bdfc686"

  # 镜像到本仓 Release（上游 COS 链接带构建哈希、每次部署都变，直接引用不稳；
  # 由 watcher 检测新版本后下载并上传到此，URL 即指向 Release 资产）。
  # 文件名含构建哈希（-b148bd1d），每次部署都变——故不用 #{version} 插值，
  # 而由 watcher 在每次更新时整条改写。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/workbuddy-5.9.3.42398134/WorkBuddy-darwin-x64-5.9.3.42398134-d4692421.zip"
  name "WorkBuddy"
  desc "Tencent WorkBuddy AI office workspace app"
  homepage "https://www.workbuddy.cn/"

  auto_updates true
  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # Homebrew 官方不为 Tahoe 构建 x86_64 bottle，这里直接引用上游官方发布包。
  depends_on macos: :tahoe

  app "WorkBuddy.app"
end
