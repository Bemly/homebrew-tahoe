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
- `pre_install` 做环境与资源检查；`post_install` 做架构校验与版本自检。
  **不要手动清 `com.apple.quarantine`**（原因见 11.2）。
- `bottle do ... end` 块**不要手填 sha256**：瓶块由 `bottle.yml` 制瓶后自动写回，
  手填的值与 GHCR 里的实际产物必然不一致。瓶块里的标签写纯系统名 `tahoe`。

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
| 包有新版本，或 GHCR 里还没有瓶 | 手动触发 `bottle.yml`：制瓶 → 覆盖 GHCR 上的旧瓶 → 瓶块提交回公式 |
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
- 制瓶产物（`*.bottle.json` / `*.bottle.tar.gz`）已进 `.gitignore`，不要提交。

## 9. 新增软件的 SOP（端到端 Runbook）

目标：把一个新软件做成「用户 `brew install bemly/tahoe-intel/<name>` 时直接命中 GHCR 瓶」的状态。
下面每一步都是必做项，**顺序不能跳**——之后每个软件都按这套走。

### 9.1 调研上游（确定原料）

1. 确认上游有 **macOS amd64** 预编译产物，且能在 macOS 26 跑。
   优先找 GitHub Releases 的 `*-macOS-amd64*` / `*-macos-amd64*` 资产。
2. 确定版本号来源：
   - 在 core 里的软件，看 `https://formulae.brew.sh/api/formula/<name>.json` 的 `.versions.stable`；
   - 不在 core 的软件（如 `fastfetch`）直接盯上游 release 页，release tag 可能无 `v` 前缀。
3. 下载该产物，**本地实测**算出 sha256，并 `tar -tzf` / `unzip -l` 看解压后目录结构
   （顶层目录名、bin 位置、是否需要拆层级，见 11.1）。

### 9.2 写公式

4. 照第 4 节模板写 `Formula/<name>.rb`，类名 CamelCase。
   `url` 用上游直链（制瓶原料）；`sha256` 用 9.1 实测值；
   必须带 `depends_on arch: :x86_64` + `depends_on macos: :tahoe`。
   **不要手填 `bottle do` 块**（由 bottle.yml 制瓶后自动写回，见 8.5）。

### 9.3 登记到 watcher（updater/）

5. 新建 `updater/<name>.swift`（与 `Formula/<name>.rb` 同名，一一对应）：照抄 `gh.swift`
   的 `@main` 结构，改 4 处配置——`formula` / `brewName`、`asset`、`downloadURL`、
   `checksumsURL`（上游无 checksums 文件则置 `nil`，核心自动回退下载计算）。
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

## 12. 待办 / 后续演进

- [x] 批量更新已是 watcher 的唯一模式：扫全部 `Formula/*.rb`（Swift 检查器）→ 提交 `main` → 单次 `bottle.yml` 出多瓶（见 5.1 / 7 / 9.8）。新增软件仍按第 9 节 SOP 加。
- [ ] 实测验证 watcher → 单次 bottle 全自动链路在真实多软件更新下的表现（含 Swift 检查器在 ubuntu runner 上的首次运行）。
- [ ] **brew 上没有收录的软件**：检查器目前发 `status=brew-missing` 并跳过（对应 `updater/UpdaterCore.swift` 内 TODO(brew-missing)），需要单独适配版本来源（例如直接盯上游 GitHub Releases 的最新 tag）。
- [ ] 若某些软件上游不提供 macOS amd64 包，改为自建 bottle：
      新增一个 `workflow_dispatch` 的 `bottle.yml`，构建后传到 GitHub Releases，
      公式里加 `bottle do ... sha256 tahoe: "..." end`，root_url 指向本仓 Releases。
- [ ] watcher 目前只比对 `versions.stable`；如某软件需要跟踪 `versions.head` 再扩展。
- [ ] 接入 `brew livecheck` 作为可选的辅助检查手段。
