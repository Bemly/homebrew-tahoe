cask "antigravity" do
  # 版本形态：<宿主版本>-<宿主构建号>-cn<补丁序号>。补丁序号由
  # Widgets/antigravity-niang/build.sh 的 --revision 决定，宿主升版时回到 1；
  # 同一宿主版本重打补丁时人工提到 cn2 并同步改这里的 version/sha256。
  version "2.35.0-6394266482769920-cn1"
  sha256 "39488085bee109d2f1157a9f4ead65aa0667c946877ae2bd17707913ea6d736a"

  # 本包是「打过补丁的成品整包」，不是上游直引：官方 darwin-x64 dmg 解包后
  # 静态改写 app.asar（注入中文汉化 + 页内 Gemini 伴生挂件 + 禁用自更新）再 ad-hoc
  # 重签、重打 dmg，镜像到本仓 Release（tag antigravity-<ver>）。
  # 构建：Widgets/antigravity-niang/build.sh --upload
  # 判新：updater/antigravity.swift 动态读取官方下载页的 Intel 链接 + 本包 .sha256 sidecar。
  # url 用 #{version} 插值：手工重打补丁（cn1→cn2）时只动 version/sha256 两行。
  # 注意 watcher 真跑一次更新时，核心对「customRelease 且无 downloadURL 模板」的包
  # 按全量式**整条替换 url 行**（UpdaterCore 的 replaceURLLine 规则，见 AGENTS.md §11.3），
  # 插值会变成含版本号的字面量——版本号仍在 url 里，audit 照样过，需要插值时手工改回。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/antigravity-#{version}/Antigravity-#{version}.dmg"
  name "Google Antigravity"
  name "Antigravity 中文补丁版"
  desc "Agent orchestration platform, Chinese localization and in-page companion widget"
  homepage "https://antigravity.google/product/antigravity-2"

  # Intel-only：宿主为官方 darwin-x64 包，改写后仍 thin x86_64。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "Antigravity.app"

  # brew 解包后会主动给 app 打上 com.apple.quarantine（Cask::Quarantine），于是首次
  # 打开必弹 Gatekeeper。本包是 ad-hoc 重签（改写后原公证必然失效），右键打开虽然能
  # 绕过，但每次升级都要再来一遍，所以安装完直接清掉隔离属性。
  # 完整性由上面的 sha256 pin 保证，不依赖 Gatekeeper 的判定。
  # -s 不可省：brew 把属性递归打到了包内每个条目，framework 的 14 个**符号链接**
  # （Versions/Current、Squirrel.framework/Resources 这类）属性挂在链接自身上，
  # 只有 -d -r 会全部漏掉（实测清完仍剩 14 个），`-d -r -s` 才能归零。
  # must_succeed: false —— macOS 的 App Management 权限会拒绝改写 /Applications 里的
  # app（sudo 也不行，见 install_steps 的 set_ownership 同类检查），缺权限时只是没清掉，
  # 不该让整个安装失败。
  postflight_steps do
    run "/usr/bin/xattr",
        args:           ["-d", "-r", "-s", "com.apple.quarantine", "{{appdir}}/Antigravity.app"],
        writable_paths: ["{{appdir}}/Antigravity.app"],
        must_succeed:   false
  end

  uninstall quit: "com.google.antigravity"

  # zap 清单照抄 homebrew/core 的同名 cask（由 Homebrew 按实际残留文件维护），
  # 再加本包挂件自己的数据目录；不要精简——cask 已安装时 audit 会比对残留与清单。
  zap trash: [
    "~/.antigravity",
    "~/.gemini/antigravity",
    "~/Library/Application Support/Antigravity",
    "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.google.antigravity.sfl*",
    "~/Library/Application Support/GeminiNiangWidget",
    "~/Library/Caches/com.google.antigravity",
    "~/Library/Caches/com.google.antigravity.ShipIt",
    "~/Library/HTTPStorages/com.google.antigravity",
    "~/Library/Logs/Antigravity",
    "~/Library/Preferences/ByHost/com.google.antigravity.ShipIt.*.plist",
    "~/Library/Preferences/com.google.antigravity.plist",
    "~/Library/Saved Application State/com.google.Antigravity.savedState",
  ]

  caveats <<~EOS
    本包在官方 Intel 包上做了三处静态改写，与原版行为不同：
      1. 界面中文汉化（Silas-02/antigravity-desktop-cn 的引擎，锚点巡检 20/20 通过），
         另加本 tap 自有补充词典：Gemini→哈基米、模型元素代号→周期表中文字（氖/氩/氢…）、
         Claude→克劳德（Opus 巨著 / Sonnet 十四行诗 / Haiku 俳句）、思考档位→低/中/高；
      2. 右下角 Gemini 伴生挂件：跟随主窗、显示额度剩余与重置时间、可右键换立绘
         或导入自己的图片（数据与导入图都在
         ~/Library/Application Support/GeminiNiangWidget，额度 MCP 同读一份 status.json）；
      3. 应用内自动更新已禁用，否则 Google 的新包会覆盖掉打过补丁的 app.asar。
         版本更新一律走本 tap：brew upgrade --cask antigravity。

    签名是 ad-hoc 重签（原公证随改写失效），所以安装时本 cask 会清掉 brew 给 app 打的
    quarantine 属性，正常可直接打开。若仍被 Gatekeeper 拦（多为缺「App 管理」权限导致
    清理未生效），二选一：
      在访达里对着 Antigravity.app 右键 →「打开」确认一次；或
      xattr -d -r -s com.apple.quarantine /Applications/Antigravity.app

    core 里也有 cask "antigravity"（未打补丁的官方包），二者同名不能共存：
      先 brew uninstall --cask --force antigravity，再装本 cask。
    （若你手动把 Antigravity.app 拖进过废纸篓，brew 登记会残留成「登记在、文件没」，
      安装时报 "It seems the App source ... is not there"——同一句 --force 卸载即可清掉。）
  EOS
end
