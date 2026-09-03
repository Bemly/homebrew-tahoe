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

  # 用户级输入法目录（macOS 标准输入法位置之一，仅当前用户）：
  # 真移动而非 symlink；无需 sudo，安装全程零手动；app 自带的自动更新
  # 写用户目录也不再需要管理员授权（系统级 /Library 反而每次更新都要）。
  # target 以 ~ 开头时 brew 会 expand_path 展开为家目录绝对路径，
  # 父目录不存在时由 brew 自动创建（cask/artifact/moved.rb 实读确认）。
  app "DoubaoIme.app", target: "~/Library/Input Methods/DoubaoIme.app"

  # 上游发布的是外层安装器（DoubaoImeInstaller_*.app），真身是其 Resources 里的
  # DoubaoIme.zip 内的 DoubaoIme.app。官方 install.sh 硬编码 /Library/Input Methods
  # 且内部嵌套 sudo（chown root:staff），绕开不用——preflight 直接解出真身。
  # 外层目录名带构建号（v90703）每版都变，故用通配而非固定名。
  preflight do
    installer_zip = Dir["#{staged_path}/DoubaoImeInstaller_*.app/Contents/Resources/DoubaoIme.zip"].fetch(0)
    system_command "/usr/bin/unzip", args: ["-qq", "-o", installer_zip, "-d", staged_path]
  end

  # 自动启用输入法（免去手动去系统设置添加）：向系统输入源列表追加
  # "Input Mode" 项，与系统设置里手动添加后写入的记录同构（三键：
  # Bundle ID / Input Mode / InputSourceKind）。
  # 已启用过则跳过——幂等，升级/重装不会重复追加。
  postflight do
    enabled = system_command("/usr/bin/defaults",
                             args:         ["read", "com.apple.HIToolbox", "AppleEnabledInputSources"],
                             print_stderr: false, must_succeed: false).stdout
    unless enabled.include?("com.bytedance.inputmethod.doubaoime")
      ohai "启用豆包输入法（写入系统输入源）"
      system_command "/usr/bin/defaults",
                     args: ["write", "com.apple.HIToolbox", "AppleEnabledInputSources", "-array-add",
                            "<dict><key>Bundle ID</key><string>com.bytedance.inputmethod.doubaoime</string>" \
                            "<key>Input Mode</key><string>com.bytedance.inputmethod.doubaoime.pinyin</string>" \
                            "<key>InputSourceKind</key><string>Input Mode</string></dict>"]
    end
    # 刷新偏好与菜单栏：TextInputMenuAgent 持有登录会话启动时的输入源列表，
    # 不重启它新装的输入法就不出现在菜单栏（只 kill SystemUIServer 无效，实测）。
    # 若仍不出现，注销重新登录一次即可。
    # 让 app 可写：从 zip 解出的文件默认只读（r-xr-xr-x），brew 升级/卸载删除时
    # 会因 target.writable? 为假而走 sudo 提权（实测 reinstall 因此失败）。
    # 属主是当前用户，u+w 无需密码——之后装卸都不再需要管理员权限。
    # chmod 只改权限位不碰内容，不影响代码签名（签名基于文件内容）。
    system_command "/bin/chmod", args: ["-R", "u+w", "#{Dir.home}/Library/Input Methods/DoubaoIme.app"]
    system_command "/usr/bin/killall", args: ["cfprefsd"], print_stderr: false
    system_command "/usr/bin/killall", args: ["TextInputMenuAgent"], print_stderr: false
    system_command "/usr/bin/killall", args: ["SystemUIServer"], print_stderr: false
  end

  uninstall quit:   "com.bytedance.inputmethod.doubaoime",
            delete: "~/Library/Input Methods/DoubaoIme.app"

  caveats <<~EOS
    输入法已自动安装到用户级目录并写入系统输入源，安装全程无需密码
    （卸载/升级时 Homebrew 删除 app 仍会要求密码，这是 brew 的既有行为）。

    安装后稍等几秒，菜单栏输入法菜单里即可选择"豆包拼音"；
    若未出现，注销并重新登录一次即可生效。
  EOS
end
