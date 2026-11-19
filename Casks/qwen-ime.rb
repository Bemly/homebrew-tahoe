cask "qwen-ime" do
  version "1.2.60.60"
  sha256 "5b8b1116f1cefb98079973c49c08068c9a5e85aa88e273be46350c5eb251dddc"

  # 镜像到本仓 Release（上游 CDN 链接带构建号与 fp token，直接引用不稳；
  # watcher 下载后上传到 qwen-ime-<ver>，URL 指 Release 资产）。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/qwen-ime-#{version}/QwenimeMac_V1.2.60.60_mac_pf8002_.zh-cn._release_.Build3290310.dmg"
  name "Qwen Input Method"
  desc "Qwen AI input method"
  homepage "https://ime.qianwen.com/"

  auto_updates true
  # 真身 QianwenIME.app 为 universal（x86_64 + arm64），满足 Intel 要求，不设 arch 门槛。
  depends_on macos: :tahoe

  # 用户级输入法目录，避免官方安装器写 /Library 并提权。
  app "QianwenIME.app", target: "~/Library/Input Methods/QianwenIME.app"

  # 上游 dmg 里是安装器（千问输入法.app），真身在其 Resources/QianwenIME.zip 内。
  # brew 7 起 cask 禁止命令式 preflight，逻辑包进 sh -c；{{staged_path}} 为 steps token。
  preflight_steps do
    run "/bin/sh",
        args: ["-c",
               "set -- {{staged_path}}/*.app/Contents/Resources/QianwenIME.zip; " \
               "unzip -qq -o \"$1\" -d {{staged_path}}"]
  end

  postflight_steps do
    # zip 解出的文件只读，先给当前用户写权限，避免升级/卸载时 brew 提权。
    set_permissions "Library/Input Methods/QianwenIME.app", "u+w", base: :home
    # 自动启用输入源（Bundle ID / Input Mode / InputSourceKind 三键），已启用则跳过。
    run "/bin/sh",
        args:           ["-c",
                         "defaults read com.apple.HIToolbox AppleEnabledInputSources 2>/dev/null | " \
                         "grep -q 'com.qianwen.inputmethod.desktopime' || " \
                         "defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add " \
                         "'<dict><key>Bundle ID</key><string>com.qianwen.inputmethod.desktopime</string>" \
                         "<key>Input Mode</key><string>com.qianwen.inputmethod.desktopime.pinyin</string>" \
                         "<key>InputSourceKind</key><string>Input Mode</string></dict>'"],
        writable_paths: ["Library/Preferences"],
        writable_base:  :home,
        must_succeed:   false
    terminate_process "cfprefsd"
    terminate_process "TextInputMenuAgent"
    terminate_process "SystemUIServer"
  end

  uninstall quit:   "com.qianwen.inputmethod.desktopime",
            delete: "~/Library/Input Methods/QianwenIME.app"

  caveats <<~EOS
    输入法已自动安装到用户级目录并写入系统输入源，安装全程无需密码
    （卸载/升级时 Homebrew 删除 app 仍可能要求密码，这是 brew 的既有行为）。

    安装后稍等几秒，菜单栏输入法菜单里即可选择"千问拼音"；
    若未出现，注销并重新登录一次即可生效。
  EOS
end
