# bemly/tahoe-intel

一个 Homebrew 第三方 tap，专为 **Intel（x86_64）Mac 上的 macOS 26（Tahoe）** 提供可直接安装的软件。

## 为什么

Homebrew 官方从 macOS 26 起不再为 Intel 构建 bottle。实测 core tap 中 `x86_64_tahoe` 瓶的数量为 0，
`gh`、`node` 等软件在 Intel Mac 上只能从源码编译。

本 tap 直接引用上游官方的 **macOS amd64 发布包**（外部链接），绕开这个限制。

## 安装

```bash
brew tap bemly/tahoe-intel
brew install bemly/tahoe-intel/gh
```

## 收录的软件

| 软件 | 说明 |
| --- | --- |
| `gh` | GitHub 官方 CLI，直接取 `gh_<ver>_macOS_amd64.zip` |

## 要求

- 处理器：**Intel（x86_64）**，Apple Silicon 请勿使用（直接用 `homebrew/core` 即可）
- 系统：**macOS 26（Tahoe）** 或更高

公式内已用 `depends_on arch: :x86_64` 与 `depends_on macos: :tahoe` 强制校验，条件不满足会直接拒绝安装。

## 注意事项

本 tap 的 `gh` 与 `homebrew/core` 的 `gh` **同名**，二者共用 `$(brew --prefix)/Cellar/gh`，
不能同时 link。切换来源：

```bash
# 用本 tap 的版本
brew unlink gh && brew link --overwrite bemly/tahoe-intel/gh

# 用 core 的版本
brew unlink bemly/tahoe-intel/gh && brew link gh
```

## 维护

版本更新由 `watch-updates` workflow 检查 —— 它比对 **homebrew/core 中的版本号** 与本地公式版本，
有更新则自动改写公式并发起 PR。该 workflow 只支持手动触发，不设定时任务。

开发者约定见 [AGENTS.md](AGENTS.md)。
