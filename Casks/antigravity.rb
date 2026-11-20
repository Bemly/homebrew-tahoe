cask "antigravity" do
  # 版本形态：<宿主版本>-<宿主构建号>-cn<补丁序号>。补丁序号由
  # Widgets/antigravity-niang/build.sh 的 --revision 决定，宿主升版时回到 1；
  # 同一宿主版本重打补丁时人工提到 cn2 并同步改这里的 version/sha256。
  version "2.33.0-4731201358004224-cn1"
  sha256 "b7213237c8d0bdca57df949176a1d1272ef7f16467d84282fe2c99813d32a5ee"

  # 本包是「打过补丁的成品整包」，不是上游直引：官方 darwin-x64 dmg 解包后
  # 静态改写 app.asar（注入中文汉化 + Gemini 伴生挂件 + 禁用自更新）再 ad-hoc
  # 重签、重打 dmg，镜像到本仓 Release（tag antigravity-<ver>）。
  # 构建：Widgets/antigravity-niang/build.sh --upload
  # 判新：updater/antigravity.swift 读 core cask 版本 + 本包 .sha256 sidecar。
  # url 用 #{version} 插值：手工重打补丁（cn1→cn2）时只动 version/sha256 两行。
  # 注意 watcher 真跑一次更新时，核心对「customRelease 且无 downloadURL 模板」的包
  # 按全量式**整条替换 url 行**（UpdaterCore 的 replaceURLLine 规则，11.61 第 9 条实测），
  # 插值会变成含版本号的字面量——版本号仍在 url 里，audit 照样过，需要插值时手工改回。
  url "https://github.com/Bemly/homebrew-tahoe/releases/download/antigravity-#{version}/Antigravity-#{version}.dmg"
  name "Google Antigravity"
  name "Antigravity 中文补丁版"
  desc "Agent orchestration platform with Chinese localization and a companion overlay"
  homepage "https://antigravity.google/product/antigravity-2"

  # Intel-only：宿主为官方 darwin-x64 包，改写后仍 thin x86_64。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  app "Antigravity.app"

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
      1. 界面中文汉化（Silas-02/antigravity-desktop-cn 的引擎，锚点巡检 20/20 通过）；
      2. 右下角 Gemini 伴生挂件：跟随主窗、显示额度剩余与重置时间、可右键换立绘
         或导入自己的图片（数据与导入图都在
         ~/Library/Application Support/GeminiNiangWidget，额度 MCP 同读一份 status.json）；
      3. 应用内自动更新已禁用，否则 Google 的新包会覆盖掉打过补丁的 app.asar。
         版本更新一律走本 tap：brew upgrade --cask antigravity。

    签名是 ad-hoc 重签（原公证随改写失效），首次打开会被 Gatekeeper 拦：
    在访达里对着 Antigravity.app 右键 →「打开」确认一次即可，之后正常启动。
    本包未清 quarantine 属性，是因为签名本身有效（codesign --verify 通过），
    右键打开足以绕过。若个别系统直接判「已损坏」，可清掉隔离属性：
      xattr -dr com.apple.quarantine /Applications/Antigravity.app
    完整性由本 cask 的 sha256 保证，与 Gatekeeper 无关。

    core 里也有 cask "antigravity"（未打补丁的官方包），二者同名不能共存：
      先 brew uninstall --cask --force antigravity，再装本 cask。
    （若你手动把 Antigravity.app 拖进过废纸篓，brew 登记会残留成「登记在、文件没」，
      安装时报 "It seems the App source ... is not there"——同一句 --force 卸载即可清掉。）
  EOS
end
