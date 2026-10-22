cask "mirage-wallpaper" do
  version "1.1.5"
  sha256 "2dd3e7ffa74644cbd73dcc032be4621db0fb8698873dd1c3ff7f5e10ddad409c"

  # 镜像到本仓 Release（tag mirage-wallpaper-<ver>，资产名沿用上游 basename）：
  # 本 tap 政策是所有 cask 都镜像最新版；上游资产名含构建号+短哈希
  # （Mirage-<build>-<hash>-macOS-x86_64.zip），版本号只在 tag 路径段，
  # 文件名本身无版本——tag 段用 #{version} 插值过 audit 的 unversioned
  # 检查（字面 tag 段新版 audit 已不认，wireshark/doubao-ime 存量漂化同例）。
  # 版本更新由 updater/mirage-wallpaper.swift 跟上游 GitHub releases
  # （customRelease：/latest 定 tag + expanded_assets 抓 Intel 资产名，
  # 不耗 GitHub API 限额，iperf3 同例），有更新时下载、上传 Release、
  # 改写本文件（整条换 url，见 UpdaterCore 镜像流；写回后 tag 段会变字面，
  # 需手动改回 #{version} 插值再提交，否则新版 audit 不过）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/mirage-wallpaper-#{version}/Mirage-523-c5fda60e16ba-macOS-x86_64.zip"
  name "Mirage"
  desc "Native live wallpaper engine, compatible with Wallpaper Engine"
  homepage "https://github.com/laobamac/MirageWallpaper"

  auto_updates true
  # 本 tap 只要 Intel：上游按架构分包，本包为 thin x86_64（file 实测），
  # 公证签名零拦截（spctl accepted）；macos 门槛与其他 cask 一致。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "Mirage.app"

  uninstall quit: "cn.laobamac.Mirage"
end
