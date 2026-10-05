cask "afm" do
  version "2026.09.15"
  sha256 "1e3f4c84cff735cf5479a9ddd13b6282ce4b300a68a698bc67b1ae4ed073692a"

  # 镜像到本仓 Release（tag afm-<ver>，资产 afm-<ver>.zip，内含 AFM拼音.app 单顶层目录）：
  # 本 tap 政策是所有 cask 都镜像最新版（直引只做过渡）；url 用 #{version}
  # 插值（tag 与资产名双覆盖），否则 audit 会因"URL 无版本"要求 sha256 :no_check。
  # 本 cask 锁定该版本、永不检查更新（无 updater/afm.swift，watcher 告警跳过）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/afm-#{version}/afm-#{version}.zip"
  name "AFM Pinyin"
  desc "Pinyin input method"
  # 上游无公开主页，填分发仓库（cask homepage 必填）。
  homepage "https://github.com/Bemly/homebrew-tahoe"

  # 本 tap 首个 arm64-only 例外（其余软件均为 Intel 门槛）：
  # AFM 两个二进制（AFMInput/AFMSettings）皆 thin arm64，Intel 机跑不起来，
  # 故只限 Apple Silicon；macos 门槛与其他 cask 一致（Tahoe 起）。
  depends_on arch: :arm64
  depends_on macos: :tahoe

  # 用户级输入法目录（doubao-ime 同款）：
  # 真移动而非 symlink；无需 sudo，安装全程零手动。
  # target 以 ~ 开头时 brew 会 expand_path 展开为家目录绝对路径，
  # 父目录不存在时由 brew 自动创建（cask/artifact/moved.rb 实读确认）。
  # 中文名直写：实测 brew 的 unzip 解包保留 NFC 字节，与此处字面逐字节一致。
  app "AFM拼音.app", target: "~/Library/Input Methods/AFM拼音.app"

  # 自动启用输入法（免去手动去系统设置添加）+ 刷新菜单栏。
  # Homebrew 7 起 cask 禁止命令式 postflight（Cask/InstallSteps），改声明式 steps：
  # defaults 的 -array-add 非幂等、无 DSL 直写手段，故包一层 sh -c 做"先读后写"
  # （判重保证幂等，升级/重装不重复追加；写入记录与系统设置手动添加同构，
  # 取值自 AFM拼音.app 的 Info.plist）。run 步跑在 cask sandbox 里，
  # defaults 落盘要写 ~/Library/Preferences，故显式声明 writable_paths；
  # must_succeed: false 是故意的：无 GUI 会话（ssh/CI）下 cfprefsd 不可达时
  # 安装仍成功，只是输入源需手动添加一次。
  postflight_steps do
    # 让 app 可写：从 zip 解出的文件默认只读，brew 升级/卸载删除只读 target
    # 会走 sudo 提权（doubao-ime 实测）；属主是当前用户，u+w 无需密码。
    # 只改权限位不碰内容，不影响代码签名（签名基于文件内容）。
    set_permissions "Library/Input Methods/AFM拼音.app", "u+w", base: :home
    run "/bin/sh",
        args:           ["-c",
                         "defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | " \
                         "grep -q 'moe.bemly.inputmethod.AfmIME' || " \
                         "defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add " \
                         "'<dict><key>Bundle ID</key><string>moe.bemly.inputmethod.AfmIME</string>" \
                         "<key>Input Mode</key><string>moe.bemly.inputmethod.AfmIME.afmpinyin.hans</string>" \
                         "<key>InputSourceKind</key><string>Input Mode</string></dict>'"],
        writable_paths: ["Library/Preferences"],
        writable_base:  :home,
        must_succeed:   false
    # 刷新偏好与菜单栏：TextInputMenuAgent 持有登录会话启动时的输入源列表，
    # 不重启它新装的输入法就不出现在菜单栏（doubao-ime 实测）；
    # terminate_process 默认 must_succeed: false，进程不在时不报错。
    terminate_process "cfprefsd"
    terminate_process "TextInputMenuAgent"
    terminate_process "SystemUIServer"
  end

  uninstall quit:   [
              "moe.bemly.AFMSettings",
              "moe.bemly.inputmethod.AfmIME",
            ],
            delete: "~/Library/Input Methods/AFM拼音.app"

  caveats <<~EOS
    输入法已自动安装到用户级目录并写入系统输入源，安装全程无需密码
    （卸载/升级时 Homebrew 删除 app 仍会要求密码，这是 brew 的既有行为）。

    安装后稍等几秒，菜单栏输入法菜单里即可选择"AFM拼音"；
    若未出现，注销并重新登录一次即可生效。

    本 cask 仅支持 Apple Silicon（arm64），Intel Mac 会直接拒绝安装；
    锁定当前版本，永不自动检查更新。
  EOS
end
