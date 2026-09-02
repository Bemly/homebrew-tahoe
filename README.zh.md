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

# 若之前装过 homebrew/core 的 gh / fastfetch，必须先卸载：
# 同名公式跨 tap 不能共存，brew 会直接拒绝安装
brew uninstall gh
brew uninstall fastfetch

brew install bemly/tahoe-intel/gh
brew install bemly/tahoe-intel/fastfetch
```

## 收录的软件

| 软件 | 说明 |
| --- | --- |
| `gh` | GitHub 官方 CLI，直接取 `gh_<ver>_macOS_amd64.zip` |
| `fastfetch` | 类 neofetch 的系统信息工具，直接取 `fastfetch-macos-amd64.tar.gz`（release tag 无 `v` 前缀） |

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
| 有新版本 / GHCR 里还没瓶 | 手动触发 `bottle.yml`：制瓶并覆盖 GHCR 上的旧瓶 |
| 无更新 | 保持从 GHCR 下载 |
| 上游资源取不到 | `watch-updates.yml` 开 issue 告警 |

刚升级完还没重制瓶时，brew 会回退到上游 `url` 直链，同时仓库里会有一个提醒制瓶的 issue。

> GHCR 包默认私有，匿名 `brew install` 会 401。若遇到，到
> 仓库 Settings → Packages 把对应包改成 public。

## 本地制瓶（以 fastfetch 为例）

公式新增或升级后，把瓶推到 GHCR，安装就不会回退到上游直链：

1. 进入 GitHub 仓库的 **Actions → Build bottle and publish to GHCR**。
2. 点击 **Run workflow**。
3. 选择公式（`gh` 或 `fastfetch`）并运行。

workflow 会：信任 tap → 以 `--build-bottle` 安装 → 跑 `brew bottle` 制瓶
→ 覆盖 GHCR 上已存在的同名 tag → `brew pr-upload` 推 GHCR 并把 `bottle do` 块写回公式 → 提交。

## 维护

两个 workflow，**都只支持手动触发**，不设定时任务：

| Workflow | 作用 | Runner |
| --- | --- | --- |
| `watch-updates` | 比对 **homebrew/core 中的版本号** 与本地公式版本，有更新则改写公式并开 PR、开 issue | `ubuntu-latest` |
| `bottle` | 制瓶并推 GHCR，把瓶块提回公式 | `macos-26-intel` |

开发者约定见 [AGENTS.md](AGENTS.md)。
