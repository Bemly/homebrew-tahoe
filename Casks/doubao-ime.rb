cask "doubao-ime" do
  version "0.9.7"
  sha256 "f1a6becb37438102b8842071c1c9312c4358b59b7537d4a8109db3c95bc6e4d1"

  # 镜像到本仓 Release（上游 CDN 链接带构建号、每次部署都变，直接引用不稳；
  # 由 watcher 检测新版本后下载并上传到此，URL 即指向 Release 资产）。
  # 外层安装器文件名含构建号（DoubaoImeInstaller_v90703_release.zip），每次部署都变——
  # 故不用 #{version} 插值，而由 watcher 在每次更新时整条改写。
  url "https://github.com/Bemly/homebrew-tahoe-intel/releases/download/doubao-ime-0.9.7/DoubaoImeInstaller_v90703_release.zip"
  name "Doubao IME"
  desc "Doubao AI input method"
  homepage "https://shurufa.doubao.com/"

  auto_updates true
  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # 真身 DoubaoIme 为 universal(x86_64 + arm64)，满足 Intel 要求，故无需 arch 门槛。
  depends_on macos: :tahoe

  installer script: {
    executable: "/bin/sh",
    args:       ["-c",
                 "APP_NAME=DoubaoIme /bin/sh " \
                 "\"#{staged_path}/DoubaoImeInstaller.app/Contents/Resources/install.sh\""],
    sudo:       true,
  }

  # 上游发布的是安装器（外层 Installer.app 内包着真正的 DoubaoIme.app + install.sh）。
  # 外层目录名带构建号（DoubaoImeInstaller_v90703.app），每版都变——preflight 先改成固定名，
  # 再调 installer script 自动完成安装（sudo 写 /Library/Input Methods/，装完会弹密码框）。
  # install.sh 依赖 APP_NAME 环境变量（内层解包出 DoubaoIme.app，故传 DoubaoIme）；
  # installer script 无 env 键，只能经 /bin/sh -c 内联传入。
  preflight do
    FileUtils.mv Dir["#{staged_path}/DoubaoImeInstaller_*.app"].fetch(0),
                 "#{staged_path}/DoubaoImeInstaller.app"
  end

  uninstall quit:   "com.bytedance.inputmethod.doubaoime",
            delete: "/Library/Input Methods/DoubaoIme.app"

  caveats <<~EOS
    安装时会弹出密码框（输入法需装进系统目录 /Library/Input Methods）。

    装完后去“系统设置 → 键盘 → 文本输入 → 编辑”添加豆包输入法。
  EOS
end
