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
├── scripts/
│   └── check-updates.sh               # 版本检查逻辑（可被 workflow 或手动调用）
└── .github/
    └── workflows/
        ├── watch-updates.yml          # 手动触发的版本 watcher（ubuntu）
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
| 制瓶任务用 `macos-26-intel` | 瓶标签由**构建机**的架构+系统决定，必须 Intel + macOS 26 才是 `x86_64_tahoe`；该 job 只在手动制瓶时跑 |
| `fetch-depth: 1` | 只拉最新提交，不全量 clone |
| 版本查询走 formulae.brew.sh | Homebrew 官方站点，**不消耗 GitHub API 限额** |
| sha256 取 `checksums.txt`（~2KB） | 避免下载 15MB 的发布包 |
| `concurrency` + `timeout-minutes` | 防重复跑、防挂死 |

## 6. 当前收录

| 软件 | 版本 | 来源 | 状态 |
| --- | --- | --- | --- |
| `gh` | 2.99.0 | GitHub 官方发布包 `gh_2.99.0_macOS_amd64.zip`（外部链接） | 已收录 |

### gh 发布包结构（已实测）

```
gh_2.99.0_macOS_amd64/
├── LICENSE
├── bin/gh                 # 42MB，单架构 x86_64
└── share/man/man1/*.1     # 229 个 man 页
```

共 231 个文件，zip 约 15MB。
sha256：`70c05750c75df9465bc73b994e8bc379243bb494271f1b51f54ead2e19e45471`

## 7. Watcher 工作原理

`watch-updates.yml` → `scripts/check-updates.sh`：

1. 从 `Formula/gh.rb` 读出本地版本号（优先 `version` 行，没有则从 `url` 行解析）；
2. `GET https://formulae.brew.sh/api/formula/gh.json` 取 `.versions.stable`
   —— **这是 brew 上的版本号，不是上游 GitHub 的最新版**，正是需要的判据；
3. 用 `sort -V` 比较：本地 == brew → 结束；本地 > brew → 结束；brew 更新 → 继续；
4. **HEAD 探测新版本资源是否可下载**；不可下载则发 `status=upstream-missing`
   并开 issue 告警，不再往下走；
5. 取新版本的 sha256：优先 `GET gh_<ver>_checksums.txt`（2KB），失败才回退下载 15MB zip；
6. 用 `sed` 改写 `Formula/gh.rb` 的 `url` / `sha256`，并做改后自检；
7. **摘除失效的 `bottle do` 块**（其 sha256 属于旧版本），并发 `bottle_stale=true`；
8. workflow 建分支 `bump/gh-<ver>` 提交并开 PR（PR 已存在则复用分支），
   同时按状态开 issue 告警。

支持输入参数：

- `formula`：要检查的软件（目前只有 `gh`）
- `dry_run`：`true` 时只检查不提交，先看结果再决定

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
- 制瓶产物（`*.bottle.json` / `*.bottle.tar.gz`）已进 `.gitignore`，不要提交。

## 9. 新增软件的 SOP

1. 确认上游有 **macOS amd64** 预编译产物，且支持 macOS 26。
2. 下载该产物，记录 **sha256**，确认解压后的目录结构。
3. 照第 4 节模板写 `Formula/<name>.rb`，类名用 CamelCase。
4. 在 `scripts/check-updates.sh` 的 `case "$FORMULA"` 里登记该软件的
   `asset` / `download_url` / `checksums_url`（无 checksums 文件则留空，自动回退下载计算）。
5. 在两个 workflow 的 `options:` 里都加上该软件名：
   `watch-updates.yml` 和 `bottle.yml`。
6. 本地验证（见第 10 节）通过后再合并。
7. 手动跑一次 `bottle.yml`，让 GHCR 上有瓶、公式里生成瓶块。

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

手动跑一遍 watcher（不改文件用 dry_run 思路，直接看输出）：

```bash
./scripts/check-updates.sh gh
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

## 12. 待办 / 后续演进

- [ ] 需要时补充更多 Intel Tahoe 软件（按第 8 节 SOP 加）。
- [ ] 若某些软件上游不提供 macOS amd64 包，改为自建 bottle：
      新增一个 `workflow_dispatch` 的 `bottle.yml`，构建后传到 GitHub Releases，
      公式里加 `bottle do ... sha256 tahoe: "..." end`，root_url 指向本仓 Releases。
- [ ] watcher 目前只比对 `versions.stable`；如某软件需要跟踪 `versions.head` 再扩展。
- [ ] 接入 `brew livecheck` 作为可选的辅助检查手段。
