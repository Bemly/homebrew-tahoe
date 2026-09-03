# bemly/tahoe-intel

一个 Homebrew 第三方 tap，专为 **Intel（x86_64）Mac 上的 macOS 26（Tahoe）** 提供可直接安装的软件。

## 为什么

Homebrew 官方从 macOS 26 起不再为 Intel 构建 bottle。实测 core tap 中 `x86_64_tahoe` 瓶的数量为 0，
`gh`、`node` 等软件在 Intel Mac 上只能从源码编译。

本 tap 取上游官方的 **macOS amd64 预构建包**（不重新编译），打包成 Homebrew 瓶后
分发到 **GHCR**：`ghcr.io/v2/bemly/tahoe-intel`。

## 要求

- 处理器：**Intel（x86_64）**，Apple Silicon 请勿使用（直接用 `homebrew/core` 即可）
- 系统：**macOS 26（Tahoe）** 或更高

公式内已用 `depends_on arch: :x86_64` 与 `depends_on macos: :tahoe` 强制校验，条件不满足会直接拒绝安装。

## 安装

```bash
brew tap bemly/tahoe-intel

# 若之前装过 homebrew/core 的 gh / fastfetch / opencode，必须先卸载：
# 同名公式跨 tap 不能共存，brew 会直接拒绝安装
brew uninstall gh
brew uninstall fastfetch
brew uninstall opencode # core 的 opencode 是 npm 版，同名

brew install bemly/tahoe-intel/gh
brew install bemly/tahoe-intel/fastfetch
brew install bemly/tahoe-intel/opencode # 会连带装上本 tap 的 ripgrep 依赖

# workbuddy 是桌面 app，走 cask（装进 /Applications，Launchpad/Spotlight 可见）
brew install --cask bemly/tahoe-intel/workbuddy
# doubao-ime 是输入法，走 cask（自动跑官方安装器装进 /Library/Input Methods，会弹密码框）
brew install --cask bemly/tahoe-intel/doubao-ime
```

## 收录的软件

| 软件 | 说明 |
| --- | --- |
| `gh` | GitHub 官方 CLI，直接取 `gh_<ver>_macOS_amd64.zip` |
| `fastfetch` | 类 neofetch 的系统信息工具，直接取 `fastfetch-macos-amd64.tar.gz`（release tag 无 `v` 前缀） |
| `workbuddy` | 腾讯 WorkBuddy AI 办公工作台（Electron 桌面 app），cask，装进 `/Applications`；不在 brew core，版本由其自动更新接口动态获取 |
| `doubao-ime` | 豆包 AI 输入法，cask，装进用户级 `~/Library/Input Methods`（免 sudo）并自动写入系统输入源启用；不在 brew core，版本由其下载接口动态获取 |
| `node` | Node.js 运行时，直接取官方 `node-v<ver>-darwin-x64.tar.gz` |
| `node@24` | Node.js 24 LTS，直接取官方 `node-v<ver>-darwin-x64.tar.gz` |
| `node@22` | Node.js 22 LTS，直接取官方 `node-v<ver>-darwin-x64.tar.gz` |
| `opencode` | AI 编程 agent，取 `anomalyco/homebrew-tap` GoReleaser 公式的 Intel 段（`opencode-darwin-x64.zip`）；与 core 的 npm 版同名，装前须先卸载另一方 |
| `sst` | SST 开发框架，取 `anomalyco/homebrew-tap` GoReleaser 公式的 Intel 段（`sst-mac-x86_64.tar.gz`） |
| `torpedo` | sst/torpedo VPC 数据库访问工具，取 `anomalyco/homebrew-tap` GoReleaser 公式的 Intel 段（`torpedo-mac-x86_64.tar.gz`） |
| `ripgrep` | grep 类搜索工具，`opencode` 的依赖（随本 tap 出瓶） |
| `mufetch` | 系统信息工具，取 release 的 `mufetch_darwin_x86_64.tar.gz` |
| `cmd` | 终端 AI 编程 agent，npm 包 `command-code`（只暴露 `cmd` 命令）；依赖本 tap 的 node 瓶；不检查更新 |
| `zcode` | 智谱 z.ai 的 AI 辅助开发环境，cask 取上游 CDN 的 x64 dmg（core 的 zcode cask 只有 arm64）；版本跟随 core 的 cask |
| `deepseek-harness` | DeepSeek agent harness，npm 包 `@deepseek-ai/dsh`（只暴露 `dsh` 命令，`dsh web` 起浏览器 UI）；依赖本 tap 的 node 瓶；不检查更新 |
| `ffmpeg` | FFmpeg 本体，evermeet 的 Intel x86_64 静态构建（`ffmpeg-<ver>.zip`）；版本跟随 core 的 ffmpeg |
| `ffprobe` | FFmpeg 流分析器，evermeet 静态构建，与本 tap 的 ffmpeg 同版本；core 无此公式 |
| `ffplay` | FFmpeg 播放器，evermeet 静态构建，与本 tap 的 ffmpeg 同版本；core 无此公式 |
| `ffserver` | 上游已移除（4.0）的流媒体服务器，最后一个静态构建 3.4.2；不检查更新 |
| `fish` | 好用的 shell，取官方 `fish-<ver>.app.zip` 内的 unix 树（universal 二进制的 Intel 切片）；版本跟随 core 的 fish |
| `docker-buildx` | Docker 构建插件，官方 `buildx-v<ver>.darwin-amd64` 裸二进制；版本跟随 core 的 docker-buildx |
| `checkra1n` | checkm8 越狱工具，Intel x86_64 版（core 同名 cask 因 Gatekeeper 已被 disable）；锁定版本不检查更新 |
| `palera1n` | checkm8 越狱工具，universal 包单下载同时覆盖 Intel 与 Apple Silicon；锁定版本不检查更新 |
| `macos-tskmgr` | 任务管理器，按架构分包（`arch` 插值）；锁定版本不检查更新 |
| `brewui` | Homebrew 官方图形界面，cask 取其 GitHub release（`Homebrew-<ver>.zip`）；版本经 release 跳转跟踪 |
| `winstart` | Metro 风应用启动器，cask 镜像到本仓 Release（无公开上游链接）；锁定版本不检查更新 |
| `docker-compose` | Docker Compose 插件，官方 `docker-compose-darwin-x86_64` 裸二进制；版本跟随 core 的 docker-compose |

## 注意事项（同名冲突）

本 tap 的 `gh` / `fastfetch` 与 `homebrew/core` 的同名公式共用 `$(brew --prefix)/Cellar/<name>`，
不能同时 link。切换来源：

```bash
# 用本 tap 的版本
brew unlink gh && brew link --overwrite bemly/tahoe-intel/gh
brew unlink fastfetch && brew link --overwrite bemly/tahoe-intel/fastfetch

# 用 core 的版本
brew unlink bemly/tahoe-intel/gh && brew link gh
brew unlink bemly/tahoe-intel/fastfetch && brew link fastfetch
```

## GHCR 瓶

安装包从 **GHCR** 分发：`ghcr.io/v2/bemly/tahoe-intel`
（Homebrew 会剥掉仓库名的 `homebrew-` 前缀，与核心的 `ghcr.io/v2/homebrew/core` 同构）。

瓶的内容直接来自上游预构建包，**不重新编译**。瓶标签由构建机的架构与系统决定，
为了产出 `x86_64_tahoe`，制瓶跑在 `macos-26-intel` runner 上。

| 场景 | 处理 |
| --- | --- |
| 软件有新版本 | `watch-updates` 改写公式后自动触发 `bottle.yml`（也可手动触发） |
| GHCR 里还没有瓶（新收录软件） | 手动触发 `bottle.yml`：制瓶并推 GHCR |
| 无更新 | 保持从 GHCR 下载 |
| 上游资源取不到 | `watch-updates.yml` 开 issue 告警 |

新版本刚推送、新瓶还没上 GHCR 的短暂窗口里，brew 会回退到上游 `url` 直链。

> GHCR 包默认私有，匿名 `brew install` 会 401。若遇到，到
> 仓库 Settings → Packages 把对应包改成 public。

## 触发制瓶（以 fastfetch 为例）

公式新增或升级后，把瓶推到 GHCR，安装就不会回退到上游直链：

1. 进入 GitHub 仓库的 **Actions → Build bottle and publish to GHCR**。
2. 点击 **Run workflow**。
3. 填入公式名（单个 / 逗号分隔多个如 `gh,fastfetch` / `all` 表示全部）并运行。

workflow 会：信任 tap → 以 `--build-bottle` 安装 → 跑 `brew bottle` 制瓶
→ 覆盖 GHCR 上已存在的同名 tag → `brew pr-upload` 推 GHCR 并把 `bottle do` 块写回公式 → 提交。

## 维护

两个 workflow，**都只支持手动触发**，不设定时任务：

| Workflow | 作用 | Runner |
| --- | --- | --- |
| `watch-updates` | 批量扫描全部公式与 **homebrew/core** 版本（Swift 检查器，`updater/` 每包一个文件）；有更新则改写公式、直接提交 `main` 并自动触发一次制瓶 | `ubuntu-latest` |
| `bottle` | 制瓶并推 GHCR，把瓶块提回公式 | `macos-26-intel` |

开发者约定见 [AGENTS.md](AGENTS.md)。
