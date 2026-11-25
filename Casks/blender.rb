cask "blender" do
  version "5.3.0-beta"
  sha256 "b96c2b69c370c2d49d50f28d62852fb881fcd580904b36fb42a8290cc5152dc8"

  url "https://github.com/Bemly/homebrew-tahoe/releases/download/blender-5.3.0-beta/Blender-5.3.0-Beta-macOS-x86_64-AMD.dmg"
  name "Blender Beta"
  desc "3D creation suite, unofficial beta Intel community build"
  homepage "https://github.com/jaguarus83/blender-5x-intel-mac-builds"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "Blender.app"

  uninstall quit: "org.blenderfoundation.blender"

  caveats <<~EOS
    这是社区制作的 Beta 构建，不是 Blender 官方 Intel 版本。
    上游包未签名，首次启动会被 Gatekeeper 拦截：
      在 /Applications 里右键 Blender.app → 打开 → 仍要打开，
      之后即可正常启动。

    与 core 的 blender cask 同 token、同 bundle ID；blender@lts 也会安装到
    /Applications/Blender.app。都不能共存——先备份并移除旧版，再装本 cask。
  EOS
end
