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
| `workbuddy` | 5.4.7.37521366 | cask——WorkBuddy 官方 zip（Electron 自动更新接口 `/v2/update` 动态获取），镜像到本仓 GitHub Release | 已收录 |
| `node` | 26.8.1 | Node.js 官方 `node-v<ver>-darwin-x64.tar.gz`（外部链接，release tag 无 `v` 前缀） | 已收录 |
| `node@24` | 24.20.0 | Node.js 官方 `node-v<ver>-darwin-x64.tar.gz`（外部链接） | 已收录 |
| `node@22` | 22.23.2 | Node.js 官方 `node-v<ver>-darwin-x64.tar.gz`（外部链接） | 已收录 |

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
- **推送前统一清空该包的已有版本**：`bottle.yml` 在 `pr-upload` **之前**
  用 GitHub API（`users/{owner}/packages/container/tahoe-intel%2F<name>/versions`）
  列出该包全部版本并逐个 `DELETE`（单个失败只告警不阻断）。这一步同时达成两个目的：
  清掉历史老瓶，以及让同版本可以重复推送（`pr-upload` 撞已存在标签会直接
  `odie "already exists!"`，所以必须先删再传，见 11.10）。
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

5. 新建 `updater/<name>.swift`（与 `Formula/<name>.rb` 同名，一一对应），两种写法：
   - **brew 流**（软件在 homebrew/core）：照抄 `gh.swift` 的 `@main` 结构，改 4 处配置——
     `formula` / `brewName`、`asset`、`downloadURL`、`checksumsURL`
     （上游无 checksums 文件则置 `nil`，核心自动回退下载计算）；
   - **自定义流**（brew 未收录）：照抄 `workbuddy.swift`，实现 `customRelease` 闭包调
     上游自有更新接口，返回 `UpstreamRelease(version:downloadURL:sha256:)`
     （sha 仅在实测确认归属时才给，否则置 nil 由核心下载实算）。
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

### 11.9 桌面 app 公式的三个坑（以 WorkBuddy 为例）

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
4. **安装后 audit 会扫 app 内置的异架构模块**。Electron x64 包里附带 darwin-arm64 的
   node 原生模块（node-pty/koffi 等预编译件，运行时用不到），装完再跑
   `audit --strict` 会报 `Binaries built for a non-native architecture`。
   不能删（会破坏代码签名触发 Gatekeeper），解法是在 tap 的
   `audit_exceptions/mismatched_binary_allowlist.json` 里豁免
   `WorkBuddy.app/Contents/Resources/**/*`。注意 Ruby fnmatch 的 `**` 不跨目录，
   结尾必须是 `/**/*` 而不是 `/**`（FNM_PATHNAME 下实测）。
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

### 11.10 制瓶推送 GHCR 的四个坑（2026-09-03 实测，node/node@22 连续失败的根因）

`brew pr-upload` 推送前会先 `skopeo inspect` 目标标签；**标签已存在且没传
`--keep-old` 就直接 `odie "<uri> already exists!"`**（Homebrew
`github_packages.rb` 的 `preupload_check`）。所以「保留当前版本」与「可覆盖推送」
不可兼得——要让同一版本能重复制瓶，就必须**先删再传**。清理逻辑踩了四个坑：

1. **端点用错**：owner 是普通用户（不是组织），端点必须是
   `users/{owner}/packages/container/...`，用 `orgs/...` 恒 404。
2. **包名漏前缀**：`package_name` 必须带 tap 名并 URL 编码，即
   `tahoe-intel%2Fnode`（`node@22` → `tahoe-intel%2Fnode%2F22`），
   只写 `node` 同样 404。
3. **gh api 把错误 JSON 打到 stdout**：`2>/dev/null` 拦不住，jq 的
   `select(...)` 也不匹配，于是整段 `{"message":"Not Found",...}` 会被当成
   version id 拿去 `DELETE`，表现为莫名其妙的 `exit code 4`。
   **必须校验 id 是纯数字**（`[[ "$vid" =~ ^[0-9]+$ ]]`）才删。
4. **用 `|| echo` 把 pr-upload 失败降级成警告是危险的**：job 会变绿，但 GHCR 上
   仍是旧瓶，而后续步骤照样把新瓶的 sha256 写回公式 → **公式里的 sha256 与
   实际可下载的瓶不符，用户 `brew install` 时校验失败**。宁可 job 红，不可假绿。

另外两个相关坑：

- **推送后用「匿名 pull token 列标签 + skopeo delete」清理老标签不可靠**：
  包还是私有（首次推送时，公开化步骤在其后）时 `curl -f` 会失败，
  在 `set -euo pipefail` 下以 **exit 22 中断整个 job**；且 skopeo 在 GHCR 上
  删 manifest list 会报 `unsupported`（见 8.5）。该职责已并入「推送前统一清空」。
- **runner 镜像预装了 core 的 node@24（实测 24.19.0）**，它占用
  `/usr/local/bin/node` 等链接，会阻塞本 tap node 家族的 link 步骤：
  `Target /usr/local/bin/node is a symlink belonging to node@24`。
  `brew unlink` 对预装但登记不全的 keg 会静默失败，需改成
  `brew uninstall --force --ignore-dependencies` 并兜底删掉冲突符号链接。

## 12. 待办 / 后续演进

- [x] 批量更新已是 watcher 的唯一模式：扫全部 `Formula/*.rb`（Swift 检查器）→ 提交 `main` → 单次 `bottle.yml` 出多瓶（见 5.1 / 7 / 9.8）。新增软件仍按第 9 节 SOP 加。
- [x] **brew 未收录软件的版本来源**：`CheckConfig.customRelease` 自定义流已支持
      （WorkBuddy 走其 Electron 自动更新接口，见 `updater/workbuddy.swift` 与 9.3）；
      仍未适配的软件会发 `status=brew-missing` 并跳过（`UpdaterCore` 内 TODO）。
- [ ] 实测验证 watcher → 单次 bottle 全自动链路在真实多软件更新下的表现（含 Swift 检查器
      在 ubuntu runner 上的首次运行，以及 workbuddy 这种 ~465MB 大包在 macos-26-intel
      上的制瓶耗时与 GHCR 推送）。
- [ ] 若某些软件上游不提供 macOS amd64 包，改为自建 bottle：
      新增一个 `workflow_dispatch` 的 `bottle.yml`，构建后传到 GitHub Releases，
      公式里加 `bottle do ... sha256 tahoe: "..." end`，root_url 指向本仓 Releases。
- [ ] watcher 目前只比对 `versions.stable`；如某软件需要跟踪 `versions.head` 再扩展。
- [ ] 接入 `brew livecheck` 作为可选的辅助检查手段。
