cask "github-copilot-app" do
  # 版本形态：<宿主版本>-cn<补丁序号>，与 antigravity 同约定（AGENTS 11.61 第 9 条）。
  version "1.4.3-cn1"
  sha256 "181f96b5cf0b4e8bc74b37a233b6b5d8ef66075b5d8680108d42b5c4afcd4fe8"

  # 补丁成品整包（破例同 antigravity，AGENTS 1 节）：官方 Intel dmg 复制后注入两个
  # x86_64 dylib（上游 MIT 中文插件 CopilotCN + 本仓挂件 GyWidgetCN），官方主二进制
  # 改名 github-real、github 位置换成注入启动器（算绝对路径设 DYLD_INSERT_LIBRARIES
  # 再 exec；不用 LSEnvironment，那会让子进程被 dyld SIGABRT），
  # 带 disable-library-validation entitlements ad-hoc 重签后重打 dmg 镜像本仓 Release。
  # 构建：Widgets/github-copilot-cn/build.sh（CI：patched.yml）；
  # 判新：updater/github-copilot-app.swift 读 core cask 版本 + 本 Release 的 sidecar。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/github-copilot-app-#{version}/GitHub-Copilot-#{version}.dmg"
  name "GitHub Copilot"
  name "GitHub Copilot 中文补丁版"
  desc "GitHub Copilot native client, Chinese patch and in-page companion widget"
  homepage "https://github.com/github/app"

  # Intel-only：官方 darwin-x64 包，注入 dylib 亦编为 x86_64。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "GitHub Copilot.app"

  # 清掉 brew 解包后主动打的 quarantine（ad-hoc 重签无公证，不清首启必弹 Gatekeeper）。
  # -s 不可省：符号链接自身的属性只有 -s 才清得到（antigravity 实测 14 个链接）。
  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-d", "-r", "-s", "com.apple.quarantine", "{{appdir}}/GitHub Copilot.app"],
        writable_paths: ["{{appdir}}/GitHub Copilot.app"],
        must_succeed:   false
  end

  uninstall quit: "com.github.githubapp"

  zap trash: [
    "~/Library/Application Support/com.github.githubapp",
    "~/Library/Application Support/CopilotCN",
    "~/Library/Caches/com.github.githubapp",
    "~/Library/Preferences/com.github.githubapp.plist",
    "~/Library/WebKit/com.github.githubapp",
  ]

  caveats <<~EOS
    本包在官方 Intel 包上做了运行时注入式补丁，与原版行为不同：
      1. 界面中文（shuhuNB515/githubcopilot-desktop-zh-mac，MIT；本仓编为 x86_64）；
      2. 右下角 Gemini 伴生挂件：右键换立绘 / 导入自己的图片（存 localStorage），
         数据与词典在 ~/Library/Application Support/CopilotCN；
      3. 注入靠包内启动器（Contents/MacOS/github 是启动器，官方主二进制改名为
         github-real）+ ad-hoc 重签（带 disable-library-validation entitlement），
         安装后已清隔离属性，正常免弹窗。

    应用内自动更新**未禁用**（Tauri updater 嵌在二进制里，静态禁用代价过高）：
    一旦它自更新，补丁会被官方包覆盖、界面回到英文。更新一律走本 tap：
      brew upgrade --cask bemly/tahoe/github-copilot-app
    发现变回英文就 brew reinstall --cask bemly/tahoe/github-copilot-app。

    core 里也有 cask "github-copilot-app"（未打补丁的官方 arm64 包），同名不能共存：
      先 brew uninstall --cask --force github-copilot-app，再装本 cask。
  EOS
end
