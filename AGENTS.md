# AGENTS.md

> 本文件是 `bemly/tahoe-intel` 仓库的开发约定与执行计划。
> 任何人（或 Agent）改动本仓库前，先读完这份文档。

## 1. 项目定位

`bemly/tahoe-intel` 是一个 Homebrew 第三方 tap，只解决一件事：

**给 Intel（x86_64）Mac 上的 macOS 26（Tahoe）提供可直接安装的软件。**

### 为什么需要它

Homebrew 官方已不再为 macOS 26 构建 x86_64 的 bottle。

本机实测（2026-09-02，Homebrew 6.0.21，macOS 26.6.2，Intel x86_64）：

| 软件 | bottle 标签 | 是否有 Intel(x86_64) macOS 瓶 |
| --- | --- | --- |
| `gh` | `arm64_tahoe` `arm64_sequoia` `arm64_sonoma` / `arm64_linux` `x86_64_linux` | 无 |
| `node` | `arm64_tahoe` `arm64_sequoia` `arm64_sonoma` / `arm64_linux` `x86_64_linux` | 无 |
| `node@24` | 上面那些 + `sonoma`(x86_64) | 仅到 macOS 14 |

也就是说：Intel Mac 装这些软件时，要么从源码编译（极慢），要么只能退回旧系统的瓶。
本 tap 的做法是**直接引用上游官方的 macOS amd64 发布包**（外部链接），绕开 bottle 缺失的问题。

### 收录范围（硬性约束）

只收录**同时满足**以下两点的软件：

1. 提供 **x86_64（amd64）macOS** 预编译产物，或可指向的外部下载链接；
2. 能在 **macOS 26（Tahoe）** 上正常安装运行。

不收录：仅 arm64 的软件、需要本地编译的软件、只支持 Linux/macOS 25 及以下的软件。

**例外——代编译模式（2026-09-03 起，qemu 为首例）**：上游**不提供** macOS 预编译
（只发源码），但软件有价值、值得收录时，可改由 **CI 在 macos-26-intel 上一次性代编译成瓶**，
用户仍走瓶安装。这类软件往往**带整棵依赖树**——**绝不能把依赖也照搬进本 tap**（同名公式
跨 tap 是 Homebrew 硬限制，对依赖同样生效），枢纽依赖留给 core、只有"卸载得掉"的叶子才自瓶。
完整规则见 6 节「qemu 代编译模式」。

## 2. 命名约定

| 项 | 值 | 说明 |
| --- | --- | --- |
| tap 名 | `bemly/tahoe-intel` | 用户使用时的名字，**不得改写** |
| 仓库名 | `bemly/homebrew-tahoe-intel` | GitHub 仓库名必须带 `homebrew-` 前缀，`brew tap bemly/tahoe-intel` 才能简写解析 |
| 公式目录 | `Formula/` | 标准 Homebrew 布局 |
| 公式全名 | `bemly/tahoe-intel/<name>` | 安装时必须写全名 |

> 仓库名里的 `homebrew-` 是 Homebrew 的强制前缀，不是给 `tahoe-intel` 加料。
> tap 名保持 `bemly/tahoe-intel` 原样。

## 3. 目录结构

```
homebrew-tahoe-intel/
├── AGENTS.md                          # 本文件：约定 + 计划
├── README.md                          # 面向用户的使用说明
├── Formula/
│   └── gh.rb                          # 公式，一个软件一个文件
├── updater/
│   ├── UpdaterCore.swift              # 检查器共享核心（版本比对 / 公式改写 / 输出协议）
│   └── gh.swift                       # 每包一个检查器入口，与 Formula/*.rb 一一同名
└── .github/
    └── workflows/
        ├── watch-updates.yml          # 手动触发的批量版本 watcher（ubuntu + Swift）
        └── bottle.yml                 # 手动触发的制瓶 + 推 GHCR（macos-26-intel）
```

## 4. 公式编写规范

每个公式必须包含：

```ruby
class Xxx < Formula
  desc    "..."                        # 一句话，≤80 字符
  homepage "..."
  # 不要写 version 行：brew 会从 URL 扫描出版本，重复声明会被 audit 判为冗余
  url     "https://.../xxx_X.Y.Z_macOS_amd64.zip"
  sha256  "..."
  license "..."

  depends_on arch: :x86_64             # 强制 Intel
  depends_on macos: :tahoe             # 强制 macOS 26+

  def pre_install;  end                # 前置检查
  def install;      end                # 安装
  def post_install; end                # 后置校验
  def caveats;      end                # 使用提示
  test do ... end                      # brew test 用例
end
```

要点：

- **`depends_on arch: :x86_64` + `depends_on macos: :tahoe` 是硬性门槛**，缺一不可。
  （已确认 `:tahoe` 是 Homebrew 6.0.21 合法符号，`MacOSVersion::SYMBOLS` 中 `tahoe => "26"`；
  `x86_64_tahoe` 也是合法 bottle 标签。）
- Intel 的 bottle 标签写作**纯系统名**（`tahoe` 而非 `x86_64_tahoe`）——
  这是 Homebrew 约定，可从 core 里 `node@24` 的 `sha256 sonoma:` 印证。
- 上游官方发布包的直链（`url`）是**制瓶的原料**；分发走 GHCR 瓶（见第 8 节）。
  **例外：Electron 桌面 app（workbuddy）**——dmg 解包撞 brew 上游 bug，且 app
  应装进 `/Applications`（Launchpad/Spotlight 才可见），故走 **cask** 而非公式。cask
  无 bottle 机制（文档核实：bottle 是公式专属，见 11.8），watcher 检测到新版本后
  把发布包上传到本仓 GitHub Release、改写 `Casks/<name>.rb`，不触发 `bottle.yml`。
- `pre_install` 做环境与资源检查；`post_install` 做架构校验与版本自检。
  **不要手动清 `com.apple.quarantine`**（原因见 11.2）。
- `bottle do ... end` 块**不要手填 sha256**：瓶块由 `bottle.yml` 制瓶后自动写回，
  手填的值与 GHCR 里的实际产物必然不一致。瓶块里的标签写纯系统名 `tahoe`。
- **桌面 app（.app 包）**：brew 公式没有 `app` DSL（那是 cask 的），用
  `prefix.install Dir["**/Foo.app"].fetch(0)` 装进 Cellar（参照 macvim），配一个
  `bin` 启动脚本；闭源软件**不声明 license**（`:cannot_redistribute` / `"Proprietary"`
  都会被 audit --strict 拒，缺省则不检查）。细节见 11.9。

## 5. Workflow 约定

**所有 workflow 一律 `workflow_dispatch`，由我手动点按钮触发。**

不允许出现：

- `schedule`（定时 cron）
- `push` / `pull_request` 自动触发

降低 GitHub 负载的具体做法（已落实）：

| 措施 | 说明 |
| --- | --- |
| 只用 `workflow_dispatch` | 不跑定时任务，Actions 分钟数趋近于 0 |
| 检查类任务用 `ubuntu-latest` | macOS runner 按 10 倍分钟数计费，查版本不需要 macOS |
| 检查器用 Swift（`updater/`） | ubuntu 镜像自带 Swift 工具链；每包一个 `<name>.swift` 与 `Formula/*.rb` 一一同名，共享逻辑在 `UpdaterCore.swift`；用 `swiftc` 编译后运行（解释器模式会静默跳过顶层代码，不能用，见 UpdaterCore 头注） |
| 制瓶任务用 `macos-26-intel` | 瓶标签由**构建机**的架构+系统决定，必须 Intel + macOS 26 才是 `x86_64_tahoe`；该 job 只在手动制瓶时跑 |
| `fetch-depth: 1` | 只拉最新提交，不全量 clone |
| 版本查询走 formulae.brew.sh | Homebrew 官方站点，**不消耗 GitHub API 限额** |
| sha256 取 `checksums.txt`（~2KB） | 避免下载 15MB 的发布包 |
| `concurrency` + `timeout-minutes` | 防重复跑、防挂死 |
| 批量制瓶只占一次 runner | `watch-updates.yml` 扫全部（唯一模式），只触发**一次** `bottle.yml`（逗号列表传参）；`bottle.yml` 在单个 `macos-26-intel` 任务里顺序出瓶，绝不逐个触发 |

### 5.1 批量模式的核心约束：一次 runner 出多个瓶

watcher 扫到 N 个软件更新时，**绝不让 watcher 逐个 `gh workflow run` 触发 N 次 `bottle.yml`**——
那会变成 N 次 macOS runner 占用（macOS 按 10 倍分钟计费，最贵）。正确做法：
watcher 把更新直接提交 `main`，再用**一个** `gh workflow run -f formula="a,b,c"`
触发 `bottle.yml`，由它在**单个** `macos-26-intel` 任务内循环为 a/b/c 出瓶。
`bottle.yml` 的 `formula` 入参支持：`gh`（单）、`gh,fastfetch`（逗号多）、`all`（遍历 `Formula/*.rb`）。

## 6. 当前收录

| 软件 | 版本 | 来源 | 状态 |
| --- | --- | --- | --- |
| `gh` | 2.99.0 | GitHub 官方发布包 `gh_2.99.0_macOS_amd64.zip`（外部链接） | 已收录 |
| `fastfetch` | 2.68.1 | GitHub 官方发布包 `fastfetch-macos-amd64.tar.gz`（外部链接，release tag 无 `v` 前缀） | 已收录 |
| `neofetch` | 7.1.0 | GitHub 归档发布包 `neofetch-7.1.0.tar.gz`（外部链接，纯 bash 脚本、已归档为最后一版）；**不走 updater 检查器**（无更新），`install` 用 `make install PREFIX`，`post_install` 不做 x86_64 文件校验 | 已收录 |
| `workbuddy` | 5.4.7.37521366 | cask——WorkBuddy 官方 zip（Electron 自动更新接口 `/v2/update` 动态获取），镜像到本仓 GitHub Release | 已收录 |
| `doubao-ime` | 0.9.7 | cask——豆包输入法安装器（官方下载接口 `/api/v1/app/download_url?platform=macos` 动态获取，去 V 取版本），镜像到本仓 GitHub Release；preflight 从安装器解出真身 app，装进用户级 `~/Library/Input Methods`（免 sudo，官方 install.sh 硬编码 /Library 且嵌套 sudo 故弃用），postflight 自动写入系统输入源启用（免手动添加，见 11.17） | 已收录 |
| `node` | 26.8.1 | Node.js 官方 `node-v<ver>-darwin-x64.tar.gz`（外部链接，release tag 无 `v` 前缀） | 已收录 |
| `node@24` | 24.20.0 | Node.js 官方 `node-v<ver>-darwin-x64.tar.gz`（外部链接） | 已收录 |
| `node@22` | 22.23.2 | Node.js 官方 `node-v<ver>-darwin-x64.tar.gz`（外部链接） | 已收录 |
| `qemu` | 11.1.1 | **代编译模式**：上游源码 `qemu-<ver>.tar.xz` 为原料，CI 在 macos-26-intel 编译全量 68 个目标出瓶；core 无任何 Intel 瓶（模式规则见下） | 已收录 |
| `capstone` | 5.0.9 | 代编译模式：qemu 专属依赖（生态扇入 8），同批代编译 | 已收录 |
| `dtc` | 1.8.1 | 代编译模式：qemu 专属依赖（扇入 1） | 已收录 |
| `libslirp` | 4.9.4 | 代编译模式：qemu 专属依赖（扇入 4） | 已收录 |
| `vde` | 2.3.3 | 代编译模式：qemu 专属依赖（扇入 2）；2016 年旧代码需 `-std=gnu17` 编译开关（见 11.13） | 已收录 |
| `opencode` | 1.18.27 | `anomalyco/homebrew-tap` 的 GoReleaser 公式，取 mac 双架构段（`opencode-darwin-x64/arm64.zip`，结构照抄源文件；Intel 走 GHCR 瓶、ARM 走直链，见 11.27）；与 core 的 npm 版同名，`depends_on "bemly/tahoe-intel/ripgrep"` 走自家源 | 已收录 |
| `sst` | 4.17.1 | `anomalyco/homebrew-tap` 的 GoReleaser 公式，只留 Intel mac 段（`sst-mac-x86_64.tar.gz`）；`sst version` 子命令取版本（不支持 `--version`） | 已收录 |
| `torpedo` | 0.0.13 | `anomalyco/homebrew-tap` 的 GoReleaser 公式，只留 Intel mac 段（`torpedo-mac-x86_64.tar.gz`，上游 `sst/torpedo`）；无任何版本命令，不做版本自检 | 已收录 |
| `ripgrep` | 15.2.0 | core 拷入 + 双门槛（代编译模式，随 qemu 链）；opencode 的依赖，先于 opencode 制瓶 | 已收录 |
| `mufetch` | 0.1.1 | GitHub release 的 `mufetch_darwin_x86_64.tar.gz`（外部直链，tar 无顶层目录，文件直接在 CWD）；brew 流模板式检查器，sha 取自 release 的 `checksums.txt`（约 2KB） | 已收录 |
| `cmd` | 1.45.0 | npm 包 `command-code` 的 tarball 直引（`npm install` 到 libexec，四入口只暴露 `cmd`）；依赖本 tap 的 node 瓶（core 的 node 在 Intel Tahoe 无瓶）；**不检查更新**（无 updater/cmd.swift，同 neofetch） | 已收录 |
| `zcode` | 3.10.2 | cask——上游 CDN 按架构分包（`arch` 双插值，`sha256 arm:/intel:` 直给）；检查器走 `brewCask` 版本 + 双架构产物分支（见 11.26） | 已收录 |
| `deepseek-harness` | 0.1.1-rc.2 | npm 包 `@deepseek-ai/dsh` 的 tarball 直引（`npm install` 到 libexec，只暴露 `dsh`，`dsh web` 起 Web UI，默认 `http://127.0.0.1:3080`）；依赖本 tap 的 node 瓶（core 的 node 在 Intel Tahoe 无瓶）；**不检查更新**（无 updater/deepseek-harness.swift，同 cmd/neofetch）；与 core 的 `dsh`（Dancer's shell）无关但共享 `bin/dsh` 链接，同时安装时以后 link 的为准 | 已收录 |
| `ffmpeg` | 9.0.1 | evermeet 静态发行版 `ffmpeg-<ver>.zip`（单 x86_64 二进制；不用 getrelease 的 7z——brew 解 7z 需 p7zip，core 无 Intel Tahoe 瓶，见 11.18）；检查器 brew 流模板式（`brewName: ffmpeg`，`checksumsURL: nil` 回退下载实算） | 已收录 |
| `ffprobe` | 9.0.1 | 同上（`ffprobe-<ver>.zip`，与本 tap ffmpeg 同版本配套）；版本判据走 brew 流的 ffmpeg stable（core 无 ffprobe 公式）；core 无同名公式 | 已收录 |
| `ffplay` | 9.0.1 | 同上（`ffplay-<ver>.zip`，与本 tap ffmpeg 同版本配套）；版本判据走 brew 流的 ffmpeg stable（core 无 ffplay 公式）；core 无同名公式 | 已收录 |
| `ffserver` | 3.4.2 | 同上（`ffserver-<ver>.zip`，上游 4.0 已移除的最后构建，2018 年二进制仍可在 Tahoe x86_64 原生运行）；**不检查更新**（无 updater/ffserver.swift） | 已收录 |
| `fish` | 4.9.0 | 官方 `fish-<ver>.app.zip` 内的 unix 树（`base/` 即 install.sh 落盘内容，只装 base/ 不装 .app 本体；universal 含 x86_64 切片，doubao-ime 同例）；检查器 brew 流模板式（`checksumsURL: nil`，上游无 SHA256SUMS，实测 404） | 已收录 |
| `docker-buildx` | 0.37.0 | 官方裸二进制 `buildx-v<ver>.darwin-amd64`（改名装进 bin；实测 darwin-amd64 尾缀不影响版本扫描，无需 version 行，见 11.19）；检查器 brew 流模板式（`checksumsURL: nil`，checksums.txt 无 darwin 条目） | 已收录 |
| `checkra1n` | 0.12.4 | cask——上游 dmg 直引（URL 路径即文件 sha256；core 同名 cask 因过不了 Gatekeeper 已被 disable，本 tap 提供可用安装路径）；附 `binary` 垫片出 `checkra1n` 命令；**不检查更新**（无 updater/checkra1n.swift） | 已收录 |
| `palera1n` | 3.0.0-beta.2 | cask——上游 universal dmg 直引（x86_64+arm64 双切片，单包覆盖双架构，无需 arch 分包；直引不镜像 Release）；**不检查更新**（无 updater/palera1n.swift） | 已收录 |
| `macos-tskmgr` | 1.1.1 | cask——上游按架构分包（`arch` 插值各取各的，`sha256 arm:/intel:` 直给；直引不镜像 Release）；**不检查更新**（无 updater/macos-tskmgr.swift） | 已收录 |
| `brewui` | 0.2.1 | cask——上游 GitHub release 的 universal zip 直引（单包双架构；直引不镜像 Release）；检查器走 UpdaterCore 新增的 `github` 流（releases/latest 跳转判新，不耗 API 限额，见 11.21） | 已收录 |
| `winstart` | 0.13.6 | cask——本地包一次性镜像到本仓 Release（`winstart-<ver>` tag，上游无公开链接，人工 `gh release create` 发版）；universal 双切片；**不检查更新**（无 updater/winstart.swift）；cask homepage 必填，取开发者 B 站主页 | 已收录 |
| `docker-compose` | 5.5.1 | 官方裸二进制 `docker-compose-darwin-x86_64`（文件名无版本、路径段可扫，无需 version 行，见 11.21）；检查器 brew 流模板式（`checksumsURL: nil`，checksums.txt 文件名带 `*` 前缀、核心精确匹配对不上） | 已收录 |
| `heliport` | 2.0.0-alpha | cask——上游 dmg 直引（url 用 `#{version}` 插值，tag 带 v 前缀而文件名无版本；包内 x86_64 thin）；**不检查更新**（无 updater/heliport.swift） | 已收录 |
| `konsole` | 5277 | cask——KDE CI 每日构建的双架构包，镜像到本仓 Release（`konsole-<构建号>`；直链只留最新一天，必须镜像）；版本即构建号，检查器走 customRelease（双 listing 交集）+ 双架构镜像分支，每月手动跑一次（不设 cron，见 11.26） | 已收录 |

### gh 发布包结构（已实测）

```
gh_2.99.0_macOS_amd64/
├── LICENSE
├── bin/gh                 # 42MB，单架构 x86_64
└── share/man/man1/*.1     # 229 个 man 页
```

共 231 个文件，zip 约 15MB。
sha256：`70c05750c75df9465bc73b994e8bc379243bb494271f1b51f54ead2e19e45471`

### fastfetch 发布包结构（已实测）

```
fastfetch-macos-amd64/
└── usr/
    ├── bin/fastfetch              # 主程序，单架构 x86_64（无独立 dylib）
    ├── bin/flashfetch             # neofetch 风格别名二进制
    ├── share/fastfetch/presets/   # 内置预设（fastfetch 从 bin 同级 ../share 读取）
    ├── share/man/man1/fastfetch.1
    ├── share/bash-completion/completions/fastfetch
    ├── share/zsh/site-functions/_fastfetch
    ├── share/fish/vendor_completions.d/fastfetch.fish
    └── share/licenses/fastfetch/LICENSE
```

tar.gz 约 2MB。注意 fastfetch 的 macOS 发布**不提供 checksums.txt**，
watcher 检查器（`updater/fastfetch.swift` 的 `checksumsURL: nil`）会回退到下载 tar.gz 后本地计算。
sha256：`1e9a6ba7474a41b3cc2bb1b923afcf40c749c25bd17dc1e62b64464e7445a534`

### workbuddy 发布包结构（已实测）

```
WorkBuddy.app/                        # Electron 桌面 app，1.07GB / 3442 文件
└── Contents/
    ├── Info.plist                    # CFBundleShortVersionString 只有三段（如 5.4.7），
    │                                 #   公式版本是四段（含构建号 .37521366）
    ├── MacOS/Electron                # 主二进制（未改名），x86_64 thin，已签名
    └── ...
```

zip 约 465MB。WorkBuddy **不在 brew core**，版本来源用它的 Electron 自动更新接口
`https://www.workbuddy.cn/v2/update?platform=workbuddy-darwin-x64`（返回 version / url / sha256hash），
由 `updater/workbuddy.swift` 走 `customRelease` 自定义流接入。三个关键实测结论：

- 接口的 `sha256hash` 是 **dmg** 的 sha，与 zip 实算**不符** → 公式原料用 zip、sha 由
  检查器在有更新时下载 zip 本地实算（约 465MB，仅更新时发生）；
- 不用 dmg 做原料：brew 6.0.21 的 `DmgUnpackStrategy` 遇到 dmg 里指向 /Applications
  的符号链接会调不存在的 `MacOS.system_dir?` 直接崩（上游 bug，见 11.8），zip 无此问题；
- 产物文件名带版本 + 构建哈希（`-b148bd1d`），每次部署都变 → URL 必须整条动态获取、
  公式改写整条替换（`rewriteFormula` 的 newURL 模式）；
- 发版走本仓 GitHub Release（`gh release create workbuddy-<ver> <zip>`，同名 tag 已存在则
  `gh release upload --clobber` 覆盖资产）。每次发新版后，检查器会用 `gh release list`
  列出该 cask 的全部 release，**除本次版本外，其余 `workbuddy-*` 旧 release 全删**——
  只保留最新版一个，避免旧资产在 Release 堆积。单个旧 release 删除失败只告警不阻断，
  不影响发版结果。

### node / node@24 / node@22 发布包结构（已实测，三版本同构）

```
node-v<ver>-darwin-x64/                  # 5866 个文件，单顶层目录（brew 会下降进入）
├── bin/
│   ├── node                             # 主二进制，x86_64
│   ├── npm  -> ../lib/node_modules/npm/bin/npm-cli.js      # 相对符号链接
│   ├── npx  -> ../lib/node_modules/npm/bin/npx-cli.js
│   └── corepack -> ../lib/node_modules/corepack/dist/corepack.js
├── include/node/...
├── lib/node_modules/
│   ├── npm/                             # 完整 npm 包树
│   └── corepack/
└── share/man/man1/node.1
```

tar.gz 约 25MB。三个都在 **homebrew/core**，版本来源走 brew 流的 `versions.stable`，
sha 取自同目录的 `SHASUMS256.txt`（官方发布清单，约 2KB）。

⚠️ **brew 版本扫描的坑**：文件名 `node-v<ver>-darwin-x64.tar.gz` 尾部的 `x64` 会让
brew 的 `Version.parse` 只抓到 `"64"`（实测 `brew info` 显示 `stable 64`），与真实版本不符。
解法：公式**显式声明 `version` 行**（audit 仅在声明值与扫描值相同时才判冗余，不同则允许）。
由此引出 `rewriteFormula` 必须同步替换 version 行，否则 url 与 version 脱节。

### qemu 代编译模式（无上游预编译 + 带依赖树软件的处理方式）

**适用条件**：上游只发源码、无任何 macOS 预编译（qemu 官方下载页 macOS 段只有
`brew install qemu`），软件有价值且构建可复现（qemu 本体编译能全绿）。

**一句话模式**：上游源码 tar.xz 做公式原料 → bottle.yml 在 macos-26-intel 现编译
（core 侧依赖 + 本体）→ GHCR 出 tahoe 瓶；**只瓶「卸载得掉」的叶子依赖**，枢纽依赖
留给 core。用户端：qemu 与叶子依赖永远走本 tap 的瓶（更新秒装）；枢纽依赖首次安装
仍由 core 源码构建（1–2 小时量级，第三方 tap 无法绕开，见下）。

**为什么不能把依赖树照搬进 tap**（qemu 初版方案的教训）：
同名公式跨 tap 是**无条件 odie**（`install/check.rb`，无 --force 可绕），且两个 tap 的
同名包**共用同一个 Cellar 目录**（`/usr/local/Cellar/<name>/`）——只要用户装过 core 的
同名包，本 tap 的包就永远判定「已装自别的 tap」。这条对**依赖**同样生效。官方 core 能把
整棵依赖树都瓶起来，只因为它是 default tap、没有第二家抢名字；第三方 tap 复制依赖树
与 core 生态**天然互斥**。

**hub/叶子分流策略**：
1. 判据用**生态扇入**（全 Homebrew 有多少公式依赖它）：`brew uses --eval-all <f>` 或
   反查 formulae.brew.sh 全量 `formula.json` 的 dependencies。**不要用本机
   `brew uses --installed`**——开发机装了一堆软件时几乎全判成 hub（本机实测 30/30）。
2. **走 core（公式写裸名依赖）**：生态枢纽包（openssl@3 519 / gettext 399 / glib 333 /
   zstd 206 / libpng 214 / gnutls 56…）。特征：多数机器已装、brew 拒绝卸载（被其它包
   依赖）、用户端无需重编。
3. **自瓶（公式写全名 `bemly/tahoe-intel/<name>`）**：主软件 qemu + qemu 专属叶子
   （capstone/dtc/libslirp/vde，扇入 1–8，除 qemu 外无人依赖）——core qemu 卸掉后
   它们就「卸载得掉」。
4. **Group A（走 core）必须在依赖上闭合**：若某包是 core 包的依赖（gnutls→nettle/
   libtasn1/p11-kit/libunistring/libidn2，glib→json-c），core 安装时必然把它拉进来，
   再瓶一份同名必撞 odie——所以判据不能只看扇入，还要看它的依赖方归属哪组。
5. **裸名 `depends_on` 永远解析到 core**：brew 6 的 `FromNameLoader` 规定「存在于
   default tap 时永不与其它 tap 视为歧义」（`formulary.rb`）——想靠「同名优先本 tap」
   是错的。凡指向本 tap 公式的依赖必须写全名，指向 core 的写裸名。

**公式落地四步（一律从拷 core 原文起步）**：上游在 homebrew/core 里的，直接拷 core 公式
原文（编译行为与官方一致，杜绝手写 install 出错）→ 摘掉 core 的 `bottle do` 块（root_url
指向 core GHCR 且无 x86_64_tahoe 标签）→ 加 `depends_on arch: :x86_64` + `macos: :tahoe`
门禁 → 依赖按上面分流改写全名/裸名。core 源码按 `ruby_source_path`（API JSON 字段）取，
**lib 前缀公式在 `Formula/lib/` 二级目录**，别猜路径。

**检查器 = brew JSON 全量流（三行配置）**：这类软件的 url 模板不好推（glib 的 `/2.88/`
目录、上游换镜像等），`UpdaterCore` 的 brew 流因此新增**全量式**：
`CheckConfig(formula: X, brewName: X)` 即可——url 与 sha256 直取 formulae.brew.sh JSON
的 `urls.stable.url` / `urls.stable.checksum`（即 core 公式 url 行指向的真实上游与
Homebrew 维护的校验和，上游换镜像自动跟随）。模板式（downloadURL 闭包）仍优先、兼容旧包。

**版本扫描的坑**：URL 带**版本目录**（glib `/glib/2.88/glib-2.88.3.tar.xz`、gnutls
`/v3.8/`、libssh `/0.12/`）时，URL 版本扫描先命中目录段（2.88 < 2.88.3）→ 恒误判
「有更新」，每次 watcher 扫描都空转触发制瓶；`.pem`（ca-certificates）这类 URL 扫不出
版本号。两者都要**显式 `version` 行**（node 家族的 x64 尾缀是同类问题，见上）。

**CI 侧注意**：单 job 平台上限 6 小时 → timeout 设 360；制瓶循环中途失败时「提交瓶块」步
仍要跑（`if: always()`，见 11.12），否则瓶已推 GHCR 但公式没 sha，后续包被判「无瓶」。

## 7. Watcher 工作原理

`watch-updates.yml`（**只有批量模式**，没有单软件模式）→ `updater/`（Swift 检查器）：

1. workflow 遍历 `Formula/*.rb`，对每个公式查找**同名**的 `updater/<name>.swift`
   （`fastfetch.rb` ↔ `fastfetch.swift` 一一对应；找不到同名 swift 则告警跳过）；
2. `swiftc` 把 `updater/UpdaterCore.swift`（共享核心）+ 该包 swift 编译成可执行文件再运行
   （解释器模式 `swift Core.swift <name>.swift` 会静默跳过顶层代码，不能用）；
3. 检查器从 `Formula/<name>.rb` 读出本地版本号（优先 `version` 行，没有则从 `url` 行解析）；
4. `GET https://formulae.brew.sh/api/formula/<name>.json` 取 `.versions.stable`
   —— **这是 brew 上的版本号，不是上游 GitHub 的最新版**，正是需要的判据；
   brew 上没有该软件（404）→ `status=brew-missing`，本轮跳过
   （版本来源需单独适配，见第 12 节待办与 UpdaterCore 内 TODO）；
5. 数字分段比较（等价 `sort -V`）：本地 == brew → 结束；本地 > brew → 结束；brew 更新 → 继续；
6. **HEAD 探测新版本资源是否可下载**；不可下载则发 `status=upstream-missing`
   并开 issue 告警，不再往下走；
7. 取新版本的 sha256：优先 `GET gh_<ver>_checksums.txt`（2KB），失败才回退下载 15MB zip；
8. 用 Swift 正则改写 `Formula/<name>.rb` 的 `url` / `sha256`（版本替换限定 url 行 +
   边界防误伤：`(?<![0-9.])旧版本(?![0-9.])`），并做改后自检；
9. **摘除失效的 `bottle do` 块**（其 sha256 属于旧版本），并发 `bottle_stale=true`；
10. workflow 对更新过的公式跑 `ruby -c` 语法自检，然后**一次性提交到 `main`**（不开 PR）；
11. 用**一次** `gh workflow run "Build bottle and publish to GHCR" -f formula="a,b,c"`
    触发 `bottle.yml`，由它在单个 `macos-26-intel` 任务里顺序为这批软件出瓶（见 9.8）。

即 N 个软件更新 = **1 次 watcher（ubuntu）+ 1 次 bottle（macos）**，共 2 次 workflow 运行，
与更新数量无关。

三道保护（批量直接进 `main`，靠它们兜底）：

- `dry_run=true`：公式就地改写但不提交、不触发制瓶，先看结果再决定；
- 提交前对每个更新过的公式跑 `ruby -c` 语法自检；
- 上游资源不可下载（`upstream-missing`）的软件不进更新清单，逐个开告警 issue。

支持输入参数：

- `dry_run`：`true` 时只检查不提交（就地改写公式，但不 commit、不触发制瓶）。

## 8. GHCR 瓶策略

### 8.1 定位

`url`（上游预构建包直链）只是**制瓶的原料**，分发走 GHCR 瓶：

- 安装走 Homebrew 原生瓶机制，不依赖 GitHub Releases；
- 上游万一改名/删档，GHCR 里还留着一份；
- **不重新编译** —— 瓶的内容就是把上游预构建包拆进 Cellar 再打包。

### 8.2 地址

```ruby
bottle do
  root_url "https://ghcr.io/v2/bemly/tahoe-intel"
  sha256 cellar: :any_skip_relocation, tahoe: "<由 bottle.yml 生成>"
end
```

依据（源码 `Homebrew::GitHubPackages.root_url`）：

```ruby
root_url(org, repo) = "https://ghcr.io/v2/#{org}/#{repo.delete_prefix("homebrew-")}"
```

所以 `bemly/homebrew-tahoe-intel` → **去掉 `homebrew-` 前缀** → `ghcr.io/v2/bemly/tahoe-intel`
（与核心的 `ghcr.io/v2/homebrew/core` 同构）。

### 8.3 构建环境：必须是 macos-26-intel

瓶标签由**构建机**的架构与系统决定，写不进公式。要产出 `x86_64_tahoe`
就必须 Intel + macOS 26；GitHub 托管 runner 里对应 **`macos-26-intel`**
（该镜像确为 Intel：Java 路径带 `_X64`、Homebrew 前缀是 `/usr/local`、
驱动是 `chromedriver-mac-x64`）。

常见误区：`macos-14/15/26` 默认是 arm64，制出来是 `arm64_*`；
`macos-13` 虽是 Intel 但系统是 Ventura，制出来是 `ventura` 而非 `tahoe`。

### 8.4 生命周期

| 场景 | 处理 |
| --- | --- |
| 包有新版本，或 GHCR 里还没有瓶 | 手动触发 `bottle.yml`：制瓶 → 覆盖 GHCR 上的旧瓶 → 清理老版本标签 → 瓶块提交回公式 |
| 下次 gh 又更新 | `watch-updates.yml` 先摘掉失效瓶块并开 issue；再跑一次 `bottle.yml` 覆盖 GHCR |
| 无更新 | 保持走 GHCR 瓶下载 |
| 上游资源取不到 | `watch-updates.yml` 开 issue 告警，不动公式 |

### 8.5 关键实现细节

- **Taps 目录必须软链**。`brew tap` 默认是 clone，`brew bottle --merge --write`
  会改到克隆副本上导致提交丢失。`bottle.yml` 里用
  `ln -sfn "$GITHUB_WORKSPACE" <Taps>/bemly/homebrew-tahoe-intel`。
- **推 GHCR 用 `brew pr-upload`**：读 CWD 下的 `*.bottle.json`，跑
  `brew bottle --merge --write`（把瓶块写回公式）再上传。需要
  `HOMEBREW_GITHUB_PACKAGES_USER` / `HOMEBREW_GITHUB_PACKAGES_TOKEN` 与 `skopeo`；
  workflow 里用 `secrets.GITHUB_TOKEN` + `permissions: packages: write`。
- **GHCR 包默认私有**，匿名 `brew install` 会 401。`bottle.yml` 里尝试用 API 改成公开，
  失败不阻断；兜底是仓库 Settings → Packages 手动改公开。
- **制瓶版本号取 `brew list --versions`**（brew 的实际安装结果），不从公式文本里 grep 数字——
  版本号段数不同（`3.0` / `1.2.3.4`）或注释里先出现数字都会导致误判。
- **`bottle.yml` 的并发组是全局 `bottle`**，不按入参分组：不同入参的两次制瓶若并行，
  会同时 `git push main`、删/推 GHCR 标签而互相冲突，排队串行执行。
- **推送前「删整个包」再由 pr-upload 重建**：`bottle.yml` 在 `pr-upload` **之前**
  检查该包在 GHCR 上有无带标签版本；有则整包删除
  （`DELETE users/{owner}/packages/container/tahoe-intel%2F<name>`），让
  `pr-upload` 重新建包推送。这一步同时达成两个目的：清掉历史老瓶，以及让
  同版本可以重复推送（`pr-upload` 撞已存在标签会直接 `odie "already exists!"`，
  所以必须先删再传，见 11.10）。**不能逐个删版本**：GitHub 禁止删除包的
  「最后一个带标签版本」。新建的包默认私有，由后续「设为公开」步骤兜底
  （实测重建后的包会继承公开状态，匿名拉取正常）。
  GitHub Packages 页面上显示的 `sha256:...` 无标签行是 image index 引用的
  子清单（瓶的真正内容），**不是孤儿，不要手删**；标签删掉后 GitHub 会自行
  回收不再被引用的清单。
- 制瓶产物（`*.bottle.json` / `*.bottle.tar.gz`）已进 `.gitignore`，不要提交。

## 9. 新增软件的 SOP（端到端 Runbook）

目标：把一个新软件做成「用户 `brew install bemly/tahoe-intel/<name>` 时直接命中 GHCR 瓶」的状态。
下面每一步都是必做项，**顺序不能跳**——之后每个软件都按这套走。

### 9.1 调研上游（确定原料）

1. 确认上游有 **macOS amd64** 预编译产物，且能在 macOS 26 跑。
   优先找 GitHub Releases 的 `*-macOS-amd64*` / `*-macos-amd64*` 资产。
   **若上游没有 macOS 预编译（只发源码）** → 改走 6 节「qemu 代编译模式」：
   判断、hub/叶子分流、检查器写法（JSON 全量流）、CI 超时都与本节直引预编译包的流程不同。
2. 确定版本号来源（二选一）：
   - **brew 流**：在 core 里的软件，看 `https://formulae.brew.sh/api/formula/<name>.json` 的 `.versions.stable`；
   - **自定义流**：brew 未收录的软件（如 workbuddy），若上游有自有更新接口（Electron app
     的自动更新接口最稳），返回值里的 version/直链/sha 可一次拿全——接入方式见 9.3。
3. 下载该产物，**本地实测**算出 sha256，并 `tar -tzf` / `unzip -l` 看解压后目录结构
   （顶层目录名、bin 位置、是否需要拆层级，见 11.1）。

### 9.2 写公式

4. 照第 4 节模板写 `Formula/<name>.rb`，类名 CamelCase。
   `url` 用上游直链（制瓶原料）；`sha256` 用 9.1 实测值；
   必须带 `depends_on arch: :x86_64` + `depends_on macos: :tahoe`。
   **不要手填 `bottle do` 块**（由 bottle.yml 制瓶后自动写回，见 8.5）。

### 9.3 登记到 watcher（updater/）

5. 新建 `updater/<name>.swift`（与 `Formula/<name>.rb` 同名，一一对应），四种写法：
   - **brew 流**（软件在 homebrew/core）：照抄 `gh.swift` 的 `@main` 结构，改 4 处配置——
     `formula` / `brewName`、`asset`、`downloadURL`、`checksumsURL`
     （上游无 checksums 文件则置 `nil`，核心自动回退下载计算）；
   - **brew 流-全量式**（qemu 链 / ripgrep 这类从 core 拷入、url 模板不好推的公式）：
     只需 `CheckConfig(formula: "<name>", brewName: "<name>")`，url 与 sha256 由核心直取
     JSON 的 `urls.stable.url` / `.checksum`，上游换镜像自动跟随（见 6 节「qemu 代编译
     模式」；模板式仍优先）；
   - **raw 流**（软件来自其他 tap 仓库，如 `anomalyco/homebrew-tap` 的三包）：
     照抄 `opencode.swift`，只配 `formula` + `rawFormulaURL`（源公式 raw 地址），
     核心按 GoReleaser 结构解析 version + Intel mac 的 url/sha256；
     要双架构（opencode 取 mac 双段）再加 `rawDualArch: true`，核心解析双块、
     改写公式内双 `if Hardware::CPU` 块（见 11.27）；
   - **自定义流**（brew 未收录）：照抄 `workbuddy.swift`，实现 `customRelease` 闭包调
     上游自有更新接口，返回 `UpstreamRelease(version:downloadURL:sha256:)`
     （sha 仅在实测确认归属时才给，否则置 nil 由核心下载实算）。
   - **双架构产物**（上游按架构分包的 cask，如 zcode / konsole）：在版本来源
     （brewCask / customRelease 任选其一）之外再配 `archArtifacts: [token]` +
     `downloadURLForArch: (version, arch) -> url`，核心走双分支（逐个探测下载、
     各算各的 sha，改写 version + `sha256 arm:/intel:` 行；url 行不动）。
     要镜像到本仓 Release（konsole 这类直链几天即坏的）再加 `uploadRelease: true`
     （tag `<name>-<ver>`、资产名沿用上游 basename、旧快照自动清理）。
     token→key 由核心 `caskArchKey` 显式映射，未知 token 直接 fail。
   ⚠️ **公式与 swift 文件没有 push 进远端之前，CI checkout 拿不到它们**（见 11.7）。

### 9.4 本地验证

7. 本地验证（见第 10 节）：`brew style` / `audit --strict` / `fetch` / `install` / `test` 全过。
   此时装的是上游直链版（还没有 GHCR 瓶），属正常现象。

### 9.5 提交并推到远端

8. 把 9.2–9.3 的全部改动 `git add` + `commit` + `git push origin main`。
   **不提交就无法在下一步用 `gh` 触发带新软件名的制瓶**（选项只认远端版本）。

### 9.6 手动制瓶（触发 bottle.yml）

9. 用本机已登录的 `gh`（需 `workflow` 权限）触发：

   ```bash
   gh workflow run "Build bottle and publish to GHCR" \
     --repo bemly/homebrew-tahoe-intel \
     -f formula=<name>
   ```

   `formula` 入参支持：`gh`（单）、`gh,fastfetch`（逗号多，一次出多个瓶）、`all`（遍历全部）。
   多软件场景优先用逗号列表或 `all`，只占一次 macOS runner（见 5.1）。

10. **阻塞等到跑完**（必须看到 `✓ Complete job` 再继续）：

    ```bash
    RUN_ID=$(gh run list --repo bemly/homebrew-tahoe-intel --limit 1 \
              --json databaseId --jq '.[0].databaseId')
    gh run watch "$RUN_ID" --repo bemly/homebrew-tahoe-intel
    ```

    注意：

    - repository 名是 `bemly/homebrew-tahoe-intel`（带 `homebrew-` 前缀），不是 tap 名 `bemly/tahoe-intel`；
    - 该 workflow 会依次：软链并信任 tap → build-bottle 安装 → 制瓶 → 删旧 GHCR 标签（支持重复运行覆盖）
      → 推 GHCR → 尝试设公开 → **把瓶块 commit 回公式**。

### 9.7 让本机也换成 GHCR 瓶版（而不是直链）

11. 制瓶完成后，远端公式已带 `bottle do` 块。本机先把这次提交拉下来，再重装，让它走 GHCR 瓶：

    ```bash
    git pull --ff-only origin main
    brew reinstall bemly/tahoe-intel/<name>
    ```

    成功标志：日志出现
    `Downloading https://ghcr.io/v2/bemly/tahoe-intel/<name>/manifests/<ver>`
    与 `Pouring <name>--<ver>.tahoe.bottle.tar.gz`。

12. 校验：`brew info bemly/tahoe-intel/<name>` 显示 `stable <ver> (bottled)`，
    且 `<name> --version` 版本正确、`file -b $(which <name>)` 为 `Mach-O 64-bit executable x86_64`。

### 9.8 批量更新（watcher 的唯一模式）

适合「多个软件同时发版」或「想一键把整个 tap 的瓶刷新一遍」：

1. 手动跑 `watch-updates.yml`。想先看结果再决定，勾 `dry_run=true`：
   只就地改写公式，不提交、不触发制瓶。
2. watcher 在 `ubuntu-latest` 上遍历 `Formula/*.rb`（Swift 检查器逐包查 brew 版本）；
   有更新的就地改写 `url`+`sha256`、摘除旧 `bottle do` 块，然后**一次性提交到 `main`**。
3. watcher 紧接着触发**一次** `bottle.yml`，`formula` 传逗号列表（如 `gh,fastfetch`）；
   `bottle.yml` 在**单个** `macos-26-intel` 任务里顺序为这批软件出瓶、覆盖 GHCR、写回瓶块。
4. 校验同 9.7 第 12 步（逐个 `brew info` 看 `(bottled)`）。

也可以只提交更新、不自动制瓶：`dry_run=true` 看完结果后手动跑一次
`bottle.yml -f all`（或 `-f "gh,fastfetch"`）出瓶。
**关键点**：无论几个软件，制瓶只发生在一个 `macos-26-intel` 任务内，不会变成 N 次 runner。

## 10. 本地验证

本机（Intel x86_64 + macOS 26.6.2）就是最合适的验证环境：

```bash
# 用本地目录做 tap，避免走网络
brew tap bemly/tahoe-intel /Users/bemly/Projects/tahoe-intel

brew info      bemly/tahoe-intel/gh      # 看解析结果
brew style     bemly/tahoe-intel/gh      # RuboCop 规范
brew audit --strict bemly/tahoe-intel/gh # 公式审计
brew fetch     bemly/tahoe-intel/gh      # 验证 url + sha256 可下载且一致
brew install   bemly/tahoe-intel/gh      # 真装一遍，验证 pre/post 脚本
brew test      bemly/tahoe-intel/gh      # 跑 test do
```

手动跑一遍某软件的检查器（本地无 `GITHUB_OUTPUT` 时结果直接打在 stdout）：

```bash
swiftc updater/UpdaterCore.swift updater/gh.swift -o /tmp/check-gh && /tmp/check-gh
```

## 11. 踩坑记录（本机实测，改代码前务必先看）

### 11.1 解压目录不要加前缀

brew 解压 zip 后**会自动下降进入其中唯一的顶层目录**。实测 `install` 执行时
CWD 已经是 `gh_<version>_macOS_amd64/`：

```
DEBUG pwd=/private/tmp/gh-XXXX/gh_2.99.0_macOS_amd64
DEBUG top=["LICENSE", "bin", ".brew_home", "share"]
```

所以 `bin.install "gh_2.99.0_macOS_amd64/bin/gh"` 会报
`Errno::ENOENT: No such file or directory - gh_2.99.0_macOS_amd64/bin/gh`。

**正确写法**：用 `Dir["**/bin/gh"]` 通配，brew 下降与否都能命中。

### 11.2 别手动清隔离属性

brew 在下载阶段已清掉 `com.apple.quarantine`（装完 `xattr -l` 为空）。
而且 `bin.install` 出来的文件是 `0555`，手动 `xattr -d` 必然
`xattr: [Errno 13] Permission denied`。这一步是多余的，不要加。

### 11.3 不要显式声明 version

`version "2.99.0"` 与 URL 扫描出的版本相同时，audit 报
`redundant with version scanned from URL`。让 brew 从 URL 扫描即可；
watcher 脚本相应地也从 url 行解析版本号（`version` 行读不到就回退）。
**例外（URL 扫不出或扫错版本才显式声明）**：node 家族的 `darwin-x64.tar.gz` 尾缀会扫成
`"64"`；URL 带版本目录（glib `/glib/2.88/`、gnutls `/v3.8/`、libssh `/0.12/`）会扫成
目录段；`.pem`（ca-certificates）扫不出——详见 6 节对应段落。

### 11.4 同名公式跨 tap 不能共存

brew 会直接拒绝安装：

```
Error: gh was installed from the homebrew/core tap
but you are trying to install it from the bemly/tahoe-intel tap.
Formulae with the same name from different taps cannot be installed at the same time.
```

用户必须先 `brew uninstall gh`（core 版），才能装本 tap 的版本。

### 11.5 本地开发：tap 目录要用软链接

`brew tap bemly/tahoe-intel <本地路径>` 是 **clone，不是 symlink**，
改了本地文件 brew 读不到，会一直报旧错误。开发时换成软链接：

```bash
rm -rf /usr/local/Homebrew/Library/Taps/bemly/homebrew-tahoe-intel
ln -s /Users/bemly/Projects/tahoe-intel /usr/local/Homebrew/Library/Taps/bemly/homebrew-tahoe-intel
```

### 11.6 验证结果（2026-09-02，Intel x86_64 / macOS 26.6.2）

| 检查项 | 结果 |
| --- | --- |
| `brew style` | 无告警 |
| `brew audit --strict` | 无问题 |
| `brew install` | 234 files / 43.0MB，post_install 架构校验通过 |
| `brew test` | 版本 + x86_64 两条断言均通过 |
| `gh --version` | 2.99.0 |
| `file -b $(which gh)` | `Mach-O 64-bit executable x86_64` |
| watcher（已是最新） | `status=up-to-date` |
| watcher（模拟 2.98.0→2.99.0） | 正确改写 url 与 sha256，sha 取自 2KB 的 checksums.txt |

### 11.7 制瓶的两道必经关（每加一个软件都会踩）

1. **必须先 `git push` 再触发 `bottle.yml`。**
   CI 的 checkout 只看远端：新软件的公式（`Formula/<name>.rb`）和检查器
   （`updater/<name>.swift`）没 push 就触发制瓶，runner 上根本没有这些文件。
   → SOP 9.5（提交并推送）必须在 9.6（触发制瓶）之前完成。
2. **制瓶后本机要 `git pull` + `brew reinstall` 才换上 GHCR 瓶。**
   `bottle.yml` 在 CI 里把瓶块 commit 回公式并 push；本机不 pull 就读不到瓶块，
   重装时仍会回退到上游直链。`git pull --ff-only` 后 `brew reinstall` 的日志
   必须出现 `ghcr.io/v2/bemly/tahoe-intel/<name>/manifests/...`
   与 `Pouring <name>--<ver>.tahoe.bottle.tar.gz` 才算真正换瓶成功。
3. 触发用 `gh workflow run ... --repo bemly/homebrew-tahoe-intel`
   （带 `homebrew-` 前缀的**仓库名**），不是 tap 名 `bemly/tahoe-intel`。

### 11.8 WorkBuddy：dmg 做原料会撞 brew 上游 bug，用 zip

（2026-09-03 实测，Homebrew 6.0.21）Electron app 的官方 dmg 里通常有指向
`/Applications` 的符号链接，`brew install` 解包时走 `DmgUnpackStrategy`，
它会调 `MacOS.system_dir?` —— **这个方法在该版本根本不存在**，直接
`NoMethodError` 崩掉（上游 bug，本机与 CI 只要 brew 版本相同都会踩）。

结论：凡是「zip/dmg 双格式」的上游，公式一律取 **zip**（zip 解包不经过该路径）。
WorkBuddy 的接口 `sha256hash` 恰好是 dmg 的 sha（与 zip 实算不符），所以检查器
把 `UpstreamRelease.sha256` 置 nil，有更新时下载 zip 本地实算。若上游只有 dmg，
得等 brew 修复后再收，或考虑 cask。

### 11.9 桌面 app 公式的坑（以 WorkBuddy 为例）

> ⚠️ **现状（2026-09-03）**：workbuddy 已改为 **cask**（commit e223316），本节 1–5 条
> 都是「公式时代」的实测记录。cask 路线不经过 build-bottle、不走公式 audit
> （`audit_exceptions/` 目录也已随公式一并移除，且该机制本就是公式专属，
> cask audit 不认它），所以这些坑在 cask 路线**不会触发**。保留在此，是因为
> 若未来某个桌面 app 以公式形式收录，这些坑会原样重现。

1. **zip 顶层垃圾被过滤后仍会下降**。zip 里有 `WorkBuddy.app/` + `__MACOSX/` 两个顶层
   目录，看似不会触发 11.1 的「自动下降」，但 brew 解包时先把 `__MACOSX` 当垃圾过滤掉，
   只剩唯一顶层目录 → **照样下降进 app 内部**，CWD 就是 app 根，`Dir["**/WorkBuddy.app"]`
   扑空报 `IndexError`。install 要写双分支：`Contents/Info.plist` 存在说明已下降，
   用 `(prefix/"Foo.app").install Dir["*"]`；否则 `prefix.install Dir["**/Foo.app"].fetch(0)`。
2. **闭源软件不声明 license**。`license :cannot_redistribute` 与 `license "Proprietary"`
   都会被 `audit --strict` 判 `non-standard SPDX licenses` 拒掉；**不写 license 行**
   则 audit 直接跳过 license 检查（源码 `formula_auditor.rb`：`license.present?` 才审）。
3. **plist 版本可能比公式版本少段**。WorkBuddy 的 `CFBundleShortVersionString` 是三段
   （5.4.7），公式版本是四段（含构建号），post_install/test 做前缀比对而非全等
   （`version.start_with?("#{plist_version}.")`）。
4. **安装后 audit 会扫 app 内置的异架构模块**（公式时代记录，现不适用）。Electron x64
   包里附带 darwin-arm64 的 node 原生模块（node-pty/koffi 等预编译件，运行时用不到），
   装完再跑 `audit --strict` 会报 `Binaries built for a non-native architecture`。
   不能删（会破坏代码签名触发 Gatekeeper），公式时代的解法是在 tap 的
   `audit_exceptions/mismatched_binary_allowlist.json` 里豁免
   `WorkBuddy.app/Contents/Resources/**/*`。注意 Ruby fnmatch 的 `**` 不跨目录，
   结尾必须是 `/**/*` 而不是 `/**`（FNM_PATHNAME 下实测）。该文件随 workbuddy 转
   cask 已删除；cask 的 audit 规则不同，不需要此豁免。
5. **build-bottle 的链接修复对 Electron 是致命的**。`brew install --build-bottle`
   会把所有非 @rpath 的 dylib id 改写成 ~80 字符的 `/usr/local/opt` 绝对路径，
   load command header 已满的二进制直接崩（`Updated load commands do not fit in
   the header`，本地普通 install 却能过——坑只在制瓶时爆发）。解法三层：
   公式声明 `preserve_rpath`（公开 DSL，@rpath 形态不再被改写）；
   install 里用 brew 自带的 ruby-macho（`MachO::Tools.change_dylib_id`）把其余
   非 @rpath 的 id（ANGLE 的 `./libEGL.dylib`、libffmpeg 的 `@loader_path`、
   QimeiSDKMac 的绝对路径）统一改写为 `@rpath/<basename>` 并 ad-hoc 重签——
   dylib id 只是加载身份，没有任何 load command 按旧 id 引用，改写安全；
   ruby 细节两坑：`%w[]` 是单引号语义不解析 `\x` 字节转义，binary 串与 UTF-8
   字面量 `include?` 恒 false——magic 判断用 `unpack1("H8")` 的 hex 字符串比较。

### 11.10 制瓶推送 GHCR 的坑（2026-09-03 实测，node/node@22 连续失败 + 假绿的根因）

`brew pr-upload` 推送前会先 `skopeo inspect` 目标标签；**标签已存在且没传
`--keep-old` 就直接 `odie "<uri> already exists!"`**（Homebrew
`github_packages.rb` 的 `preupload_check`）。所以「保留当前版本」与「可覆盖推送」
不可兼得——要让同一版本能重复制瓶，就必须**先删再传**。清理逻辑踩了六个坑：

1. **端点用错**：owner 是普通用户（不是组织），端点必须是
   `users/{owner}/packages/container/...`，用 `orgs/...` 恒 404。
2. **包名漏前缀**：`package_name` 必须带 tap 名并 URL 编码，即
   `tahoe-intel%2Fnode`（`node@22` → `tahoe-intel%2Fnode%2F22`），
   只写 `node` 同样 404。
3. **CI 里 gh 没有凭据**：Actions 不会自动把 `secrets.GITHUB_TOKEN` 注入环境变量，
   `gh` CLI 只认 `GH_TOKEN`/`GITHUB_TOKEN`——不显式传就完全无凭据，调 API 直接
   报认证错误且 **stdout 为空**，清理静默失效。本机怎么测都测不出来：
   gh 会回落到 keyring 里的个人 token。这是整个「清理失效 → already exists」
   链条里最隐蔽的一环（诊断手段：把 API 原始返回打进日志）。
4. **gh api 把错误 JSON 打到 stdout**：`2>/dev/null` 拦不住，jq 的
   `select(...)` 也不匹配，于是整段 `{"message":"Not Found",...}` 会被当成
   version id 拿去 `DELETE`，表现为莫名其妙的 `exit code 4`。
   **必须校验 id 是纯数字**（`[[ "$vid" =~ ^[0-9]+$ ]]`）才删。
5. **GitHub 禁止删除包的「最后一个带标签版本」**：逐个删版本的路线走不通，
   `DELETE .../versions/<id>` 会返回 HTTP 400
   `You cannot delete the last tagged version of a package. You must delete
   the package instead.`（个人 token 带 delete:packages 也一样）。
   **唯一出路：删除整个包，让 pr-upload 重建**（包不存在时 pr-upload 正常
   建包推瓶；重建后的包会继承公开状态，实测匿名拉取正常）。
   对比：`docker push` 同名 tag 天然覆盖，根本没有这道检查——CharonAnchor
   那类 docker 镜像项目享受不到这个限制，也别拿它类比 brew 瓶。
6. **用 `|| echo` 把 pr-upload 失败降级成警告是危险的**：job 会变绿，但 GHCR 上
   仍是旧瓶，而后续步骤照样把新瓶的 sha256 写回公式 → **公式里的 sha256 与
   实际可下载的瓶不符，用户 `brew install` 时校验失败**。宁可 job 红，不可假绿。
   「删整个包重建」的方案下同样禁止：删除失败要让 job 红着暴露问题。

另外三个相关坑：

- **推送后用「匿名 pull token 列标签 + skopeo delete」清理老标签不可靠**：
  包还是私有（首次推送时，公开化步骤在其后）时 `curl -f` 会失败，
  在 `set -euo pipefail` 下以 **exit 22 中断整个 job**；且 skopeo 在 GHCR 上
  删 manifest list 会报 `unsupported`（见 8.5）。该职责已并入「推送前删包重建」。
- **runner 镜像预装了 core 的 node@24（实测 24.19.0）**，它占用
  `/usr/local/bin/node` 等链接，会阻塞本 tap node 家族的 link 步骤：
  `Target /usr/local/bin/node is a symlink belonging to node@24`。
  `brew unlink` 对预装但登记不全的 keg 会静默失败，需改成
  `brew uninstall --force --ignore-dependencies` 并兜底删掉冲突符号链接。
- **brew 会缓存 GHCR 的 manifest JSON**：删包重建（同一 tag 指向新 manifest）后，
  本机若缓存了旧 manifest，`brew install/reinstall` 会报
  `Couldn't find manifest matching bottle checksum.`——瓶和公式其实都对，
  是缓存没刷新。`brew fetch --force --bottle-tag=tahoe <formula>` 强制重新
  拉取即可恢复；`brew fetch --bottle-tag=tahoe` 也是排查瓶是否可拉的最快手段
  （成功标志：`✔︎ Bottle Manifest` + `✔︎ Bottle` 两行）。

<<<<<<< HEAD
### 11.11 依赖树照搬进 tap 不可行：同名跨 tap 对依赖同样无条件 odie

qemu 初版方案把 30 个依赖全复制进本 tap（依赖全名化 + 全量流检查器都做好了），
首轮制瓶 29 秒即失败、方案被推翻。完整推导见 6 节「qemu 代编译模式」；要点：
两个 tap 的同名包**共用同一 Cellar 目录** + `install/check.rb` 无条件 odie，
所以「只要用户装过 core 的 X，本 tap 的 X 就永远装不上」，对依赖亦然。
第三方 tap 想给用户"零编译"，只能在**自己的叶子**上实现；枢纽包要么用户已有、
要么用户端源码构建——这是 tap 定位的固有边界，别拿 core 的做法硬套。

### 11.12 pr-upload 写的瓶块会因 job 中途死亡而丢失

`brew pr-upload --no-commit` 会把瓶块**写进 Formula/*.rb**（--no-commit 只是不
git commit），最终靠 workflow 的「提交瓶块」步骤入库。若制瓶循环里后面的公式失败，
job 直接死 → 提交步骤被跳过 → 已写好的瓶块随 runner 蒸发（GHCR 有瓶、公式没 sha，
后续包判「无瓶」走源码编译而失败；capstone/dtc/libslirp 实测中招）。
修法（bottle.yml 已落地）：循环步骤加 `id` → 「提交瓶块」加 `if: always()` →
追加「失败门槛」步骤（`steps.<id>.outcome == 'failure'` 时 exit 1）——失败仍红，
但成功部分的瓶块先入库。

### 11.13 旧 C 代码撞 C23：`int f();` 从「未原型」变「零参」

C23 起空参括号 `()` 等价 `(void)`。2016 年前后的代码（vde 2.3.3 实测）在 Xcode 26
runner（clang 默认 gnu23）下报 20 个 `too many arguments to function call,
expected 0, have 3`。本机 clang 21 默认标准下复现不了——用
`clang -fsyntax-only -std=gnu23 file.c` 强制即可复现，`-std=gnu17` 验证修复。
落地：公式 install 里 `ENV.append "CFLAGS", "-std=gnu17"`（gnu17 是 clang 15–19
的默认标准，恢复旧语义）。

### 11.14 关于 core 瓶与 GHCR 可见性的两个实测事实

- core **部分**包其实有 Intel tahoe 瓶（automake/autoconf/libtool/m4/texinfo/
  pkgconf/xz/zstd 带 `tahoe` 标签），但 qemu 那 26 个依赖**一个都没有**（只有
  arm64_* 和更老的 sonoma）→ 代编译前提成立，别拿「core 有 tahoe 瓶」否定整套方案。
- Actions 的 `GITHUB_TOKEN` 在 **public 仓库**建的 GHCR 包**默认即公开**（匿名
  curl 可直接拉 tags），「首推后需手动改 Public」不成立；删包重建也继承公开状态。
### 11.15 迁移 tap 公式 + raw 流的坑（2026-09-03 实测，opencode/sst/torpedo）

1. **version 行去留以 `audit --strict` 为准，不要凭 URL 猜**。本以为
   `*-darwin-x64.zip` / `*-mac-x86_64.tar.gz` 尾部数字会像 node 一样扫出 `"64"`，
   实测三包的 `v` 前缀版本号都能被正确扫描，显式 `version` 全被判冗余——删掉才过。
   结论：迁移公式先不写 version，跑一遍 audit 再定。
2. **`--version` 不是通用契约**。sst 裸跑 `--version` 打帮助 exit 1，版本在
   `sst version` 子命令里；torpedo 根本没有版本命令（`--version` 与 `version`
   子命令都非零退出）。`safe_popen_read` 不容忍非零退出（同 neofetch 坑），
   post_install/test 必须按实测写：sst 用 `sst version`，torpedo 用 `--help` + 架构校验。
3. **raw 解析三约束**（见 `parseGoReleaserRaw`）：先截 `on_linux` 段再找
   （linux 资产也带 x64）；只认 `intel?` 标记后的 url（torpedo 的 arm 块在前）；
   sha 校验 64 位 hex。降级模拟三包改写与源备份逐字节一致。
4. **依赖必须先制瓶**。`depends_on "bemly/tahoe-intel/ripgrep"` 全限定名强制走自家
   GHCR；但 `bottle.yml` 内按字母排序（opencode 排在 ripgrep 前），一次跑会让
   opencode 先编。制瓶分两次：先 `-f ripgrep`，再 `-f "opencode,sst,torpedo"`。

### 11.16 cask 发 Release 的两处核心 bug（2026-09-03 实测，doubao-ime 首发）

1. **旧 release 清理从未跑起来过**。`gh release list --json tagName` 回的是对象数组
   `[{"tagName":"..."}]`，核心按 `[String]` 强转恒失败 → 警告跳过 → 旧 release 堆积
   （workbuddy 亦然，只是目前只有一个版本没暴露）。已修为取 `tagName` 字段，
   并用假 release `doubao-ime-0.0.0-test` 实测删旧留新通过。
2. **上传用的临时文件名导致资产 404**。`gh release create/upload` 以本地文件名做资产名，
   核心直接传 curl 的 `updater-<UUID>` 临时文件 → Release 里资产名随机 → cask url 404。
   （workbuddy 的资产名是对的，应是当初手动传的，核心 bug 一直没暴露。）
   已修为上传前重命名成上游资产名；doubao 首发的两个垃圾资产已手删。
   教训：cask 首发后必须 `brew fetch --cask` 端到端验证（成功标志 `✔︎ Cask doubao-ime`）。

### 11.17 输入法 cask 的全自动安装（2026-09-03 实测，doubao-ime 免 sudo 改造）

1. **官方 install.sh 不可用于全自动场景**：硬编码 `/Library/Input Methods`，且内部嵌套
   `sudo chown -R root:staff`——无论 cask 怎么调都会弹密码。绕开方式：preflight 直接
   `unzip` 安装器 Resources 里的内层 zip（真身 DoubaoIme.app），不执行官方脚本；
   外层目录名带构建号每版都变，用 `DoubaoImeInstaller_*.app` 通配。
2. **用户级输入法目录完全可行**：`~/Library/Input Methods` 是 macOS 标准输入法位置，
   TIS 与系统设置都会列出。cask `app` stanza 的 `target:` 写 `~/...` 时
   `resolve_target` 会 `expand_path` 展开（`cask/artifact/relocated.rb` 实读确认），
   父目录不存在时 `Moved#move` 自动创建——真移动而非 symlink（symlink 输入法
   过不了 TIS 的签名/路径校验，不可用）。附带好处：app 自带的自动更新写用户目录
   不再需要管理员授权（系统级 `/Library` 反而每次自更新都要）。
3. **自动启用输入法**：`defaults write com.apple.HIToolbox AppleEnabledInputSources
   -array-add` 追加 `<dict>` 三键（Bundle ID / Input Mode / InputSourceKind="Input Mode"，
   与系统设置里手动添加后的记录同构）；先 `defaults read` 判重保证幂等（升级/重装
   不重复追加）；写完 `killall cfprefsd`（落盘）+ `killall SystemUIServer`（刷新菜单栏）。
   输入法图标未立即出现时，注销重登一次即生效。
4. **必须重启 `TextInputMenuAgent`，且要等几秒**：它持有登录会话启动时的输入源列表，
   不重启新装的输入法就不出现在菜单栏（只 `killall SystemUIServer` 无效，实测）。
   重启后 TIS 重建约需数秒——**装完立刻查会误判为"未启用"**，等 8 秒再查才稳定。
5. **验证手段（推荐）**：`TISCreateInputSourceList` 可程序化区分「已安装」与「已启用」。
   用 python ctypes 加载 `HIToolbox` 调用即可（`swiftc` 链接 TIS 符号会失败，别走那条路）。
   `ALL INSTALLED` 有而 `ENABLED` 没有 = 装了但没启用；两者都有 = 真正可用。
   `defaults read` 只反映偏好记录，不能作为"真的能用"的证据。
6. **卸载/升级删除 app 仍会走 sudo**：brew 删只读的 app 包时统一提权（既有行为，
   与装在用户级目录无关），非交互环境用 `SUDO_ASKPASS` 提供密码即可跑通。
   结论：**安装免密码，卸载/升级仍需密码**——caveats 里如实说明。
7. **`chmod -R u+w` 不破坏代码签名**：改的是权限位不是内容，`codesign -v` 仍 exit 0（实测）。
8. **验证明细**：`brew install --cask` 全程零密码；app 落位 `~/Library/Input Methods/`
   为真目录（非 symlink，universal x86_64+arm64）；`defaults read` 含豆包三键且重装无重复
   （postflight 判重幂等）；TIS 的 `ENABLED` 列表含 `com.bytedance.inputmethod.doubaoime.pinyin`。

### 11.18 evermeet 取 zip 不取 7z：brew 解 7z 需要 p7zip（2026-09-04 实测）

1. `getrelease[/ffprobe|/ffplay|/ffserver]` 302 到的都是 **7z**（`deolaha.ca/ffmpeg/<name>-<ver>.7z`），
   但 brew 的 `P7Zip` 策略硬依赖 `p7zip` 公式（`7zr`，`unpack_strategy/p7zip.rb` 实读确认）——
   p7zip 在 core 无 x86_64_tahoe 瓶，用户装它要从源码编译，违背本 tap 使命。
   同站有同版本 **zip**（`https://evermeet.cx/ffmpeg/<name>-<ver>.zip`，302 到
   `deolaha.ca/pub/ffmpeg/`，brew 原生格式零依赖）——公式一律取 zip。
   zip 内为单个二进制、无顶层目录（与 mufetch 同构，`bin.install "<name>"` 即可）。
2. GPG 签名验证：密钥 `0x476C4B611A660874`（指纹与上游公布一致）导入后完好；
   签名文件是 `<file-url>.sig` 后缀形式（如 `ffmpeg-9.0.1.zip.sig`），不是字面
   `/sig` 路径——按字面拼会 404。
3. ffprobe/ffplay 在 core 无公式，版本判据只能走 brew 流的 **ffmpeg stable**
  （evermeet 三者同版本配套，当前同为 9.0.1；evermeet 发版若滞后于 core，
   检查器报 `upstream-missing` 开 issue 跳过，不误改公式）。

### 11.19 fish.app 只装 base/；darwin-amd64 不触发版本扫描坑（2026-09-04 实测）

1. fish 官方 `.app.zip` 是"启动器 + unix 树"双结构：`Contents/MacOS/fish` 只是
   开终端的启动器，真正的 shell 在 `Contents/Resources/base/`（即官方 install.sh
   要 `ditto` 到 /usr/local 的内容：bin/etc/share）。公式**只装 base/**
   （`bin/etc/share` 原样进 prefix），不装 .app 本体——shell 要的是稳定路径
   （/etc/shells + chsh 写死一路经，.app 内路径随版本变化），且 base 二进制只链
   系统库（otool 确认仅 libiconv/libSystem），搬家安全。设默认 shell 仍要用户手动
   `sudo sh -c 'echo …/fish >> /etc/shells'` + `chsh -s`（见公式 caveats）。
2. `buildx-v0.37.0.darwin-amd64` 的 `amd64` 尾缀**不**触发 node 式的版本扫描坑：
   显式 `version` 行被 audit 判冗余（实测）——说明 `Version.parse` 对该形态能正确
   扫出 `0.37.0`。结论：尾缀是否致盲以 `audit --strict` 实测为准，不要凭字面猜
   （opencode/sst/torpedo 同理，见 11.15）。
3. 上游校验文件缺位两例：fish release 无 SHA256SUMS（404）；docker/buildx 的
   checksums.txt 只有 freebsd/linux/netbsd/openbsd 条目、**无 darwin**——两者检查器
   `checksumsURL` 皆置 nil，有更新时回退下载实算（fish ~25MB / buildx ~68MB，
   仅检测到新版本时发生）。
4. **fish 4.9.0 的两个 helper 是纯 arm64**（`fish_indent`/`fish_key_reader` 无
   x86_64 切片，主 `fish` 才是 universal）——在 Intel 上跑不起来，公式只装主
   fish（man 页保留）。教训：universal 包不能只验主二进制，`bin/*` 要逐个
   `file`；明知跑不起来的文件**不要**用 audit 豁免硬保（那是给"用不到才无害"
   的文件准备的，见 11.25），直接不装。

### 11.20 越狱系 cask 三则（2026-09-04 实测，checkra1n/palera1n/TSKMGR）

1. **core 被 disable 的 cask 正是本 tap 的机会**：core 的 checkra1n 因过不了
   Gatekeeper 已 `disable!`（2026-09-01），新用户装不上——本 tap 同版本同文件
   同 sha 直引即成可用路径（cask 无 bottle 机制，不存在"瓶缺失"问题）。
   同名 cask 跨 tap 照样互斥：装过 core 旧版的先 `brew uninstall --cask`。
2. **audit 的"URL 无版本"靠 `#{version}` 插值消解**：checkra1n 的 `%20` 编码文件名、
   palera1n 的版本号只在路径（`v3.0.0-beta.2/`）不在文件名——两者都被判 unversioned
   而要求 `sha256 :no_check`。写法照抄 core/zcode：url 里写 `#{version}` 插值
   （值仍 pin 死在 version 行，不检查更新），audit 即过。
3. **双架构 cask 两种形态**：universal 单包（palera1n）什么都不用做，一个 url+sha
   天然覆盖双架构；按架构分包（TSKMGR）用 `arch arm:/intel:` + url `#{arch}` 插值，
   `app` 行同样插值（`MacOSTSKMGR-#{arch}.app`），sha256 用 `sha256 arm:/intel:`
   直给——**不要只为 sha256 套 `on_arm`/`on_intel`**，会被 style 的
   `OnSystemConditionals` 判违规；另 `desc` 禁止出现平台词（"for macOS" 撞
   `Cask/Desc`，见 macos-tskmgr 首版）。
4. **装前看 /Applications 是否已有同名 app**：本机实测三者都被用户多年前手装过，
   cask 安装会报 `already an App` 中断——属保护机制非 bug；要迁入 brew 管理需先
   备份移走旧 app，验证完本轮已原样恢复（checkra1n 顺带验证了 `binary` 垫片，
   `checkra1n --version` 出 `beta 0.12.4`）。

### 11.21 github 直跟流 + compose 两则 + cask 收编（2026-09-04 实测）

1. **UpdaterCore 新增 `github` 流**（brewui 首例）：不在 core、又无自有更新接口的
   软件，直接跟 GitHub release——`HEAD releases/latest` 取 `Location` 跳转目标
   的 tag（不跟随、不调 API、不耗限额），剥 `githubTagPrefix`（默认 `"v"`）得版本，
   `downloadURL` 模板收版本号（与 brew 流一致）。cask 照常用 `version` 行，
   `rewriteFormula` 同步。brewui 实测 `tag v0.2.1 → 0.2.1 → up-to-date` 全通。
2. **compose 文件名无版本也能扫**：`docker-compose-darwin-x86_64` 文件名无版本、
   版本只在路径 `v5.5.1` 段——显式 `version` 行被 audit 判冗余，说明 brew 连路径段
   一起扫。结论并入 11.19 第 2 条：是否显式声明一律以 `audit --strict` 为准。
3. **checksums 的 `*` 前缀坑**：docker/compose 的 checksums.txt 有 darwin 行，
   但文件名带 `*`（binary 模式），核心按 `awk '$2==f'` 精确匹配对不上——置 nil
   回退下载实算（~65MB，仅新版本时），不要为省流量把 `*` 写进 asset 耍小聪明。
4. **新公式写完 grep 自查跨包残留**：docker-compose.rb 首版 install 行复制了
   buildx 的文件名（`buildx-v…darwin-amd64`），装之前 `grep buildx` 即现形——
   同系列公式连写时必须过一遍异名残留。
5. **`brew install --cask --adopt` 收编已装 app**：本机 Homebrew.app/WinStart.app
   皆手装在先，cask 报 `already an App`；`--adopt` 直接纳入管理（winstart 一次成）。
   root 属主的 app（Homebrew.app）收编要 sudo，非交互跑不通——需用户手动
   `sudo chown` 或删掉重装（反例：同机 winstart 属主为 bemly，收编零密码一次成）。

### 11.22 cask 的 quarantine brew 不清；破签名 + 隔离 = "已损坏"（2026-09-04 实测）

1. **11.2（别手动清隔离属性）只适用于公式**：cask 产物实测残留
   `com.apple.quarantine`（brew 不清）——palera1n/TSKMGR 装完 `xattr` 皆在。
2. 两种 Gatekeeper 死法要区分：**无签名但包完整**（palera1n）→ 提示"来自身份不明
   的开发者"，右键打开可绕过；**adhoc 签名已破**（TSKMGR 改包后未重签，
   `codesign -v` 报 `invalid Info.plist`、`spctl` 报 `invalid resource directory`）
   → 直接判"已损坏"，右键也绕不过，必须清隔离属性才跑得起来。
3. 修法（macos-tskmgr 已落地）：cask `postflight` 里
   `system_command "/usr/bin/xattr", args: ["-d", "-r", "com.apple.quarantine", app]`
   ——只清 quarantine 不碰其他属性；完整性锚点是公式/cask 的 sha256 pin，
   不依赖 Gatekeeper。路径用 `Dir["#{appdir}/MacOSTSKMGR-*.app"].fetch(0)`
   而非 `#{arch}` 插值（postflight 上下文里 arch 不可用，写死更稳）。
   修完重装验证：`xattr -p` 报 No such xattr 且全包 `find -xattrname` 计数为 0。
4. fish `Couldn't find manifest matching bottle checksum` 是 11.10 已知问题
   （删包重建后本机缓存旧 manifest）：`brew fetch --force --bottle-tag=tahoe`
   刷新即恢复——用户侧遇到先走这条，不用动公式。

### 11.23 Swift 实参顺序 + runner 纯 CR 响应头（2026-09-04 实测，watcher 红史）

1. **Swift 实参必须与形参同序**：`doubao-ime.swift` / `workbuddy.swift` 把
   `uploadRelease:` 写在 `customRelease:` 之前，从落仓第一天起就没编译通过过
   （`argument 'customRelease' must precede argument 'uploadRelease'`）——此前
   无人跑过全量 watcher 才没暴露。修法：闭包实参按 init 声明序放
   （zcode.swift 早有注释，另两文件照抄）。**教训**：改完 `updater/` 必须在本地
   把 CI 循环完整跑一遍再 push（25 个逐个 `swiftc`，见下），不能只编自己新增的：
   `for sw in updater/*.swift; do swiftc -O -o /tmp/check-$(basename $sw .swift) updater/UpdaterCore.swift $sw; done`。
2. **runner 的 curl 响应头可能是纯 `\r` 分隔**（无 `\n`）：brewui 的 github 流在
   本机全通、在 ubuntu runner 上三连 check-failed；诊断打出 `curl exit=0`、
   输出 4888B 却是"1 行"——`components(separatedBy: "\n")` 永远找不到 Location。
   修法：header 解析一律按 `CharacterSet.newlines` 切分（`\n`/`\r\n`/纯`\r` 全兼容）。
   成因未深究（runner curl/代理 quirks），只认现象。
3. **检查器失败必须明示**：`githubLatestTag` 拿不到 tag 时曾直接 `fail()`（exit 1
   无 status），workflow 会当"无需更新"静默吃掉。现改为重试 3 次仍失败则发
   `status=check-failed`（exit 0），`watch-updates.yml` 收集公示（不开 issue，
   下次自动恢复）。顺带给该路径加过 GH_TOKEN 认证（已 revert：限流就等下次，
   反复跑只会更限——保持匿名）。

### 11.26 双架构产物分支 + url 改写语义修正（2026-09-04 实测，zcode 双架构化）

1. **UpdaterCore 新增双架构维度**（版本来源正交）：`archArtifacts: [token]`
   + `downloadURLForArch: (version, arch) -> url`，置上即走 `runDualArchCheck`
   （逐个 HEAD 探测 → 下载实算 → 改写 version 行 + `sha256 arm:/intel:` 行；
   url 行不动，`#{version}/#{arch}` 插值已覆盖新版本）。token→key 由
   `caskArchKey` 显式映射（未知 token 直接 fail，绝不静默错配）；双产物无
   checksums 模板（有更新逐个实算）；与 `uploadRelease` 镜像流不可同用（fail 明示）。
2. **旧改写语义有个潜 bug**：`rewriteFormula` 原来整条替换 url 行——对插值 url
   （zcode/brewui 的 `#{version}`）第一次更新就会把插值写死成字面，顺带破坏
   audit 的版本判定。现改为：镜像流（`uploadRelease`）仍整条换；其余只做
   旧版本号子串替换（数字边界，与 check-updates.sh 时代一致），纯插值行不动；
   自检同步放宽（字面一致或插值保留均可）。单产物公式在模板与文件一致时，
   子串替换的结果与原来整条替换逐字节相同（本地 harness 实测：
   gh 2.100.0→2.101.0 的 url 行精确变成模板实例化结果；
   brewui 0.2.1→0.2.2 的插值 url 行原样保留、version 行同步）。
3. **palera1n 这类 universal 单包什么都不用做**：无 arch 门槛的 cask 天然双架构，
   "允许双架构" = 不加门槛、不分包——只有上游按架构分包（zcode/TSKMGR/konsole）
   才需要 `arch` 插值。
4. **StanzaGrouping 别手调**：`arch`/`version` 的空行布局 cop 说了算——本次手删
   空行反而新报两条，`--fix` 一键复原（复原即最初写法）。以后只管 --fix + 看 diff。
5. **双架构改写有两个连环坑，都是实测抓的**：① core 通行写法里 `sha256` 只出现
   一次，第二段写成换行延续（`intel: "..."` 无前缀）——只认 `^sha256 <key>:` 的
   解析会漏整段，改写完报"未找到 sha256 行"；修法是首行/延续行双正则 + 行内
   key 逐个换；② 自检不能要求字面 `sha256 <key>: "<sha>"`（单空格）——对齐空格
   原样保留后是多空格，自检也要认 `:\s+`。两者都是拿 `/tmp` 摆拍文件（zz1/zz2，
   版本调低一位触发真更新链路）实测定位的——双分支的端到端验证就靠这招，
   外加 review 真 Release 资产后删掉摆拍 tag。
6. **konsole 这类"只留最新"上游必须镜像**：KDE CI 目录单文件（5276 当天即 404），
   直链 cask 出生几天即坏——`customRelease` 抓双 listing 交集最大构建号判新，
   双包镜像到本仓 Release（`konsole-<构建号>`，旧快照自动清理），cask 永远指
   Release。按月手动跑 watcher（不设 cron，见 §5）。

### 11.24 上游会重切同版本包：sha 可能出生即过期（2026-09-04 实测，gh 2.100.0）

watcher 用 checksums.txt 取到 `39d5…` 写入公式，接着 bottle 就报
`Formula reports different checksum`——当时 checksums.txt 与实包都已变成
`fcd7…`（cli 团队重传了同名资产）。症状即 `reports different checksum`；
修法：重下实物算 sha，再核对 checksums.txt **当下**值，三方
（下载实物/当下 checksums/公式）一致才改公式，改完重跑 bottle。
教训：checksums.txt 不是不可变快照，同版本重切只认三方一致，不认"watcher 当时看到的值"。

### 11.25 全仓扫手滑：装后审计 + 豁免回归 + 风格腐化（2026-09-04 实测）

1. **架构审计只查已安装的 keg**：`audit --strict` 的异架构检查在公式未安装时
   直接跳过——收录时"audit 全过"不代表二进制没问题。fish（11.19.4）与
   deepseek-harness 都是装完重审才暴露。结论：新包 SOP 的 audit 必须在
   `install` **之后**再跑一遍（`fetch` 前跑的那遍只审文本）。
2. **dsh 的 arm64 预编译件走 tap 豁免**：`node-pty/prebuilds/darwin-arm64/`
   （随包附带、Intel 运行时用不到，WorkBuddy 公式时代同款，见 11.9.4）——
   `audit_exceptions/` 机制随 workbuddy 转 cask 被删过，本次为公式加回：
   `audit_exceptions/mismatched_binary_allowlist.json`，格式
   `{"<formula>": ["<相对 prefix 的 glob>", ...]}`，多级目录必须用
   `/**/*` 结尾（FNM_PATHNAME 下 `**` 不跨目录，实测）。豁免只给"用不到才
   无害"的文件，明知跑不起来的（fish 那俩 helper）不许进豁免，直接不装。
3. **风格会腐化**：本机 brew 会自动更新（只有 CI 锁了 `HOMEBREW_NO_AUTO_UPDATE`），
   rubocop cops 会变严——qemu 链 5 个公式（core 拷入 + 门禁改写）攒了几十个
   `DependencyOrder`/`ComponentsOrder`/`EmptyLines` 才被发现。修法就
   `brew style --fix`，但必须 review diff：本次它顺手删了 qemu.rb 从 core 带回的
   两行注释（`bison # >= 3.0`、`python@3.14 # keep aligned with meson`），
   已手动补回——autocorrect 的 diff 要逐行看，不能无脑提交。
4. **README 会漏行**：AGENTS §6 全，但 README 中英都漏了 qemu 链 5 包 + neofetch
   （早期合并时没同步）。以后新增软件顺手把三处表格（AGENTS/中/英）一次填齐。

### 11.27 opencode 双架构：摘 arch 门槛的例外（2026-09-04 实测）

1. 本 tap 唯一摘 `arch` 门槛的公式：`opencode`（加回 `darwin-arm64` 段，结构照抄
   源文件 `on_macos` 内套双 `if Hardware::CPU`）+ 它的依赖 `ripgrep`
   （ARM 装 opencode 会依赖到它，不摘则 ARM 直接被拒；ripgrep 是源码编译，
   ARM 上现编即可）。`macos: :tahoe` 门槛保留。sst/torpedo 暂不动（同系列但
   无人要 ARM 版，要了再按此套路加）。
2. 瓶仍只有 x86_64（macos-26-intel 制出，无 ARM runner 可出 arm 瓶）——ARM 安装
   回退上游直链（同版本 arm64 包，无需制瓶）。公式只改门槛/加段、不动安装产物
   时，旧瓶继续有效，不必重制（本次即如此）。
3. 检查器走 raw 双架构分支（`rawDualArch: true`）：`parseGoReleaserRawDual`
   取双块 url/sha，`rewriteFormulaRawDual` 按缩进判定块作用域改写双块
   （块内 `def install...end` 缩进更深，不会误出块；找不到对应行直接 fail）。
   双改写的端到端验证靠 harness（假版本号调纯函数，看双块替换 + 摘瓶）。
4. ARM 侧无法在本机验证（无 ARM 硬件）：arm 段 url/sha 与源文件逐字节核对 +
   结构照抄源文件；`post_install`/`test` 用 `Hardware::CPU.arm?` 双分支，
   Intel 侧全绿即发。
   ——后续用户在 ARM Mac mini（macOS 27）上实测通过：arm64 段走直链 2 秒装完、
   `post_install` 架构校验过；代价是 ripgrep 无 arm 瓶、源码编译一次性拉起
   13 个编译期依赖（rust/llvm/ruby 三栈约 2.5GB，见下）。

## 12. 待办 / 后续演进

- [x] 批量更新已是 watcher 的唯一模式：扫全部 `Formula/*.rb`（Swift 检查器）→ 提交 `main` → 单次 `bottle.yml` 出多瓶（见 5.1 / 7 / 9.8）。新增软件仍按第 9 节 SOP 加。
- [x] **brew 未收录软件的版本来源**：`CheckConfig.customRelease` 自定义流已支持
      （WorkBuddy 走其 Electron 自动更新接口，见 `updater/workbuddy.swift` 与 9.3）；
      仍未适配的软件会发 `status=brew-missing` 并跳过（`UpdaterCore` 内 TODO）。
- [ ] 实测验证 watcher → 单次 bottle 全自动链路在真实多软件更新下的表现（含 Swift 检查器
      在 ubuntu runner 上的首次运行，以及 workbuddy 这种 ~465MB 大包在 macos-26-intel
      上的制瓶耗时与 GHCR 推送）。
- [x] **上游不提供 macOS amd64 包的软件 → 代编译模式已落地（qemu 首例，2026-09-03）**：
      上游源码做原料，`bottle.yml` 在 macos-26-intel 现编译出 GHCR 瓶（root_url 指向
      `ghcr.io/v2/bemly/tahoe-intel`，不是 GitHub Releases——早期设想已废弃，见 6 节
      「qemu 代编译模式」）。qemu + capstone/dtc/libslirp/vde 已收录并本机验收。
- [x] **anomalyco 分支（feat/anomalyco-3）已合并回 main 并逐个制瓶完成**（2026-09-03~04）：
      `ea02f08 Merge branch 'feat/anomalyco-3' into main`；opencode/sst/torpedo/ripgrep 走 raw 流
      公式 + 代编译/直引流程逐个制瓶（Log 见 `bottle: 更新 GHCR 瓶块（opencode,sst,torpedo）`、
      `（ripgrep）`），workbuddy/doubao-ime cask 也已落地；15 个公式现均带 `bottle do` 块。
      合并时的 worktree 注意事项已失效（分支已合回 main，软链指向 main 即可）。
- [ ] watcher 目前只比对 `versions.stable`；如某软件需要跟踪 `versions.head` 再扩展。
- [ ] 接入 `brew livecheck` 作为可选的辅助检查手段。
