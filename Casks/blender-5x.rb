cask "blender-5x" do
  version "5.2.2"
  sha256 "8515b592d033c1e620e28c5c5708d35683a08f084dadcbcb7220c47303e3fe0e"

  # 镜像到本仓 Release（tag blender-5x-<ver>，资产名沿用上游 basename）：
  # 本 tap 政策是所有 cask 都镜像最新版；url 用 #{version} 双插值（tag 与资产名
  # 都带版本），否则 audit 会因"URL 无版本"要求 sha256 :no_check（文件名尾部的
  # x86_64 会让版本检测抓到 "64"，wireshark/zcode 同例）。
  # 版本更新由 updater/blender-5x.swift 跟上游 GitHub releases（UpdaterCore
  # github 流），有更新时下载、上传 Release、改写本文件（brewui 同机制）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/blender-5x-#{version}/Blender-#{version}-macOS-x86_64-AMD.dmg"
  name "Blender 5x Intel"
  desc "3D creation suite, Intel-optimized community build"
  homepage "https://github.com/jaguarus83/blender-5x-intel-mac-builds"

  # Intel-only（本 tap 首个 x86_64 门槛 cask）：包内 Blender 二进制为 thin
  # x86_64，Apple Silicon 跑不起来；macos 门槛与其他 cask 一致（Tahoe 起）。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "Blender.app"

  uninstall quit: "org.blenderfoundation.blender"

  caveats <<~EOS
    上游包未签名，首次启动会被 Gatekeeper 拦截：
      在 /Applications 里右键 Blender.app → 打开 → 仍要打开，
      之后即可正常启动。

    与 core 的 blender cask 及任何已装的 Blender.app 同名同 ID，
    不能共存——先备份并移除旧版，再装本 cask。
  EOS
end
