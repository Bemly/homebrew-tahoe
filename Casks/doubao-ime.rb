cask "doubao-ime" do
  version "1.1.1"
  sha256 "c8c0b866bc350703410798706558bedc0a6a93855b64de4df34bf04fc55b9f31"

  # 镜像到本仓 Release（上游 CDN 链接带构建号、每次部署都变，直接引用不稳；
  # 由 watcher 检测新版本后下载并上传到此，URL 即指向 Release 资产）。
  # 外层安装器文件名含构建号（DoubaoImeInstaller_v90703_release.zip），每次部署都变——
  # 文件名部分由 watcher 在每次更新时整条改写（镜像流）；tag 段用 #{version} 插值
  # 过 audit 的 unversioned 检查（AGENTS.md §11.5 同例），watcher 写回字面后需手动改回插值。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/doubao-ime-#{version}/DoubaoImeInstaller_v1010103_release.zip"
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
  # 外层目录名带构建号（v90703）每版都变，故由 shell 通配取第一个匹配。
  # Homebrew 7 起 cask 禁止命令式 preflight（Cask/InstallSteps），改声明式 steps：
  # 步骤块内只能写 DSL 调用，Ruby 逻辑一律包进 sh -c；{{staged_path}} 是 steps
  # 运行时模板 token（runner 展开，见 install_steps.rb），解包目标在 caskroom 内，
  # sandbox 默认允许写，无需 writable_paths。
  preflight_steps do
    run "/bin/sh",
        args: ["-c",
               "set -- {{staged_path}}/DoubaoImeInstaller_*.app/Contents/Resources/DoubaoIme.zip; " \
               "unzip -qq -o \"$1\" -d {{staged_path}}"]
  end

  # 自动启用输入法（免去手动去系统设置添加）：向系统输入源列表追加
  # "Input Mode" 项，与系统设置里手动添加后写入的记录同构（三键：
  # Bundle ID / Input Mode / InputSourceKind）。
  # 已启用过则跳过——幂等，升级/重装不会重复追加。
  # defaults 落盘要写 ~/Library/Preferences，run 步显式声明 writable_paths；
  # must_succeed: false 是故意的：无 GUI 会话（ssh/CI）下 cfprefsd 不可达时
  # 安装仍成功，只是输入源需手动添加一次。
  postflight_steps do
    # 让 app 可写：从 zip 解出的文件默认只读（r-xr-xr-x），brew 升级/卸载删除时
    # 会因 target.writable? 为假而走 sudo 提权（实测 reinstall 因此失败）。
    # 属主是当前用户，u+w 无需密码——之后装卸都不再需要管理员权限。
    # chmod 只改权限位不碰内容，不影响代码签名（签名基于文件内容）。
    set_permissions "Library/Input Methods/DoubaoIme.app", "u+w", base: :home
    run "/bin/sh",
        args:           ["-c",
                         "defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | " \
                         "grep -q 'com.bytedance.inputmethod.doubaoime' || " \
                         "defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add " \
                         "'<dict><key>Bundle ID</key><string>com.bytedance.inputmethod.doubaoime</string>" \
                         "<key>Input Mode</key><string>com.bytedance.inputmethod.doubaoime.pinyin</string>" \
                         "<key>InputSourceKind</key><string>Input Mode</string></dict>'"],
        writable_paths: ["Library/Preferences"],
        writable_base:  :home,
        must_succeed:   false
    # 刷新偏好与菜单栏：TextInputMenuAgent 持有登录会话启动时的输入源列表，
    # 不重启它新装的输入法就不出现在菜单栏（只 kill SystemUIServer 无效，实测）。
    # 若仍不出现，注销重新登录一次即可。
    # terminate_process 默认 must_succeed: false，进程不在时不报错。
    terminate_process "cfprefsd"
    terminate_process "TextInputMenuAgent"
    terminate_process "SystemUIServer"
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
