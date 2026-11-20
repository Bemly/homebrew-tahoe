# AGENTS.md

> 本文件是 `bemly/tahoe` 仓库的开发约定与执行计划。
> 任何人（或 Agent）改动本仓库前，先读完这份文档。
>
> **提交与推送（硬性约定，2026-11-14 起）**：每次改动完成（代码 / 公式 / cask / 文档）后，
> 一律立即 `git add` + `commit` + `git push origin main`，不需要用户再明确要求。
> 旧的「无明确要求不 commit」规则已废除。

## 1. 项目定位

`bemly/tahoe` 是一个 Homebrew 第三方 tap，只解决一件事：

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
用户仍走瓶安装。这类软件往往**带整棵依赖树**——**不能把 core 的依赖同名照搬进本 tap**
（同名公式跨 tap 是 Homebrew 硬限制，对依赖同样生效）：枢纽依赖留给 core；core 无 Intel
瓶的依赖按 6.3 分流——能同名的直接接管，有 core 依赖方的改名 `fork-*` 自瓶。
完整规则见 6 节「qemu 代编译模式」与 6.3。

**例外——arm64-only（2026-10-05 起，`afm` 为首例）**：AFM拼音输入法两个二进制皆
thin arm64，Intel 机跑不起来，但值得收录。经用户拍板作为首个破例收进本 tap：
cask 写 `depends_on arch: :arm64`（Intel 安装直接拒绝，见 11.40），macos 门槛不变。
此口子只为自有软件（AFM）开，不接外部 arm64-only 收录。

**例外——分发修改版专有二进制（2026-11-20 起，`antigravity` 为首例）**：本仓此前所有
镜像（11.34 政策）传的都是**未改动的官方包**，只是把地址换成本仓 Release 以免直链腐烂。
`antigravity` cask 不同：它分发的是**在官方 darwin-x64 包上静态改写 `app.asar`
（中文汉化 + Gemini 娘挂件 + 禁用应用自更新）后 ad-hoc 重签**的重打 dmg——即
**公共 Release 上放了修改过的 Google 专有二进制**。这是与 Google 条款冲突的显式破例，
经用户拍板收录；理由是本 tap 的使命就是让 Intel Tahoe 能用上这些软件，而官方包在
Intel 上缺汉化与挂件能力。约束：构建必须由 `Widgets/antigravity-niang/build.sh`
一条命令复现、官方输入的 sha256 必须与 homebrew/core 的 cask API 核对一致、
每步都有硬质量门（宁可不产出，不出半成品）；`RELEASE-NOTES.template` 里如实写明
上游许可状况（汉化引擎仓库无 LICENSE、原角色形象 CC BY-NC-SA、默认立绘出处待确认）。
细节与踩坑见 11.61。

**第二例 `github-copilot-app`（2026-11-21 起）**：同一破例口径，但补丁形态不同——
GitHub Copilot 桌面版是 **Tauri（WKWebView）**，前端资源 brotli 压在 500MB+ 的主二进制里，
没有 asar 可改，故走**运行时注入**：官方 Intel dmg 复制后塞进两个 x86_64 dylib
（上游 MIT 中文插件 `CopilotCN.dylib` + 本仓页内挂件 `GyWidgetCN.dylib`），
官方主二进制改名 `github-real`、`github` 位置换成自编译的启动器（算 dylib 绝对路径设
`DYLD_INSERT_LIBRARIES` 再 exec），带 `disable-library-validation` 等 entitlements
ad-hoc 重签后重打 dmg。
中文插件是 MIT（`licenses/ZH-MIT.txt` 随仓），但**被注入的 GitHub 专有二进制仍是修改版**，
破例性质与 antigravity 相同。构建同样一条命令复现
（`Widgets/github-copilot-cn/build.sh`，CI 跑），官方输入 sha 由脚本实算并缓存
（core cask 那份是 arm64 包的，不能用来核对 Intel 包）。细节见 11.62。

## 2. 命名约定

| 项 | 值 | 说明 |
| --- | --- | --- |
| tap 名 | `bemly/tahoe` | 用户使用时的名字，**不得改写** |
| 仓库名 | `bemly/homebrew-tahoe` | GitHub 仓库名必须带 `homebrew-` 前缀，`brew tap bemly/tahoe` 才能简写解析 |
| 公式目录 | `Formula/` | 标准 Homebrew 布局 |
| 公式全名 | `bemly/tahoe/<name>` | 安装时必须写全名；依赖引用同样写全名 |
| 依赖改名 | `fork-<core>` | core 有依赖方、不能同名接管时用；能同名的沿用 core 名（见 6.3） |

> 仓库名里的 `homebrew-` 是 Homebrew 的强制前缀，不是给 `tahoe` 加料。
> tap 名保持 `bemly/tahoe` 原样。

## 3. 目录结构

```
homebrew-tahoe/
├── AGENTS.md                          # 本文件：约定 + 计划
├── README.md / README.zh.md           # 面向用户的使用说明（英文 / 中文）
├── Formula/                           # 130 个公式，一个软件一个文件（含 39 个 fork-*）
├── Casks/                             # 25 个 cask（桌面 app / 输入法）
├── Patches/                           # glib / libssh2 / libtool / python / swift 补丁
├── Widgets/antigravity-niang/         # antigravity 补丁成品构建：挂件源码 + asar 工具 + build.sh
├── Widgets/github-copilot-cn/         # github-copilot-app 补丁成品构建：注入 dylib + 启动器 + 宠物 + build.sh
├── audit_exceptions/                  # 装后 audit 豁免（mismatched_binary_allowlist.json）
├── updater/
│   ├── UpdaterCore.swift              # 检查器共享核心（版本来源 / 比对 / 改写 / 输出协议）
│   └── <name>.swift                   # 144 个检查器入口，与 Formula|cask 一一同名
└── .github/
    └── workflows/
        ├── watch-updates.yml          # 手动触发的批量版本 watcher（ubuntu + Swift）
        ├── bottle.yml                 # 手动触发的制瓶 + 推 GHCR（macos-26-intel）
        ├── patched.yml                # 手动触发的补丁成品构建 + cask lint（macos-26-intel）
        └── sysroots.yml               # 手动触发的交叉编译 sysroot 构建（发 Release）
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
| 版本来源按流分流 | brew 公式 / cask API、GitHub `releases/latest`、源 tap raw、上游自有接口；只有 brew 流走 formulae.brew.sh（**不消耗 GitHub API 限额**），见第 7 节 |
| sha256 取 `checksums.txt`（~2KB） | 避免下载 15MB 的发布包 |
| `concurrency` + `timeout-minutes` | 防重复跑、防挂死 |
| 补丁成品构建与 cask lint 走 CI | `patched.yml`（macos-26-intel，手动）：`build.sh --upload` → 把 sidecar 的 sha 写回工作区 cask → `brew style`/`audit --strict` → 绿了才提交 cask；**开发机只跑轻量取证**（语法/样本串/探针/日志/fetch）。2026-11-21 用户纠正：本地跑 brew lint 与构建把 Intel 开发机卡死 |
| 批量制瓶只占一次 runner | `watch-updates.yml` 扫全部（唯一模式），只触发**一次** `bottle.yml`（逗号列表传参）；`bottle.yml` 在单个 `macos-26-intel` 任务里顺序出瓶，绝不逐个触发 |
| 递归依赖门控 | `bottle.yml` 在 `brew readall` 后展开每批公式的**运行时**依赖闭包（build deps 只在 CI 现编、不影响用户端，故不检查）：本仓依赖必须有瓶块（同批公式由拓扑排序在本轮出瓶，豁免）、core 依赖经 formulae.brew.sh API 查无 `tahoe`/`x86_64_tahoe`/`all` 瓶则直接失败并列出名单；旧公式确需 compat 时手动勾 `allow_unbottled_core: true` 放行，见 8.1 / 11.59 |

### 5.1 批量模式的核心约束：一次 runner 出多个瓶

watcher 扫到 N 个软件更新时，**绝不让 watcher 逐个 `gh workflow run` 触发 N 次 `bottle.yml`**——
那会变成 N 次 macOS runner 占用（macOS 按 10 倍分钟计费，最贵）。正确做法：
watcher 把更新直接提交 `main`，再用**一个** `gh workflow run -f formula="a,b,c"`
触发 `bottle.yml`，由它在**单个** `macos-26-intel` 任务内循环为 a/b/c 出瓶。
`bottle.yml` 的 `formula` 入参支持：`gh`（单）、`gh,fastfetch`（逗号多）、`all`（遍历 `Formula/*.rb`）。

## 6. 当前收录

> 2026-11-21 核对：**130 个公式 + 25 个 cask**，`updater/` 144 个检查器（另有 `UpdaterCore.swift`）。
> 供给方式五类：**预编译直引**（上游 macOS Intel 包）、**源码 / 代编译**（core 拷入或上游源码，CI 现编）、
> **`fork-*` 依赖层**（core 依赖改名 + `keg_only` 自瓶）、**cask**（桌面 app / 输入法，镜像到本仓 Release）、
> **补丁成品**（本地重打包：官方包 + 静态改写 + 重签，仅 `antigravity`，见 1 节破例与 11.61）。
> 所有公式都带 `depends_on arch: :x86_64` + `depends_on macos: :tahoe`；cask 按架构门槛。

### 6.1 预编译直引（上游 macOS Intel 包）

| 软件 | 版本 | 来源 | 备注 |
| --- | --- | --- | --- |
| `aarch64-unknown-linux-gnu` | 15.2.0 | messense 交叉工具链 GitHub Releases | 只收 Intel host 段；交叉到 aarch64 Linux；github 流 + `.sha256` sidecar |
| `antigravity-cli` | 1.5.13 | Google GCS `antigravity-public` 的 `cli_mac_x64.tar.gz`（按构建号分目录） | 扁平裸二进制装成 `agy`；customRelease 跟官方 auto-updater manifest（只给 sha512，核心回退下载实算）；core 无同名公式 |
| `boost@1.85` | 1.85.0 | MarkusJx/prebuilt-boost GitHub `boost-<ver>-macos-13-clang-static+shared-x86.tar.gz` | 第三方预编译 static+shared；dylib 补 `@rpath` + ad-hoc 重签；与 core 同名；freeling 依赖 |
| `caddy` | 2.11.9 | 官方 `caddy_<ver>_mac_amd64.tar.gz` | 扁平包；H2/H3 基线；brew 模板流 |
| `chisel` | 1.12.0 | GitHub `chisel_<ver>_darwin_amd64.gz` | gzip 裸二进制；github 流；与 core 同名异物 |
| `cmake` | 4.5.0 | Kitware GitHub `cmake-<ver>-macos-universal.tar.gz` | universal；core 无 Intel 瓶；brew 模板流 |
| `cmd` | 1.45.0 | npm `command-code` tarball | 纯 JS 装进 libexec；依赖本 tap node；不检查更新 |
| `deepseek-harness` | 0.2.2-rc.1 | npm `@deepseek-ai/dsh` tarball | 纯 JS；`dsh web`；依赖本 tap node；跟 npm latest |
| `docker-buildx` | 0.39.0 | GitHub 裸二进制 `buildx-v<ver>.darwin-amd64` | brew 模板流 |
| `docker-compose` | 5.8.0 | GitHub 裸二进制 `docker-compose-darwin-x86_64` | 文件名无版本；brew 模板流 |
| `dotnet` | 11.0.100 | 官方 builds.dotnet.microsoft.com `dotnet-sdk-<ver>-osx-x64.tar.gz` | .NET SDK；整包进 prefix + `write_exec_script`；显式 version 行；customRelease 跟 release-metadata API；与 core 同名 |
| `exiftool` | 13.55 | SourceForge `Image-ExifTool-<ver>.tar.gz` | 纯 Perl 直装；与 core 同名同物 |
| `fastfetch` | 2.71.0 | GitHub `fastfetch-macos-amd64.tar.gz` | release tag 无 `v`；brew 模板流 |
| `ffmpeg` | 9.0.2 | evermeet 静态 `ffmpeg-<ver>.zip` | 单二进制；版本跟 core ffmpeg |
| `ffplay` | 9.0.2 | evermeet 静态 `ffplay-<ver>.zip` | 同上；core 无同名公式 |
| `ffprobe` | 9.0.2 | evermeet 静态 `ffprobe-<ver>.zip` | 同上；core 无同名公式 |
| `ffserver` | 3.4.2 | evermeet 静态 `ffserver-3.4.2.zip` | 上游 4.0 已移除；不检查更新 |
| `fish` | 4.9.3 | 官方 `fish-<ver>.app.zip` 内 unix 树 | universal Intel 切片；只装 `base/` |
| `frida-server` | 17.27.0 | GitHub `frida-server-<ver>-macos-x86_64.xz` | 裸二进制；github 流；需 sudo |
| `fzf` | 0.75.0 | GitHub `fzf-<ver>-darwin_amd64.tar.gz` | 单二进制；github 流 |
| `gh` | 2.105.0 | GitHub `gh_<ver>_macOS_amd64.zip` | brew 模板流；sha 走 checksums.txt |
| `git-lfs` | 3.8.1 | GitHub `git-lfs-darwin-amd64-v<ver>.zip` | 全套 man；brew 模板流 |
| `go` | 1.27.4 | 官方 `go<ver>.darwin-amd64.tar.gz` | 完整工具链；零依赖；显式 version 行 |
| `h2spec` | 2.6.0 | GitHub `h2spec_darwin_amd64.tar.gz` | 单二进制；brew 模板流 |
| `hyperfine` | 2.0.0 | GitHub `hyperfine-v<ver>-x86_64-apple-darwin.tar.gz` | 带 man/补全；brew 模板流 |
| `iperf3` | 3.22 | userdocs `iperf3-amd64-osx-15` | 静态零依赖；customRelease 取最大世代 |
| `llvm` | 19.1.7 | GitHub `LLVM-19.1.7-macOS-X64.tar.xz` | pinned（20+ 仅 ARM64）；keg-only；`LIBCLANG_PATH` |
| `llvm-mingw` | 20261117 | mstorsjo/llvm-mingw 预编译 | Intel host 交叉到 Windows；github 流 |
| `mufetch` | 0.1.1 | GitHub `mufetch_darwin_x86_64.tar.gz` | tar 无顶层目录；sha 走 checksums.txt |
| `ninja` | 1.13.2 | GitHub `ninja-mac.zip` | universal；core 有瓶仍镜像 |
| `node` | 26.13.1 | 官方 `node-v<ver>-darwin-x64.tar.gz` | 显式 version 行；brew 模板流 |
| `node@20` | 20.20.2 | 官方 `node-v20.x-darwin-x64.tar.gz` | 显式 version 行；与 core 同名 |
| `node@22` | 22.23.5 | 官方 `node-v22.x-darwin-x64.tar.gz` | 显式 version 行 |
| `node@24` | 24.22.3 | 官方 `node-v24.x-darwin-x64.tar.gz` | 显式 version 行 |
| `opencode` | 1.19.6 | anomalyco raw 公式（双架构） | Intel 走瓶、ARM 直链；依赖 `ripgrep` |
| `openjdk` | 26.0.2.1_macos | jdk.java.net GA `macos-x64_bin.tar.gz` | keg-only；customRelease；与 core 同名 |
| `openjdk@17` | 17.0.21 | Adoptium Temurin x64 tar.gz | customRelease API；keg-only |
| `openjdk@21` | 21.0.13 | Adoptium Temurin x64 tar.gz | customRelease API；keg-only |
| `openjdk@26` | 26.0.2.1_macos | jdk.java.net GA（锁 26 线） | 与 `openjdk` 同源同物 |
| `postgresql@13` | 13.23 | EDB `postgresql-<ver>-1-osx-binaries.zip` | 只装 bin/include/lib/share（跳过 pgAdmin 等 app）；`keg_only`（自带 openssl/icu 会撞 core）；与 core 同名 |
| `protobuf` | 36.2 | 官方 `protoc-<ver>-osx-x86_64.zip` | 预编译；与 core 同名 |
| `rustup` | 1.29.3 | static.rust-lang.org 裸二进制 | cargo/rustc 垫片；跟 release-stable.toml |
| `scrcpy` | 5.0.1 | GitHub `scrcpy-macos-x86_64-v<ver>.tar.gz` | 静态；整包进 libexec |
| `sst` | 4.17.2 | anomalyco raw（Intel 段） | `sst version` 取版本 |
| `swift` | 6.4.2 | swift.org 官方 `swift-<ver>-RELEASE-osx.pkg` | 重打包只暴露 `swift`/`swiftc`；customRelease |
| `torpedo` | 0.0.13 | anomalyco raw（Intel 段） | 无版本命令，不做版本自检 |
| `x86_64-unknown-linux-gnu` | 15.2.0 | messense 预编译（Intel host） | 203MB；`.sha256` sidecar；依赖留 core/fork |
| `yt-dlp` | 2026.10.26 | GitHub `yt-dlp_macos` 单二进制 | universal；零依赖；brew 模板流 |
| `z3` | 5.3.3 | 官方 `z3-<ver>-x64-osx-13.3.zip` | 预编译；显式 version（URL 会扫成 13.3） |
| `zig` | 0.17.1 | 官方 `zig-x86_64-macos-<ver>.tar.xz` | 预编译；与 core 同名 |

### 6.2 源码 / 代编译（core 拷入或上游源码）

| 软件 | 版本 | 来源 | 备注 |
| --- | --- | --- | --- |
| `abseil` | 20260817.0 | core 拷入（源码） | cmake；protobuf 依赖；与 core 同名 |
| `aria2` | 1.37.0 | core 拷入（源码） | autotools；fork-c-ares/libssh2/openssl@4/sqlite |
| `automake` | 1.20 | core 拷入（源码） | 纯 autotools；无运行时依赖 |
| `bash` | 5.3.20 | core 拷入（源码） | fork-ncurses/readline/gettext；与 core 同名 |
| `capstone` | 5.0.9 | core 拷入（源码） | cmake；fork-gettext；qemu 依赖 |
| `curl3` | 8.23.0 | core 拷入（源码） | 改名 + `--enable-proxy-http3`；纯客户端；fork-* 依赖 |
| `dtc` | 1.8.1 | core 拷入（源码） | 依赖 `libyaml`；qemu 依赖 |
| `freeling` | 4.2 | core 同名接管（源码） | cmake；解捆自带 dynet/eigen；依赖本 tap `boost@1.85`/`icu4c@78`/`fork-dynet`；`revision` 与 core 同步 |
| `git` | 2.56.1 | core 拷入（源码） | make；fork-pcre2/gettext/openssl@4；与 core 同名 |
| `graphviz` | 16.1.1 | core 拷入（源码） | 零第三方渲染插件；autotools |
| `guile` | 3.0.11 | core 同名接管（源码） | fork-bdw-gc/gmp/libunistring…；交叉工具链依赖 |
| `icu4c@78` | 78.3 | core 同名接管（源码） | autotools；`keg_only`；freeling 依赖；`revision` 与 core 同步 |
| `jemalloc` | 5.4.0 | core 同名接管（源码） | autotools；nghttp2 依赖 |
| `libev` | 4.33 | core 同名接管（源码） | autotools；nghttp2 依赖 |
| `libimobiledevice` | 1.4.0 | core 拷入（源码） | idevice 栈主包；30+ 工具 |
| `libimobiledevice-glue` | 1.3.3 | core 拷入（源码） | 依赖 `libplist` |
| `libnghttp2` | 1.71.0 | core 同名接管（源码） | lib-only；curl3/nghttp2 依赖（扇入 19） |
| `libnghttp3` | 1.19.0 | core 拷入（源码） | cmake；curl3 依赖 |
| `libngtcp2` | 1.26.0 | core 拷入（源码） | cmake；fork-openssl@3 |
| `libplist` | 2.8.1 | core 拷入（源码） | idevice 栈叶子 |
| `libslirp` | 4.9.7 | core 拷入（源码） | meson；fork-glib；qemu 依赖 |
| `libssh` | 0.12.2 | core 同名接管（源码） | cmake；fork-openssl@4 |
| `libtatsu` | 1.1.1 | core 拷入（源码） | TSS 库；revision 与 core 同步 |
| `libusbmuxd` | 2.1.1 | core 拷入（源码） | idevice USB 复用；revision 同步 |
| `libyaml` | 0.2.5 | core 同名接管（源码） | autotools；dtc 依赖 |
| `make` | 4.4.1 | core 拷入（源码） | 装成 `gmake`；与 core 同名 |
| `meson` | 1.12.1 | core 拷入（pip 安装） | 依赖本 tap `ninja` + `python@3.15`；与 core 同名 |
| `neofetch` | 7.1.0 | GitHub archive tag（纯脚本） | 已归档最后一版；不检查更新 |
| `nghttp2` | 1.71.0 | core 拷入（源码） | `--enable-app`；fork-c-ares/jemalloc/libev/libnghttp2 |
| `python@3.11` | 3.11.18 | core 拷入（源码） | fork-* 依赖；与 core 同名 |
| `python@3.15` | 3.15.2 | core 拷入（源码） | fork-*；meson 依赖；与 core 同名 |
| `qemu` | 11.1.3 | 上游源码 tar.xz | CI 代编译 68 目标；fork-* + capstone/dtc/libslirp/vde（模式见下） |
| `ripgrep` | 15.2.0 | core 拷入（源码） | fork-pcre2；opencode 依赖 |
| `simdjson` | 5.2.0 | core 同名接管（源码） | cmake |
| `snappy` | 1.3.1 | core 同名接管（源码） | cmake；fork-pkgconf 构建 |
| `socat` | 1.8.1.3 | core 拷入（源码） | fork-openssl@3；test 走回环 |
| `svt-av1` | 4.3.0 | core 拷入（源码） | cmake |
| `vde` | 2.3.3 | core 拷入（源码） | 2016 旧代码需 `-std=gnu17` |
| `wabt` | 1.0.42 | core 拷入（源码） | cmake；上游 macOS 资产仅 arm64 |
| `wget` | 1.25.0 | core 拷入（源码） | fork-libidn2/libpsl/openssl@4/gettext |
| `wimlib` | 1.14.5 | core 拷入（源码） | autotools；fork-pkgconf 构建 |

### 6.3 `fork-*` 依赖层（39 个）

core 里仍有 39 个运行时依赖在 Intel Tahoe 没有瓶（`glib`/`openssl@4`/`gnutls`/`python@3.14`…）。
同名跨 tap 是 Homebrew 硬限制：**有 core 依赖方的包不能同名搬进来**（卸 core 版会带崩它的
core 依赖方），所以统一改名 `fork-<core>` + `keg_only`，本仓公式按全名
`bemly/tahoe/fork-<core>` 引用；**能同名的直接接管**（`abseil`/`guile`/`jemalloc`/
`libev`/`libnghttp2`/`libssh`/`libyaml`/`snappy`，freeling 链再加 `boost@1.85`/
`icu4c@78`/`freeling` 本体，见 6.1 / 6.2）。

- 全部走 **brew JSON 全量流**（`CheckConfig(formula: "fork-x", brewName: "x")`），url/sha 跟随 core；
- 源码现编，`keg_only` 保证不污染 core 的链接；补丁随 `Patches/` 入库；
- 依赖方（qemu/curl3/python@3.15/wget/git/bash…）写全名，不再回落到 core 源码编。

| fork 公式 | 对应 core | 版本 | 说明 |
| --- | --- | --- | --- |
| `fork-bdw-gc` | `bdw-gc` | 8.2.12 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-brotli` | `brotli` | 1.2.1 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-c-ares` | `c-ares` | 1.34.9 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-dynet` | `dynet` | 2.1.2 | 源码现编；`keg_only`；freeling 依赖；`revision` 与 core 同步；上游 2020 停更（core 已标 deprecated） |
| `fork-eigen@3` | `eigen@3` | 3.4.1 | 源码现编；`keg_only`；`fork-dynet` 依赖（`EIGEN3_INCLUDE_DIR` 指本源） |
| `fork-freetype` | `freetype` | 2.15.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-gettext` | `gettext` | 1.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-giflib` | `giflib` | 6.1.3 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-glib` | `glib` | 2.90.1 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-gmp` | `gmp` | 6.3.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-gnutls` | `gnutls` | 3.8.13 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-jpeg-turbo` | `jpeg-turbo` | 3.2.1 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-json-c` | `json-c` | 0.19 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-libidn2` | `libidn2` | 2.3.8 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-libpng` | `libpng` | 1.6.59 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-libpsl` | `libpsl` | 0.23.3 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-libssh2` | `libssh2` | 1.11.1 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-libtasn1` | `libtasn1` | 4.21.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-libtiff` | `libtiff` | 4.7.2 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-libunistring` | `libunistring` | 1.5 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-libusb` | `libusb` | 1.0.30 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-little-cms2` | `little-cms2` | 2.20 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-lz4` | `lz4` | 1.11.1 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-lzo` | `lzo` | 2.10 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-mpdecimal` | `mpdecimal` | 4.0.1 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-ncurses` | `ncurses` | 6.6 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-nettle` | `nettle` | 4.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-openssl@3` | `openssl@3` | 3.5.9 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-openssl@4` | `openssl@4` | 4.1.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-p11-kit` | `p11-kit` | 0.26.6 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-pcre2` | `pcre2` | 10.49 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-pixman` | `pixman` | 0.46.4 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-pkgconf` | `pkgconf` | 3.0.11 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-python@3.14` | `python@3.14` | 3.14.10 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-readline` | `readline` | 8.3.6 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-sqlite` | `sqlite` | 3.54.1 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-webp` | `webp` | 1.6.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-xz` | `xz` | 5.8.4 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-zstd` | `zstd` | 1.5.7 | 源码现编；`keg_only`；依赖方写全名 |

### 6.4 cask（25 个，桌面 app / 输入法）

cask 无 bottle 机制：watcher 检测到新版本后下载发布包、上传本仓 GitHub Release、
改写 `Casks/<name>.rb`，**不触发 `bottle.yml`**。所有 cask 一律镜像最新版（见 11.34）。

| 软件 | 版本 | 架构 | 说明 |
| --- | --- | --- | --- |
| `afm` | 2026.09.15 | arm64 | 输入法；用户级 `~/Library/Input Methods`；arm64 破例；不检查更新 |
| `amd` | 2026.09.18 | universal | 自有软件；app + `obcli`；本地构建镜像；不检查更新 |
| `antigravity` | 2.33.0-4731201358004224-cn4 | Intel | 官方 darwin-x64 包 + 汉化/页内 Gemini 娘挂件/补充词典静态改写 + 禁自更新，ad-hoc 重签后重打 dmg 镜像本仓 Release；版本形态 `<宿主版本>-<构建号>-cn<补丁序号>`（见 11.61 第 9 条）；**分发修改版专有二进制的破例**（见 1 节与 11.61）；customRelease 读 core cask API 判新、sha 取构建上传的 `.sha256` sidecar，产物由 `Widgets/antigravity-niang/build.sh` 在 **CI（patched.yml）** 构建（不走 uploadRelease 镜像分支） |
| `blender-5x` | 5.2.2 | Intel | Intel 社区构建；github 流；镜像 |
| `brewui` | 0.6.0 | universal | universal；github 流；镜像 |
| `checkra1n` | 0.12.4 | Intel | core cask 已 disable；镜像；不检查更新 |
| `doubao-ime` | 1.1.1 | Intel | 输入法；custom API；镜像 |
| `dsh-gui` | 0.2.1-rc.4 | Intel | nightly feed 判新；镜像 |
| `github-copilot-app` | 1.4.2-cn1 | Intel | 官方 darwin-x64 dmg + 运行时注入补丁（上游 MIT 中文插件 `CopilotCN.dylib` + 本仓页内挂件 `GyWidgetCN.dylib`；官方主二进制改名 `github-real`，`github` 位置换成设绝对路径 `DYLD_INSERT_LIBRARIES` 的启动器），带 disable-library-validation entitlements ad-hoc 重签后重打 dmg 镜像本仓 Release；版本形态 `<宿主版本>-cn<补丁序号>`；**第二个修改版专有二进制破例**（见 11.62）；customRelease 读 core cask API + sidecar，产物由 `Widgets/github-copilot-cn/build.sh` 在 **CI（patched.yml）** 构建；**自更新未禁用**（Tauri updater 在二进制里），caveats 写明变回英文就 reinstall |
| `grok-bot` | 1.2.3 | Intel | Cursor 下载页锚定；镜像 |
| `heliport` | 2.0.0-alpha | universal | universal；不检查更新 |
| `konsole` | 5485 | dual | KDE CI 构建号；双架构；`alwaysUpdate`；每月手动跑 |
| `lceda-pro` | 4.1.105 | Intel | 官网下载页 Intel 行；zip 套 dmg；镜像 |
| `lceda` | 6.5.61 | Intel | 官网下载页 Intel 行；镜像 |
| `lody` | 0.113.1 | Intel | brewCask 判新；镜像 |
| `macos-tskmgr` | 1.1.1 | dual | 双架构；不检查更新 |
| `mirage-wallpaper` | 1.1.6 | Intel | customRelease + `.sha256`；镜像 |
| `palera1n` | 3.0.0-beta.2 | universal | universal dmg；不检查更新 |
| `qoder` | 0.5.14 | Intel | qoder.cn 更新日志；镜像；与 core 同名 |
| `qwen-ime` | 1.2.60.60 | Intel | 上游下载 API；镜像 |
| `toshllm` | 0.88.0 | Intel | github 流；app 自带更新器 |
| `winstart` | 0.13.6 | universal | 本地包人工发版；不检查更新 |
| `wireshark` | 4.4.19 | Intel | Sparkle appcast Intel 项；镜像；ChmodBPF |
| `workbuddy` | 5.11.3.43806934 | Intel | Electron 更新接口；镜像 |
| `zcode` | 3.18.2 | dual | brewCask + 双架构；镜像 |

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
3. **自瓶（公式写全名 `bemly/tahoe/<name>`）**：主软件 qemu + qemu 专属叶子
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

`watch-updates.yml`（**只有批量模式**，没有单软件模式）是唯一的版本入口，跑在 `ubuntu-latest`：

1. 遍历 `Formula/*.rb` 与 `Casks/*.rb`，对每个文件查找**同名** `updater/<name>.swift`
   （`fastfetch.rb` ↔ `fastfetch.swift` 一一对应；找不到就 warning 跳过——`cmd`/`ffserver`/
   `llvm`/`neofetch`/`afm`/`amd`/`checkra1n`/`heliport`/`macos-tskmgr`/`palera1n`/
   `winstart` 这 11 个「不检查更新」的包故意没有检查器）；
2. `swiftc -O updater/UpdaterCore.swift updater/<name>.swift` 编译后运行；每包
   `timeout 600`（解释器模式会静默跳过顶层代码，不能用）；
3. 检查器从公式 / cask 文件读**本地版本**：优先顶层 `version` 行（跳过 `fails_with`
   块里的编译器版本），没有则从 `url` 行解析点分段版本（含 `-rc.1` 预发布后缀、8 位日期版）；
4. 取**上游版本**（五种来源，优先级 `customRelease` > `raw` > `github` > `brew`）：

| 流 | 版本判据 | url / sha 来源 | 典型 |
| --- | --- | --- | --- |
| `customRelease` | 检查器闭包调上游接口 / 页面 | 闭包返回 `UpstreamRelease`（sha 可空 → 核心下载实算） | workbuddy、dsh-gui、qwen-ime、openjdk、swift |
| `raw` | 源 tap 公式 raw 文本里的 `version` | GoReleaser 结构取 Intel 段（`rawDualArch` 则双段） | opencode、sst、torpedo |
| `github` | `releases/latest` 跳转的 `Location` tag（HEAD，不耗 API 限额） | 剥 `githubTagPrefix`（默认 `v`）后套 `downloadURL` 模板 | fzf、chisel、brewui、frida-server、交叉工具链 |
| `brew` 公式-模板式 | `api/formula/<brewName>.json` 的 `versions.stable` | 自己拼 `asset` / `downloadURL` / `checksumsURL` | gh、node 家族、fastfetch |
| `brew` 公式-全量式 | 同上 | JSON 的 `urls.stable.url` / `.checksum`（随 core 换镜像） | `fork-*`、qemu 链、ripgrep |
| `brew` cask | `api/cask/<brewName>.json` 的 `.version` | 必须自己给 x64 `downloadURL`（core 那份是 arm64），sha 实算 | zcode、lody |

5. 版本比较（等价 `sort -V`）：数字段按数值（`2026.8.19` == `2026.08.19`）、预发布 < 正式版；
   本地更新 → `newer-than-brew` 保持不动；`alwaysUpdate` 的包（konsole）版本相同也继续；
6. **HEAD 探测**目标 URL（双架构逐个）；不可下载 → `status=upstream-missing`，开
   `automated-alert` issue，不进更新清单；
7. 取 sha256：上游接口直接给 → `checksums.txt` 按 asset 精确匹配（~2KB）→ 下载整包实算；
   双架构产物没有清单，始终下载实算；
8. 改写（**内存里先自检，通过才落盘**）：
   - `url` 行：整条替换（镜像流 / 全量式 / 双架构 raw）或只替换版本子串（模板式，保留
     `#{version}`/`#{arch}` 插值）；`mirror` 行永远做版本子串 + `vX.Y/` 目录段同步；
   - 顶层 `version` 行（如有）同步；第一条 `sha256` 行替换；双架构按 key 改 `arm:`/`intel:`；
   - **摘除失效 `bottle do` 块**并发 `bottle_stale=true`（公式才需要，cask 无瓶）；
9. cask 走镜像（`uploadRelease: true`）：下载发布包 → 校验 sha → `gh release create
   <name>-<ver>`（资产名沿用上游 basename，空格 / 括号换点）→ url 改成本仓 Release →
   删除该 cask 的旧 Release（只认「前缀 + 数字开头」，避免 `lceda-` 误删 `lceda-pro-`）。

**为什么以 brew 为判据**（而不是上游最新 tag）：brew 收录了才说明有稳定的上游来源与
版本号语义；上游抢跑不会造成空转制瓶。GitHub / custom / raw 流是 brew 未收录、或需要
跟随特有发布节奏时的补充。

### 7.1 workflow 侧复核与提交

- 对更新过的文件跑 `ruby -c` 语法自检；
- 公式再过一遍 `brew fetch --force bemly/tahoe/<name>`（linuxbrew 先接 PATH，再
  `brew tap` + `brew trust`）——**url 与 sha 必须真能下载且一致**；失败者还原并剔除，
  不阻断其它包；
- `dry_run=true`：就地改写但不提交、不触发制瓶；
- 否则一次性 commit 到 `main`；
- 用**一次** `gh workflow run "Build bottle and publish to GHCR" -f formula="a,b,c"` 出瓶，
  **只传公式**（cask 混进 `brew install --build-bottle` 会直接红掉整个 job）。

即 N 个更新 = **1 次 watcher（ubuntu）+ 1 次 bottle（macOS）**，与更新数量无关。

### 7.2 状态契约

| status | 含义 | workflow 处理 |
| --- | --- | --- |
| `updated` | 已改写 | 语法 / fetch 复核后提交 |
| `up-to-date` | 本地 == 上游（或数值相等、字面不同） | 跳过 |
| `newer-than-brew` | 本地 > 上游 | 跳过（防回退） |
| `brew-missing` | brew 没有该包且未接其它流 | 跳过（需适配版本来源） |
| `upstream-missing` | 新版本资源 HEAD 不可达 | 还原 + 开 issue |
| `check-failed` | 接口 / 网络故障 | 还原 + 公示，下次自动恢复 |
| （无 status） | 崩溃 / 自检 fail | 还原 + 公示，**绝不当成无需更新** |

## 8. GHCR 瓶策略

### 8.1 定位

`url`（上游预构建包直链）只是**制瓶的原料**，分发走 GHCR 瓶：

- 安装走 Homebrew 原生瓶机制，不依赖 GitHub Releases；
- 上游万一改名/删档，GHCR 里还留着一份；
- **不重新编译** —— 瓶的内容就是把上游预构建包拆进 Cellar 再打包。
- **瓶只含本体，不含依赖**：GHCR 里每个 tag 只是该公式自己的 Cellar 内容。
  公式若需要依赖，依赖也必须在本仓 `Formula/` 里出瓶，并以全名
  `bemly/tahoe/<name>` 引用；**不能指望 core 的瓶**——core 在 Intel Tahoe 不出瓶，
  裸名依赖会回落到 core，并在用户端现场源码编译（graphviz 16.1.1 实测，见 11.59）。
  这与第 6 节 hub/叶子分流并不矛盾：hub 留 core 是历史妥协，新增/更新公式应把所需依赖
  一并入源并指全名，才能兑现「用户端不编译」的承诺。

### 8.2 地址

```ruby
bottle do
  root_url "https://ghcr.io/v2/bemly/tahoe"
  sha256 cellar: :any_skip_relocation, tahoe: "<由 bottle.yml 生成>"
end
```

依据（源码 `Homebrew::GitHubPackages.root_url`）：

```ruby
root_url(org, repo) = "https://ghcr.io/v2/#{org}/#{repo.delete_prefix("homebrew-")}"
```

所以 `bemly/homebrew-tahoe` → **去掉 `homebrew-` 前缀** → `ghcr.io/v2/bemly/tahoe`
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
  `ln -sfn "$GITHUB_WORKSPACE" <Taps>/bemly/homebrew-tahoe`。
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
  （`DELETE users/{owner}/packages/container/tahoe%2F<name>`），让
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

目标：把一个新软件做成「用户 `brew install bemly/tahoe/<name>` 时直接命中 GHCR 瓶」的状态。
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

5. 新建 `updater/<name>.swift`（与 `Formula/<name>.rb` / `Casks/<name>.rb` 同名，一一对应），
   按版本来源选模板（每种都有现成例子，直接照抄改配置）：
   - **brew 流-模板式**（软件在 homebrew/core，且能自己拼产物地址）：照抄 `gh.swift`，
     改 `formula` / `brewName` / `asset` / `downloadURL` / `checksumsURL`
     （上游无 checksums 文件则置 `nil`，核心自动回退下载计算）；
   - **brew 流-全量式**（qemu 链 / `fork-*` / ripgrep 这类从 core 拷入、url 模板不好推）：
     只需 `CheckConfig(formula: "<name>", brewName: "<name>")`，url 与 sha256 由核心直取
     JSON 的 `urls.stable.url` / `.checksum`，上游换镜像自动跟随（见 6.2 / 6.3；模板式仍优先）；
   - **brew cask 流**（软件在 core 里是 cask，如 zcode / lody）：
     `formulaPath: "Casks"` + `isCask: true` + `brewName: ...` + `brewCask: true`；
     **必须自己给 x64 `downloadURL` 模板**（core 的 url 是 arm64 的），sha 由核心实算；
   - **raw 流**（软件来自其他 tap 仓库，如 `anomalyco/homebrew-tap` 的三包）：
     照抄 `opencode.swift`，只配 `formula` + `rawFormulaURL`（源公式 raw 地址），
     核心按 GoReleaser 结构解析 version + Intel mac 的 url/sha256；
     要双架构再加 `rawDualArch: true`，核心解析双块、改写双 `if Hardware::CPU` 块（见 11.27）；
   - **github 流**（brew 未收录、又无自有接口，如 fzf / chisel / brewui / 交叉工具链）：
     配 `githubRepo`（`Owner/Repo`）+ `downloadURL` 模板，可选 `githubTagPrefix`
     （默认 `v`，无前缀设 `""`）；版本取 `releases/latest` 跳转 tag，不耗 API 限额；
   - **自定义流**（上游自有更新接口）：照抄 `workbuddy.swift`，实现 `customRelease` 闭包，
     返回 `UpstreamRelease(version:downloadURL:sha256:)`（sha 仅在实测确认归属时才给，
     否则置 nil 由核心下载实算）；
   - **双架构产物**（上游按架构分包的 cask，如 zcode / konsole）：在版本来源
     （brewCask / customRelease 任选其一）之外再配 `archArtifacts: [token]` +
     `downloadURLForArch: (version, arch) -> url`，核心走双分支（逐个探测下载、
     各算各的 sha，改写 version + `sha256 arm:/intel:` 行；url 行不动）。
     镜像一律开 `uploadRelease: true`（本 tap 政策：所有 cask 都镜像最新版，
     见 11.34）：tag `<name>-<ver>`、资产名沿用上游 basename（空格换点，
     见 11.34）、旧快照自动清理。
     token→key 由核心 `caskArchKey` 显式映射，未知 token 直接 fail。
   - **浮动直链 / 版本号不变的上游**：加 `alwaysUpdate: true`（konsole 是例子）。
   - **补丁成品 cask**（antigravity / github-copilot-app，破例见 1 节）：产物不是「下载上游
     再镜像」，而是 `Widgets/<pkg>/build.sh` 在官方 Intel 包上打补丁后重打的 dmg，由
     **`patched.yml` 在 CI 构建并上传**。检查器走 `customRelease`（core cask API 判新 +
     拼 `-cn<N>`）、sha 取 Release 上的 `.sha256` sidecar、**不开 `uploadRelease`**；
     sidecar 缺失即返回 `sha256: nil` → 核心 HEAD 探测 404 → `upstream-missing` 开 issue
     （= 「该跑构建了」走既有告警通道）。cask 的 sha 可先写占位 `PENDING_CI_SIDECAR`，
     由 workflow 用本次 sidecar 填实、lint 绿后提交（见 11.61 第 9 条 / 11.62 第 9 条）。
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
     --repo bemly/homebrew-tahoe \
     -f formula=<name>
   ```

   `formula` 入参支持：`gh`（单）、`gh,fastfetch`（逗号多，一次出多个瓶）、`all`（遍历全部）。
   多软件场景优先用逗号列表或 `all`，只占一次 macOS runner（见 5.1）。

10. **阻塞等到跑完**（必须看到 `✓ Complete job` 再继续）：

    ```bash
    RUN_ID=$(gh run list --repo bemly/homebrew-tahoe --limit 1 \
              --json databaseId --jq '.[0].databaseId')
    gh run watch "$RUN_ID" --repo bemly/homebrew-tahoe
    ```

    注意：

    - repository 名是 `bemly/homebrew-tahoe`（带 `homebrew-` 前缀），不是 tap 名 `bemly/tahoe`；
    - 该 workflow 会依次：软链并信任 tap → build-bottle 安装 → 制瓶 → 删旧 GHCR 标签（支持重复运行覆盖）
      → 推 GHCR → 尝试设公开 → **把瓶块 commit 回公式**。

### 9.7 让本机也换成 GHCR 瓶版（而不是直链）

11. 制瓶完成后，远端公式已带 `bottle do` 块。本机先把这次提交拉下来，再重装，让它走 GHCR 瓶：

    ```bash
    git pull --ff-only origin main
    brew reinstall bemly/tahoe/<name>
    ```

    成功标志：日志出现
    `Downloading https://ghcr.io/v2/bemly/tahoe/<name>/manifests/<ver>`
    与 `Pouring <name>--<ver>.tahoe.bottle.tar.gz`。

12. 校验：`brew info bemly/tahoe/<name>` 显示 `stable <ver> (bottled)`，
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
brew tap bemly/tahoe /Users/bemly/Projects/tahoe

brew info      bemly/tahoe/gh      # 看解析结果
brew style     bemly/tahoe/gh      # RuboCop 规范
brew audit --strict bemly/tahoe/gh # 公式审计
brew fetch     bemly/tahoe/gh      # 验证 url + sha256 可下载且一致
brew install   bemly/tahoe/gh      # 真装一遍，验证 pre/post 脚本
brew test      bemly/tahoe/gh      # 跑 test do
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
but you are trying to install it from the bemly/tahoe tap.
Formulae with the same name from different taps cannot be installed at the same time.
```

用户必须先 `brew uninstall gh`（core 版），才能装本 tap 的版本。

### 11.5 本地开发：tap 目录要用软链接

`brew tap bemly/tahoe <本地路径>` 是 **clone，不是 symlink**，
改了本地文件 brew 读不到，会一直报旧错误。开发时换成软链接：

```bash
rm -rf /usr/local/Homebrew/Library/Taps/bemly/homebrew-tahoe
ln -s /Users/bemly/Projects/tahoe /usr/local/Homebrew/Library/Taps/bemly/homebrew-tahoe
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
   必须出现 `ghcr.io/v2/bemly/tahoe/<name>/manifests/...`
   与 `Pouring <name>--<ver>.tahoe.bottle.tar.gz` 才算真正换瓶成功。
3. 触发用 `gh workflow run ... --repo bemly/homebrew-tahoe`
   （带 `homebrew-` 前缀的**仓库名**），不是 tap 名 `bemly/tahoe`。

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
   `tahoe%2Fnode`（`node@22` → `tahoe%2Fnode%2F22`），
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
4. **依赖必须先制瓶**。`depends_on "bemly/tahoe/ripgrep"` 全限定名强制走自家
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
4. **同是 darwin-amd64 尾缀，go 会致盲而 buildx 不会**：`go1.27.1.darwin-amd64`
   被扫成 `"64"`（显式 version 才过），`buildx-v0.37.0.darwin-amd64` 却能扫对——
   差在有无 `v` 前缀/版本号位置等细节，规律不可靠。结论不变：是否显式声明
   一律以 `audit --strict` + `brew info` 显示的 stable 为准（go 是 node 之后的
   第二个显式声明例）。
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

### 11.26 双架构产物分支 + url 改写语义修正（2026-09-04 实测，zcode 双架构化）

1. **UpdaterCore 新增双架构维度**（版本来源正交）：`archArtifacts: [token]`
   + `downloadURLForArch: (version, arch) -> url`，置上即走 `runDualArchCheck`
   （逐个 HEAD 探测 → 下载实算 → 改写 version 行 + `sha256 arm:/intel:` 行；
   url 行不动，`#{version}/#{arch}` 插值已覆盖新版本）。token→key 由
   `caskArchKey` 显式映射（未知 token 直接 fail，绝不静默错配）；双产物无
   checksums 模板（有更新逐个实算）。【2026-09-05 修正：本条末句已作废——
   双架构 + 镜像完全可用（konsole 一直这么跑，zcode 本轮也切过来了），
   组合语义见 11.34；"fail 明示" 的说法无代码对应，切勿再信。】
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

### 11.27 opencode 双架构：摘 arch 门槛的例外（2026-09-04 实测）

1. 本 tap 唯一摘 `arch` 门槛的公式：`opencode`（加回 `darwin-arm64` 段，主段放
   顶层、ARM 段在 `on_macos` 内 `if Hardware::CPU.arm?` 覆盖）+ 它的依赖 `ripgrep`
   （ARM 装 opencode 会依赖到它，不摘则 ARM 直接被拒；ripgrep 是源码编译，
   ARM 上现编即可）。`macos: :tahoe` 门槛保留。sst/torpedo 暂不动（同系列但
   无人要 ARM 版，要了再按此套路加）。
   **顶层必须留 Intel 段**：初版把双段全塞进 `on_macos`，`brew readall` 在
   Linux 下直接 `requires at least a URL` 红掉制瓶（`on_macos` 包不住 Linux，
   顶层无 url 即非法——GoReleaser 源文件同病，只是人家不跑 readall）。
   改写规则同步调整：顶层 url/sha 归 intel 槽，arm 块归 arm 槽。
2. 瓶仍只有 x86_64（macos-26-intel 制出，无 ARM runner 可出 arm 瓶）——ARM 安装
   回退上游直链（同版本 arm64 包，无需制瓶）。公式只改门槛/加段、不动安装产物
   时，旧瓶继续有效，不必重制（本次即如此）。
3. 检查器走 raw 双架构分支（`rawDualArch: true`）：`parseGoReleaserRawDual`
   取双块 url/sha，`rewriteFormulaRawDual` 按缩进判定块作用域改写双块
   （块内 `def install...end` 缩进更深，不会误出块；找不到对应行直接 fail）。
   双改写的端到端验证靠 harness（假版本号调纯函数，看双块替换 + 摘瓶）。
   ——上线当天上游就发了 1.18.28，检查器真链路一次跑通（双段 url/sha 与源文件
   逐字节一致、摘瓶、emit 全对），比 harness 更硬的 proof，没有之一。
4. ARM 侧无法在本机验证（无 ARM 硬件）：arm 段 url/sha 与源文件逐字节核对 +
   结构照抄源文件；`post_install`/`test` 用 `Hardware::CPU.arm?` 双分支，
   Intel 侧全绿即发。
    ——后续用户在 ARM Mac mini（macOS 27）上实测通过：arm64 段走直链 2 秒装完、
    `post_install` 架构校验过；代价是 ripgrep 无 arm 瓶、源码编译一次性拉起
    13 个编译期依赖（rust/llvm/ruby 三栈约 2.5GB，见下）。

### 11.28 audit 强制要镜像；镜像行必须同步改写（2026-09-05 实测）

1. `audit --strict` 对这批代编译公式报 `Stable: Should always include at least one
   HTTP mirror`（直接套 gh 模板不写 mirror 的在 core 拷入公式上过不了）——
   结论：core 拷入的公式**镜像行必须保留**（只留点分段格式的，下条解释）。
2. 但 watcher 原来只改写第一条 url 行，镜像会留旧版本 → 本次给
   `UpdaterCore.rewriteFormula` 加了镜像同步：非镜像流下所有 `mirror "` 行
   同做旧版本号子串替换（点分段格式才命中）。
3. curl3 是例外：core 的 GitHub 镜像 tag 用下划线（`curl-8_22_0`），子串替换
   够不着——只留 fresh-center 两行（点分段），GitHub 镜像行不保留；
   install 里 core 那段 `stable.mirrors` tag 校验同步删除（无镜像可检）。

### 11.29 版本解析两则：fails_with 块与 github 跳转（2026-09-05 实测）

1. **`fails_with` 块内的 version 不是公式版本**。nghttp2 的
   `fails_with :gcc do version "13"` 被 `currentVersion` 的全文件正则命中，
   本地版本误解析成 `13` → 恒判 newer-than-brew 静默跳过。修法：
   `currentVersion` 改逐行扫描，跳过 `fails_with...do/end` 块内的 version 行
   （protobuf 的 `version "12"` 同病，一并覆盖；已有公式无此结构，回归全绿）。
2. **github 流只认 `/tag/` 跳转**。rust-lang/rustup 的 `releases/latest` 跳到
   `/releases` 列表页（末段 "releases"），旧逻辑取末段即得垃圾版本 → 误报
   upstream-missing。修法：`githubLatestTag` 只接受含 `/tag/` 的 Location，
   否则继续重试直至 check-failed 明示。rustup-init 改走官方自更新通道清单
   `release-stable.toml`（`version = 'x.y.z'`，单引号）做 customRelease，
   原料取版本化归档 `/archive/<ver>/...`（不用 floating 的 dist 直链）。

### 11.30 沙箱网络与单测三则（2026-09-05 实测）

1. **socat 公网用例沙箱必挂**：本机出口经 MITM 代理（TCP 建连被接到
   198.18.x 后无回包），core 的 `tcp:www.google.com:80` 用例 hang 到
   `Timeout.timeout`。改走本机回环（`TCP-LISTEN` + `EXEC:cat` 回显断言往返），
   不依赖公网，CI/本地双绿。教训：单测涉网一律回环。
2. **curl 的 H3 连通性用例同样**：沙箱禁 UDP，`--http3-only` 冲 cloudflare
   秒挂（exit 7）。改成存在性断言（`--help all` 含 `proxy-http3` +
   `curl-config --features` 含 HTTP3）致命、连通性 `begin/rescue` 只告警——
   CI 干净网络下真跑，沙箱下不红。
3. **新版裸 `--help` 只打分类列表**：curl 8.22 的 `--help` 输出 23 行分类，
   查选项必须 `--help all`（`proxy-http3` 在 all 里）；hyperfine 1.20 输出
   改版（`Time (mean ± σ)`），test 只锁 `Benchmark 1` 这种稳定锚点。

### 11.31 本轮链路备忘（curl3 栈 / iperf3 / wireshark）

1. **libnghttp2 是枢纽（扇入 19：node 家族/curl/wget2…），不能自瓶**：
   初版照抄进 tap，装完才发现 bare 依赖永远解析到 core、自家瓶永用不上——
   已删公式+检查器+本地 keg，nghttp2/curl3 的 `libnghttp2` 保持裸名（core
   源码现编约 30 秒，一次性）。`brew uses --eval-all` 是分流判据，
   不要凭感觉（libnghttp3 扇入 5、libngtcp2 扇入 4，叶子自瓶保留）。
2. **`--enable-proxy-http3` 真实存在**：curl 官方 EXPERIMENTAL.md 明确要
   autotools 传该开关（CMake 传 `-DUSE_PROXY_HTTP3=ON`）才有
   `--proxy-http3`/CONNECT-UDP，core 没开——这就是 curl3 相对 core 的实质
   改动（改名只是避冲突）。test 用 `--help all` 断言存在性。
3. **iperf3 资产名后缀跟 runner 走**：3.20 及之前是 `iperf3-amd64-osx-13`，
   3.21 变成 `osx-15`。检查器 customRelease：版本走 brew stable，
   `expanded_assets/<ver>` 片段抓 `iperf3-amd64-osx-NN` 取最大世代；
   静态仓滞后（片段 404）则回退猜 `osx-15`，由核心 HEAD 探测报
   upstream-missing（ffprobe 同例）。公式 install 用
   `Dir["iperf3-amd64-osx-*"]` 通配，不写死后缀。
4. **wireshark Intel 停在 4.4 系**：4.6+ 无 Intel dmg，版本不能跟 brew
   （core stable 4.6.8）。检查器走官方 Sparkle appcast，取 enclosure url
   含 `Intel%2064.dmg` 的项：版本取 `shortVersionString`，sha 取同项注释
   的官方值（免 66MB 实算）；enclosure 的 dl 镜像 host 归一化到 www 主站
   同路径（实测同文件，content-length 一致）。

### 11.32 rustup 命名三连跳：别名全局生效，同名接管才是正解（2026-09-05 实测）

1. **core 的改名别名是全局的**。core 曾把 `rustup-init` 改名成 `rustup`，
   这个 old→new 映射对所有 tap 生效——本 tap 建 `rustup-init.rb` 当天，
   任何操作都报 `old name rustup-init was installed from bemly/tahoe`
   并要求 `brew migrate`。结论：公式名**绝不能撞 core 的改名别名**，
   查名时连旧名一起查，不只查现名。
2. **改名 rustup-bin 是错的**（已 revert）：本 tap 定位是 x64 备用源，
   命名应与上游保持一致。正解是与 core **同名 `rustup`**（标准同名流程：
   先卸 core 版再装本 tap 版），rustup-init 只是上游发布物的文件名，
   不是公式名——它和 rustup 是同一个二进制（argv[0] 决定行为），
   不是谁依赖谁。
3. **完整接管形态**：公式装 `rustup` + 照抄 core 的 cargo/rustc 代理垫片；
   本机卸 core `rust`/`rustup`（事先 `brew uses --installed` 确认无依赖链），
   工具链改走 `rustup toolchain install stable`（`~/.rustup`，与 brew 无关）。
   附带效果：autoremove 顺手清掉 core rust 拉来的 llvm@22（1.6GB）。
   约束写进 caveats：升级走 brew，勿 `rustup self update`（静态包自带该功能，
   会绕开 brew 改 Cellar）。

### 11.33 curl3 纯客户端化 + 同版本改布局必须源码重装（2026-09-05 实测）

1. **公式名改了，二进制名也要跟上**。初版 curl3 装的还是 `bin/curl`
   （且 keg-only 未 link），用户敲 `curl3` 直接 command not found——
   改名避冲突只做一半等于没做。修法：install 里 `mv bin/curl → bin/curl3`
  （man 页同步），wcurl 的 CMD 指到 `opt_bin/curl3`，test 全换 `bin/"curl3"`。
2. **link 出来的头文件撞 macOS SDK**：macOS SDK 自带 `usr/include/curl/*.h`，
   去掉 keg-only 正常 link 后 audit 报 shadowing。修法：`--disable-shared`
   纯客户端形态——二进制静态链接 libcurl 自包含，开发件
   （include/curl-config/pkgconfig/man3）全部裁掉；互操作测试只要客户端，
   不需要 lib。注意 `rm_rf` 被 style 禁，用 `rm_r`（+ exist? 守卫）。
3. **同版本改 install 布局，`brew reinstall` 会倒回旧瓶**：版本号没变 +
   瓶块 sha 有效 → brew 直接倒旧瓶，新布局根本不生效（本地一度"修了个寂寞"：
   bin/curl3 不存在、头文件又回来了）。验证布局改动必须
   `brew install --build-from-source`；GHCR 侧靠重跑 bottle 覆盖。

### 11.34 全 cask 镜像政策 + 空格资产名坑（2026-09-05 定稿，硬规则）

**政策（用户拍板，此后所有 cask 无例外）**：11 个 cask 全部把最新版镜像到
本仓 GitHub Release（tag `<name>-<ver>`，资产名沿用上游 basename），cask
url 一律指本仓 Release；上游直引只做新收录时的过渡，首轮即镜像。
旧政策（"链接稳定的直引即可，如 zcode/brewui"）已废弃。pinned 不检查更新
的 cask（checkra1n/palera1n/macos-tskmgr/heliport/winstart）同样镜像当前
锁定版——只是没有检查器，靠人工重做（下载→核 sha→传 Release→改 url）。
winstart 早就是这个形态（无公开链接，只能如此）。

1. **GitHub 存资产时把空格换成点**：`checkra1n beta 0.12.4.dmg` 存成
   `checkra1n.beta.0.12.4.dmg`，`Wireshark 4.4.18 Intel 64.dmg` 存成
   `Wireshark.4.4.18.Intel.64.dmg`——cask url 照抄直引的 `%20` 形态必 404
   （本轮 checkra1n/wireshark 双双中招，`fetch --cask` 现形）。
   修法：cask url 写点分隔形态；`UpdaterCore` 单/双架构两条上传链路同步做
   `空格→点` 替换（`%20` 先解码，wireshark 的 appcast 直链是编码形态），
   上传用名与 finalURL 保持一致。
2. **zcode 顺手真升了一次**：翻镜像开关后跑检查器，正撞上游 3.10.2→3.11.2，
   双包下载实算、上传 `zcode-3.11.2`、改写 version + 双 sha、旧 release
   自动清理——双架构 + 镜像全链路一次跑通，比摆拍更硬的 proof。
3. **旧 release 只留最新**：沿用 workbuddy 机制（`deleteOldCaskReleases`），
   每个 cask 的 Release 永远只有一个，11 个 cask 对 11 个 release。

### 11.35 wireshark 不装 ChmodBPF 就抓不了包（2026-09-05 实测）

1. 现象：`tshark -D` 能列接口（列接口不要权限），但一抓就
   `cannot open BPF device /dev/bpf0: Permission denied`——`/dev/bpf*`
   默认 `root:wheel 600`，且根本没有 `access_bpf` 组，本 tap 首版 cask
   只装了 app，权限链是断的。
2. 修法：cask 加 `pkg "Install ChmodBPF.pkg"`（同 dmg 内的官方包，已拆包
   验过 postinstall 实物：建 `access_bpf` 组、把 admin 组 + 当前用户加进去、
   装 LaunchDaemon 开机改 bpf 设备组归属）+ `uninstall` 配
   `launchctl`/`pkgutil` + caveats。装 pkg 要弹密码（写 `/Library`），
   属正常行为。非交互装可用 `SUDO_ASKPASS` 喂密码跑通
   （`brew reinstall --cask` 全程无人值守实测）。
3. **"注销重登"是错的，当场推翻**：原以为组身份要重新登录才生效，实测
   旧 shell（组建好之前就开着的）装完直接抓到包——macOS 对本地组成员的
   判定是动态查目录服务的（且 postinstall 把 admin 组整个拉进
   access_bpf，admin 用户天然命中），daemon 一 bootstrap 改完
   `/dev/bpf*` 归属即全会话生效。官方当年"不用重登"不是运气，是机制如此；
   本 tap 首版 caveats 照抄 classical Unix 经验写错了，已订正。
   附加：sudo 下 postinstall 的 `$USER` 未必是你本人，装完顺手显式补一次
   `sudo dseditgroup -o edit -a <你> -t user access_bpf` 最稳（幂等）；
   非 admin 用户同样靠这条手动进组，进组即生效，也不用重登。

### 11.36 tap 改名 tahoe-intel → tahoe（2026-09-05 实测）

1. 仓库 `bemly/homebrew-tahoe-intel` → `bemly/homebrew-tahoe`（`homebrew-`
   前缀是 brew 强制的，去不得），tap 名随之 `bemly/tahoe`；GHCR root_url 按
   `repo.delete_prefix("homebrew-")` 推导 → `ghcr.io/v2/bemly/tahoe`。全仓
   `tahoe-intel` → `tahoe` 子串替换一次覆盖（`macos-26-intel`/`x86_64_tahoe`
   不含该子串不受影响，改前 grep 确认过）。
2. **仓库改名不会搬 GHCR 包**：旧包仍叫 `tahoe-intel/<name>`，新 root_url 下
   全是新包。瓶迁移不重制——临时 workflow（ubuntu + `crane copy`）逐包逐 tag
   原样搬运，manifest/blob digest 不变 → 公式瓶块只改 root_url 行、sha256
   原样有效，零 macOS runner（40 个 tag 一次跑完约 4 分钟；从未出瓶的 go
   自动跳过）。
3. 新包可见性：11.14 的结论对**新建包名**同样成立——CI 里 GITHUB_TOKEN 推的
   包默认公开，迁移后匿名逐包体检 40/40 全过，无需手动改 Public。
4. 本机迁移：`brew tap-rename` 在 brew 6.0.21 **不存在**（只有 `tap-new`）。
   手动三步：`git remote set-url`；`mv Taps/bemly/homebrew-tahoe-intel
   homebrew-tahoe`（软链改名，目标目录不动）；`grep -rl` 找出 Cellar 里所有
   含旧名的 `INSTALL_RECEIPT.json` sed 改写（89 个，含 runtime_dependencies
   全名）。末了 `brew readall bemly/tahoe` + `brew fetch --bottle-tag=tahoe`
   验证（✔︎ Manifest + ✔︎ Bottle 即成功，见 11.10）。
5. 旧包 `tahoe-intel/*` 迁移后成冗余副本，手动删：
   `gh api -X DELETE users/bemly/packages/container/tahoe-intel%2F<name>`
   （`@` 同 `/` 都要编码成 `%2F`）；改名后的仓库地址 GitHub 会 301 重定向，
   外部用户须重新 `brew tap bemly/tahoe`。
6. **tap 信任按 tap 名记账，改名即失效**：本机重装时报
   `Refusing to load formula ... from untrusted tap bemly/tahoe`，且会烧在
   「别的公式」上（依赖闭包/收尾阶段扫到未信任公式，重装目标本身已信任也
   exit≠0）。修法就一句 `brew trust bemly/tahoe`；CI 不受影响（bottle.yml
   本来就有 trust 步骤）。同轮实测：本机 39 个公式重装全部命中新 GHCR 瓶；
   node 家族三条共抢 bin/node|npm|npx|corepack 四个链接，重装会把归属抢成
   最后重装的那个——装完按原状 `brew unlink` + `brew link --overwrite node`
   + corepack 单独指回 node@22 恢复。另：graphviz 重装会经 core API 漂移
   拉进 netpbm（其源码要 svn 检出，本机 subversion 未 link 时报
   "You must: brew install svn"），与改名无关但同场发生。

### 11.37 frida-server 三连坑：post_install 废弃 / xz 无执行位 / WXwindows 已废弃（2026-09-06 实测）

1. **brew 6 的 `post_install` 已废弃，新公式一律改声明式 `post_install_steps`**：
   style cop `FormulaAudit/InstallSteps` 直接拒绝 `def post_install`；且新 DSL
   是纯声明式（模板 token + `if_path_exists` 守卫，step 可序列化进 JSON API），
   跑不了 `safe_popen_read` + `odie` 这类断言——校验逻辑挪进 `install` 尾部
   （`file(1)`/版本自检照跑不误）。旧公式的 `def post_install` 运行时只发
   odeprecated 警告还能用，CI 只做 `ruby -c` 不受影响；哪天全量 style 跑红再统一迁移。
2. **xz 解出的文件没有执行位**：上游打 xz 时原文件就是 644，而 brew 的
   `bin.install` 按源文件 exec 位决定 0555/0444——非可执行文件装成 0444，
   install 里执行它报 `Permission denied`（经 safe_popen_read 只看到莫名其妙的
   "exited with 1"，埋点抓 sh 的 EXIT=126 才现形）。修法：install 里
   `chmod 0555`。tar/zip 内的二进制自带 +x，gh/mufetch/ffmpeg 都没踩过，xz 是首例。
3. **`license "WXwindows"` 已被 SPDX 废弃**，audit --strict 拒收。正确写法是
   例外表达式 hash 形态：`license "LGPL-2.1-only" => { with: "WxWindows-exception-3.1" }`
   （照抄 core wxwidgets 的 DSL 用法；frida 根 COPYING 即 wxWindows 3.1）。
4. frida 版本判据：不在 core，走 github 流（`githubRepo: "frida/frida"`，tag 无
   v 前缀显式置 `githubTagPrefix: ""`）。版本化直链的 HEAD 探测可过
   （302 对 `curl -fsI` 是 exit 0）。URL 里版本出现两处（tag 目录 + 文件名），
   版本子串替换一次全换。二进制仅链系统库（Foundation/AppKit/libSystem），零依赖。

### 11.38 bottle 传参混入 cask + fish 残 URL + dsh 预发布三连修（2026-09-09 实测）

1. **watch 传了全量名单，bottle 被 cask 带崩**：`watch-updates.yml` 算对了
   `updated_formulae`（仅公式）却传 `$list`（含 cask）触发制瓶；`bottle.yml`
   按字母排序首个撞上 `brewui` → `No available formula` 整 job 红，
   同批的 fish/opencode 根本没轮到（`34337810851` 实测）。
   修法：触发时传 `updated_formulae` 拼的 `formula_list`。教训：watch 与 bottle
   之间传的名单必须按"公式/cask"分流——cask 无 bottle 机制，名字进 bottle
   就是非法输入，不存在"跳过 cask 继续"的语义。
2. **版本号边界 `(?![0-9.])` 误杀 `.ext` 后缀**：`fish-4.9.0.app.zip` 里版本号后
   紧跟 `.app` 的点，被当成"更长点分段版本"跳过 → 只换路径段、不换文件名，
   提交 `.../4.9.3/fish-4.9.0.app.zip` 残 URL（404，且旧瓶块已被摘，fish 当场
   装不了）。fish 是全仓首个"版本后直接跟 `.ext`"的包（gh/node 的版本后都是
   `_`/`-`，故此前无事）。修法：前瞻改为 `(?![0-9]|\.[0-9])`——只挡数字与
   `.数字`（真续段如 2.88.3 里的 2.88），裸点（`.app`/`.tgz`/`.darwin`）放行；
   go（`go1.27.1.darwin-amd64`）与 npm 包（`dsh-0.1.1-rc.2.tgz`）同病一并治愈。
   另：fish 4.9.3 的 sha 也连带错了——watcher 写入的 `20998a…` 与半小时后实测的
   `3619fa…`（curl 与 brew fetch 双重独立下载一致）不符，上游在 watcher 跑完后
   重切了同版本包（11.24 的 gh 旧事重演）。按 11.24 三方一致原则独立复算后修正，
   教训：URL 修完必须 `brew fetch` 端到端验 sha，不能默认 watcher 的值还有效。
3. **改后自检的插值判定必须限定 url 行**：旧 `全文件 contains "#{version}"`
   会命中 fish.rb pre/post_install 里无关的 Ruby `#{version}` 插值，让残 URL
   空过自检（fail 本可拦下）。现只认 url 定义行含插值。
4. **dsh 接入检查器（npm `latest` 流，首个全预发布版本号软件）**：
   跟 `latest` dist-tag 文档（`registry.npmjs.org/@deepseek-ai/dsh/latest`，
   version + dist.tarball 一次拿全，sha 回退下载实算），alpha 不追。
   配套两处核心改动：`currentVersion` 的 url 回退解析带预发布后缀（关键词限定
   `preview|alpha|beta|canary|rc|pre|dev|next`，平台后缀 `-darwin`/`-x86_64`
   不吞——否则旧版本只是文件名的前缀，改写出 `dsh-0.1.2-rc.1-rc.2.tgz`）；
   `compareVersions` 里带 `-后缀` 的段小于裸段（rc→final 不丢更新，纯字符串
   比较会判 "2-rc" > "2" 而永久卡在 rc）。另：`customRelease` 取不到版本时由
   `fail()`（静默跳过）改为发 `status=check-failed` 明示（11.23 同例）。

### 11.39 watcher 错 sha + 残 URL + 依赖排序三连修（2026-09-16 实测，35080405631 红）

1. **brew JSON 的 checksum 属于源码 tarball，模板流用了就是错 sha**：
   `UpdaterCore` 原来把 `urls.stable.checksum` 无条件当 hint——对全量式
   （qemu 链：url 与 checksum 同属 core 源码包）是对的，但模板式
   （gh/node/docker-buildx：url 是各资产模板，checksum 仍是源码包的）写进去
   就是错 sha，制瓶 fetch 即 `reports different checksum`（node 26.8.2 的
   `36b37b…` 实为 `node-v26.8.2.tar.xz` 的，darwin 包实为 `adb8fe…`；
   gh `a266fe…` 实为源码包的，zip 实为 `a6fd66…`；buildx `c8eb34…` 同理）。
   修法：hint 只给全量式（`downloadURL == nil` 才取）；模板式走 checksums
   清单（gh/node 的 SHASUMS 精确匹配）或下载实算（buildx/frida/dsh）。
   三方一致（清单/实物/公式）逐个复算后修正，`brew fetch` 全绿才提交。
2. **全量式的 url 是不透明直链，版本子串替换必写残**：graphviz 16.0.0→16.1.0
   只换了路径段（`…/16.1.0/graphviz-15.1.1.tar.xz` → 404），文件名里的旧版本
   没换——旧逻辑只做子串替换，而 JSON 给的直链文件名与路径版本号脱节
   （core 的 15.1.1 包是从 16.0.0 目录拷的？总之文件名≠目录版本）。
   修法：全量式（无 downloadURL 模板）改整条换 url；镜像行同步改写不再豁免
   镜像流（cask 无 mirror 行，天然空转）。graphviz url 补全文件名 + sha
   （`0f6617…` 经下载复算与 JSON 一致）后 `brew fetch` 通过。
3. **残 URL 静默进了 main**：graphviz 自检 `url 未成功更新` fail 直接 exit 1，
   无 status 行 → watch 脚本落进 else 分支打了句"无需更新" → 坏文件照常提交。
   修法三层：① 单/双架构/raw 双架构三条链路全部**先验后写**（自检在内存里过
   才落盘，fail 时文件保持原样）；② watch 脚本无 status 即视为失败、
   还原文件记入 failed（绝不当"无需更新"）；③ 提交前 `brew fetch --force`
   端到端验 url+sha（只验直链，瓶块已摘），失败还原剔除、不阻断其它包。
4. **依赖必须先制瓶**：`deepseek-harness → node`、`opencode → ripgrep`
   （字母序 `deepseek-harness < node`、`opencode < ripgrep`，排序不处理必反）。
   本次 deepseek-harness 首个处理，node 无瓶走源码编译直接失败
   （`cannot be installed from bottle... node`）。修法：bottle 循环前按
   `depends_on "bemly/tahoe/X"` 纯 bash 拓扑排序（bash 3.2 无关联数组，
   多轮扫描；python 内嵌块会碎 YAML，已废弃），本批之外依赖视为已满足。
   本轮 8 包（node,node@24,gh,docker-buildx,graphviz,frida,deepseek,opencode）
   按 `docker-buildx,frida-server,gh,graphviz,node,node@24,opencode,deepseek-harness`
   顺序 21 分钟全绿（含 graphviz 现编）。
5. **附带**：bottle.yml 的 python 拓扑首版直接碎 YAML（push 即 invalid，
   多行 `python3 -c` 缩进与 YAML 冲突）——CI 内嵌脚本只用 bash，复杂逻辑放
   Swift/脚本文件里，不要 inline python。

### 11.40 brew 7 起 cask 禁止命令式 flight + arm64 首包实录（2026-10-05 实测，afm）

1. **本机 brew 7.0.1→7.0.7 自动更新后新增 `Cask/InstallSteps` cop**：`preflight do` /
   `postflight do` 一律判 offense，必须改声明式 `preflight_steps` / `postflight_steps`
   （公式侧 `post_install` → `post_install_steps` 是同款，见 11.37）。连带后果：
   存量 `doubao-ime.rb`（preflight + postflight 双块）现已 style 红——运行时不受影响，
   属 lint 腐化（11.25 同例）；动它有回归风险，本轮未改，新文件只保证自己绿。
2. **steps 块内只能写 DSL 调用**（`run` / `set_permissions` / `terminate_process` /
   `write_file` 等，Ruby 逻辑一律不许）：afm 的"读输入源判重再 array-add"无法直写，
   包一层 `run "/bin/sh", args: ["-c", "defaults read ... | grep -q ... || defaults write ..."]`
   保持幂等（array-add 非幂等，无条件跑会重复追加）。`defaults` 落盘要写
   `~/Library/Preferences`，run 步须显式声明 `writable_paths` + `writable_base: :home`
   （sandbox 否则拦截）；`must_succeed: false` 是故意的——无 GUI 会话下 cfprefsd
   不可达时安装仍成功，仅输入源需手动加。`chmod -R u+w` 对应
   `set_permissions <path>, "u+w", base: :home`（默认递归）；三个 killall 对应
   `terminate_process`（默认 `must_succeed: false`，进程不在不报错）。
   steps 可序列化：`brew ruby -e` 打印 `PostflightSteps` JSON 即验 DSL 合法。
   本轮包名中途从 `amd` 纠正为 `afm`：牵涉 cask 文件名/token、Release tag+资产名
   （政策要求 `<name>-<ver>` 同名）、三处文档——旧 `amd-2026.09.15` release
   已整包删除（含 tag），现只有 `afm-2026.09.15`。
3. **中文 app 名直写可行**：brew 用 Info-ZIP `unzip` 解包（`unpack_strategy/zip.rb`
   实读），实测 `AFM拼音.app` 解包后与 NFC 字面逐字节一致；ditto 打包 round-trip
   `diff -rq` 零差异且 `codesign -v` 有效——无需改 ASCII 名。
4. **Intel 机上 cask 侧验证天花板**：`depends_on arch: :arm64` 使 `brew fetch --cask`
   与 `install` 一并拒绝（fetch 直接跳过下载但 exit 0，绝不能当"下载成功"读；
   url+sha 改走 curl 实下 85MB 对账）。`info --cask` 解析 + `style` + `audit --strict`
   + steps JSON + 安装拒绝测试（exit 1，明示 arch 不符）即本地全部证据；
   ARM 真装机验证只能在 Apple Silicon 上补。
5. **`gh release create` 传 85MB 资产曾 hang 到 300s 超时**：release draft 已建、
   资产未传——`gh release view` 确认后 `upload --clobber` 补传（本次补传秒成，
   初次 hang 疑似 tag 推送阶段问题非上传本身），再 `edit --draft=false` 发布。

### 11.41 自有源码包的本地构建镜像实录（2026-10-05，amd 首例）

上游 `Bemly/AMD-Pastis-Bartender` 只有源码 tag（`v2026.09.18` 最新）、无 release
资产——走 winstart 模式：本地 `xcodebuild` 出包 → 镜像到本仓 Release
（`amd-<ver>`）→ cask 指 Release。构建链三前置（缺一即红）：`git submodule
update --init`（`Vendor/mac-dual-pipe` 空克隆无内容）；`tools/build_dualpipe.sh`
（直传静态库）；`tools/getkit.sh`（frida-core devkit 16.7.19 改中性名放
`~/.obkit`，仓库外，不进 git）。

1. **老 SDK 编不过新符号**：`effectIsInteractive` 只在 `@available(macOS 27.0, *)`
   里用，但 Xcode 26.5 自带 SDK 根本没声明该属性（availability 守卫救不了缺声明）。
   修法只动 `/tmp` 临时克隆、不碰上游：`@try { [g setValue:@(interactive)
   forKey:@"effectIsInteractive"]; } @catch (...) {}`（KVC 零编译期引用；
   `respondsToSelector:@selector(...)` 写法新 clang 照样判 error，别用）。
   建议上游合入同款，之后老 SDK 也能编。
2. **Intel 机默认只出 x86_64**：必须显式 `ONLY_ACTIVE_ARCH=NO ARCHS="arm64 x86_64"`
   才是 universal（`lipo -archs` 双确认 `.app` 二进制与 `obcli`）；arm64 切片跨编
   无需本机运行。
3. **frida 不用加依赖**（用户问过，结论：不加）：`otool -L` 只有系统库，
   frida 以 `.a` 静态链接进了二进制，装机零依赖；且本 tap 的 `frida-server`
   是 17.18.0、构建 kit 是 16.7.19——frida 客户端/服务端要同版本，加了也是错的。
4. **zip 双顶层**：`ditto -c` 只收单源，多顶层（`.app` + `obcli`）用 `zip -qry`
   （先 `xattr -cr` 清隔离属性再打），round-trip 后 `codesign -v` 有效、
   `lipo` 双架构、`obcli --help` exit 0 才算过。
5. **ad-hoc 签名预期行为**：`spctl` 报 rejected 正常，caveats 写右键打开；
   首跑 `osascript ... quit` 可能 hang（测试改 `kill`，cask 本身不受影响）。
   Intel 真装全绿：`install` 成功、app 启动退出正常、`obcli` 进 `/usr/local/bin`。

### 11.42 Intel-only cask + 资产名不稳定上游的 github 流（2026-10-05 实测，blender-5x）

上游 `jaguarus83/blender-5x-intel-mac-builds` 的 release 资产名三版三个样
（5.0.1 `Blender-5.0.1-x86_64.dmg` → 5.2.x `Blender-<ver>-macOS-x86_64-AMD.dmg`，
5.2.1 双资产并存）：检查器走 github 流 + `uploadRelease` 镜像分支，`downloadURL`
模板按最新形态写——上游改名则 HEAD 探测 404 报 `upstream-missing` 开 issue，
绝不写坏文件（到时人工同步模板与资产名）。`checksumsURL: nil`（上游无清单，
有更新时 400MB 下载实算，仅新版本时发生）。

1. **dmg 里 `Blender.app` + `Applications` 符号链接是 cask 常规形态**：11.8 的
   `MacOS.system_dir?` 崩溃是公式 `DmgUnpackStrategy` 专属，cask 挂载拷贝不走
   那条路，core 里同类 dmg 遍地——不用因噎废食转 zip。
2. **未签名包不做 quarantine 清除**：与 TSKMGR（签名已破、"已损坏"绕不过）不同，
   完整未签名包右键打开即可（palera1n 同例），caveats 写清即可。
3. **文件名尾部 `x86_64` 致盲版本检测**：字面版本 url 被 audit 判 unversioned
   （扫成 `"64"`，node/go 同病）——cask url 必须 `#{version}` 插值（tag 与资产名
   双插值，wireshark/zcode 同例）。注意镜像分支更新时整条换字面 url，届时若
   audit 再红，回头修核心改写（本次首版插值绿）。
4. **本机已有 Blender.app 时的验证**：`install` 在下载+sha（`✔︎ Cask`）之后、
   搬 app 之前报 `already an App` 中断——这本身即全链路证据（url/sha/app 名全对），
   不用为验证挪走用户 400MB 的旧 app；二进制另做 headless 跑
   (`Blender --background --version` exit 0) 验 dylib 闭包。
5. 本 tap 首个 `depends_on arch: :x86_64` cask（与 afm 的 `:arm64` 对称）；
   与 core `blender` 同名同 ID（`org.blenderfoundation.blender`），caveats 写明
   先卸旧版（11.20 同例）。

### 11.43 必触发更新 + 浮动上游的日期版本 + audit 再收紧（2026-10-06 实测；dsh-gui 于 2026-11-18 改 feed）

1. **`UpdaterCore` 新增 `alwaysUpdate` 开关**（默认 false，其他 40+ 包行为逐字节
   不变，48 个检查器全编译回归通过）：`current == stable` 也跳过 up-to-date、
   照走 HEAD→sha→镜像→改写全链路；`newer-than` 守卫保留。给"内容会变但版本号
   不变"的上游准备：dsh-gui 的浮动直链、konsole 的只留最新快照。
2. **dsh-gui 已改为 nightly feed 版本（2026-11-18）**：浮动直链
   `dsh-latest-macos-x64.dmg` 的 last-modified 停在 10-17，实为 rc.1，而 feed
   `dsh-desk/feeds/mac-x64/nightly-mac.yml` 已是 0.2.1-rc.4。现在 `customRelease`
   抓 feed 的 `version:`，拼版本化 dmg 直链，按版本判新、去掉 `alwaysUpdate`；
   镜像到 Release `dsh-gui-<ver>`。历史的"日期版本+必触发"方案只留给 konsole
   这类真正只留最新快照、无版本信号的上游。
3. **konsole 顺手真升了一次**：跑必触发验证时正撞上游 5277→5348，双包下载实算、
   上传 `konsole-5348`、旧 `konsole-5277` 自动清理、改写 version+双 sha——
   §6 版本行同步 5348。注意 konsole 的 url 仍是 `#{version}` 插值（双分支不动 url 行）。
4. **audit 又收紧了**：字面"版本仅 tag 段"不再过 unversioned 检查——此前全绿的
   brewui、github-copilot-app 现同红（存量漂化，11.25 同例，本轮未动）。
   dsh-gui（资产名浮动无版本）用 `dsh-gui-#{version}/` tag 段插值过关。
   教训：凡 tag/资产名形态特殊的 cask，首版即用插值，不要赌字面。
5. dsh-gui 包体：thin x86_64 + 公证签名（`spctl accepted`，零 Gatekeeper 摩擦，
   无需 quarantine/caveats）；与 `deepseek-harness` 公式（npm CLI）同源不同物，
   token 不冲突。Intel 真装全绿（386MB，app 启动 multi-helper 正常）。

### 11.44 cmake 直引预编译：Tier 3 下绕开源码编译（2026-10-08 实测）

core cmake 4.4.4 的瓶只有 `arm64_*` + `x86_64_linux`，Intel Mac 只能源码编——
本 tap 改直引上游官方 `cmake-<ver>-macos-universal.tar.gz`（universal 双切片，
file 实测），15 秒装完。结论：**有上游 macOS 预编译就不走 qemu 代编译模式**，
更不碰本地工具链（本机 `/usr/local/lib/libcurl.a` 缺 ICU 符号、x86_64 链不过——
而预编译包只链**系统** `/usr/lib/libcurl.4.dylib`，otool 全系统库，零依赖，
本地那堆问题根本走不到）。

1. **检查器与 brew 扫描对同一 URL 结论不同**：`currentVersion` 取 url 行首个点分段
   （`/v4.4/` 目录段 → `"4.4"`），brew 自身扫描取文件名（→ `4.4.4`）。初版按 glib
   前例写了显式 `version` 行，被 audit 判冗余——实证 brew 扫描是对的。修法是反过来：
   主 url 换 Kitware GitHub（全段全版本号，无目录段坑），cmake.org 作 http(s)
   双镜像；检查器模板仍按 `v<主次>` 动态拼目录（补丁升级自动对）。
2. **http 镜像是硬性要求**：cmake 在 core curl 的递归依赖树里（构建工具链），
   audit 强制至少一条明文 `http://` 镜像（core 用 fresh-center 同例）——本公式加
   `http://cmake.org/...`（301 到 https，同文件，纯为过审）。
3. **`post_install` 已死**：style 直接拒（11.37 同款），校验（file 认 x86_64 +
   `--version` 自检）挪进 `install` 尾部，走最终交付的 bin 软链。
4. **同名切换三步**：本机 core cmake 被 `pin` 过（bootstrap 防 churn），须先
   `brew unpin cmake` 才能卸；`brew uninstall` 触发 autoremove 顺手带走了
   meson/bison（无依赖者）——完事后原样装回，环境零漂移。教训：动 pin 过的包
   先看 pin，动构建依赖先记清单。
5. 小版本升级（4.4→4.5）时 cmake.org 镜像行的 `/v4.4/` 目录段曾要手工跟（子串替换
   够不着）；2026-11-17 起 `rewriteFormula` 会同步镜像 URL 的 `vX.Y` 目录段（见 11.57），
   不再需要手工改。主 url（GitHub，无目录段）本来就不受影响。

### 11.45 cursor 下载页锚定判新（2026-10-09 实测，grok-bot）

`https://cursor.com/cn/download/bot` 页内除 Grok Bot 各平台直链外，还有
`0.814.049` 之类无关版本——检查器必须锚定 Intel 行
（`darwin-x64/<ver>/Grok_Bot_`）取版本号，裸扫点分段必误抓（konsole 的
双 listing 交集是同类思路：版本信号有多个时先锚定再取）。
上游直链全版本化（`darwin-x64/<ver>/Grok_Bot_<ver>_x64.dmg`），命名稳定，
无需 blender 式的改名预警；`checksumsURL: nil`（155MB 下载实算，仅新版本时）。
包体 thin x86_64 + 公证签名（`spctl accepted`），Intel-only 门槛 + 无 caveats；
`Grok_Bot_<ver>_x64.dmg` 的 `_x64` 尾缀同 `darwin-amd64` 一样致盲版本检测，
cask url 首版即用 `#{version}` 双插值（11.42 教训前置）。

### 11.46 watcher 大批量后的三个掉队问题（2026-10-09 实测，caddy/iperf3/protobuf）

2026-10-09 的 watcher 一次扫出 26 个更新、提交 24 个（含之前 404 的 6 个 cask
全部对齐），17 个公式触发制瓶；caddy/iperf3/protobuf 因各自原因掉队，
本地复现 + 手工修好后随下批制瓶（与本次 17 个不抢并发组，串行排队）。

1. **caddy：上游 checksums 文件换 SHA-512**。`caddy_<ver>_checksums.txt` 全文件
   128 位 hex，核心按资产名精确命中后被 64 位校验拒收（`得到的 sha256 不合法`，
   fail→无 status→还原跳过，文件零污染）。修法：`checksumsURL: nil` 回退下载
   实算（tar 包约 18MB，仅新版本时；buildx/frida 同例）。实算值与独立下载
   逐字节一致才提交（三方一致）。
2. **protobuf：改写侧污染 `fails_with` 块**。11.29 只守了解析侧；`rewriteFormula`
   的 version 行同步取"第一个命中"，无顶层 version 行的公式（protobuf，版本全靠
   url 扫描）第一命中即 `fails_with :gcc` 里的 gcc 版本——原始值 `"12"` 被之前
   几次 watcher 改写成 36.0→36.1（本次本地复现抓现行）。修法：核心加 `failsDepth`
   跟踪（与解析侧同正则，bare `fails_with :clang` 不进深度），块内 version 行
   一律跳过；protobuf 的块内值手工恢复 `"12"`。make（块内无 version）、nghttp2
   （`"13"` 未被改过）不受影响。50 个检查器全编译回归通过。
3. **iperf3：CI fetch 报错新旧 sha 对不上而本地复现全绿**。brew stable 3.21→3.22，
   本地检查器改写 + 独立复算 + `brew fetch` 三方一致全过——CI 那次属于 fetch 侧
   读到旧文件内容的 flake（checker 日志与本地行为逐字节一致，文件当时肯定已写回；
   制瓶从 git 读文件不走这条路，不影响确定性修复）。三方一致不过的绝不提交
   （11.24 的 gh 重切是反例：当时 checksums 与实物双双已变，必须等一致）。
4. 本批另有 grok-bot/konsole 报 check-failed（runner 当时抓 cursor 页/KDE listing
   失败，瞬时网络问题）：无 status 即跳过、文件不动，下次自动恢复，不开 issue。

### 11.47 scrcpy 预编译直引 + write_exec_script 无执行位（2026-10-13 实测）

core scrcpy 5.0.1 在 Intel 无瓶，依赖树（openssl@4/python@3.15/libvmaf/libvpx/
sdl3/sdl2-compat/x264/x265/ffmpeg…11 装 5 升）全源码编，用户实测卡在 openssl@4
的 `make`（Tier 3 意料之中）。本 tap 改直引上游官方 `scrcpy-macos-x86_64-v<ver>.tar.gz`
（thin x86_64，otool 全系统库，SDL/ffmpeg 静态链入，实测零 brew 依赖；core 自家
都用 `scrcpy--prebuilt-server` 资源，整包拿更没问题），4 秒装完。

1. **扁平布局不可拆**：`scrcpy` 按自身所在目录定位 `scrcpy-server` 与 `adb`——
   整包进 `libexec`，`bin` 用 `write_exec_script` 指过去，不猜 symlink 解析
   （SDL_GetBasePath 对 symlink 的行为不可靠，wrapper exec 后即真实路径，确定对）。
2. **`write_exec_script` 只写文件不给执行位**（644，实测 `ls -la` 确认；隔壁
   `write_env_script` 显式 `chmod 0555`，本函数漏了）：install 尾的 `--version`
   自检以 exit 1 静默失败（无输出，keg 回滚），/tmp 手测因顺手 `chmod +x` 没暴露。
   修法：install 里显式 `chmod 0555, bin/"scrcpy"`（frida 的 xz 无执行位是同类，
   见 11.37）。教训：凡 wrapper/垫片，进 install 尾自检前先确认模式位。
3. 文件名 `-v5.0.1` 尾缀不致盲版本扫描（实测 stable 即 5.0.1，不写 version 行；
   buildx/docker-compose 同例，以 audit 为准）。

### 11.48 yt-dlp 的去零/补零版本差 + 无补全构建（2026-10-14 实测）

core stable 取 PyPI 归一化值 `"2026.8.19"`（去零），GitHub tag 保持补零
`"2026.08.19"`——同一 release 两种写法。不处理则每次误报更新、模板拼出
404 URL（`.../download/2026.8.19/...` 不存在）。两处修：

1. **核心数字段按数值判等**（`compareVersions`：`"08"` vs `"8"` 数值相等即
   continue；纯字面 fallback 保留，预发布逻辑不动）。另补 `==0 但字面不同`
   分支直接判 up-to-date（dual-arch 路径无此形态，不动）。52 个检查器全编译
   回归通过（其他包行为不变：前导零差异只在此一种上游出现）。
2. **yt-dlp 模板内补零**：brew 版月日补齐两位再拼 GitHub 路径（年不动）；
   形态对不上则 HEAD 探测报 upstream-missing，不写坏文件。
3. 公式不写 version 行：路径段即全版本，brew 扫描正确（写了判冗余；初版写过，
   audit 指正后删，与 cmake 反向而同因——一律以 audit 为准）。
4. 此 PyInstaller 构建无 `--print-completion`（`--help` 全文无 complet 字样，
   exit 2），不硬凑补全文件；裸二进制无执行位，`chmod 0555`（frida/scrcpy 同例）。
   test 只做 `--version` + file 断言（core 的下载实测涉网，沙箱必挂，见 11.30）。

### 11.49 libimobiledevice 入库：idevice 栈分流 + curl3 静态库遮蔽系统 curl（2026-10-19 实测）

用户跑 `brew install libimobiledevice`，core 侧 plist（48s）/glue（17s）现编通过，
卡在 libtatsu 链接：`ld: symbol(s) not found for architecture x86_64`，`_uidna_*`
来自 `libcurl.a`（libcurl_la-psl.o/libcurl_la-idn.o 引用，链接行无提供方）。
根因是本机 `/usr/local/lib/libcurl.a`→curl3 的静态库（无配套 .dylib，
`-lcurl` 被迫静态链接，而该 .a 缺 ICU/IDN 符号；11.33 的纯客户端形态遗留）。
CI runner 的 /usr/local 无此文件，用 brew/系统 shared curl 正常链接——
纯本机环境问题，不是上游 bug。本地验证时临时挪开该文件、装完原样恢复
（curl3 运行时是静态链接好的二进制，不受影响；恢复后 `ls -la` 核对）。

**后续（2026-10-19，用户拍板永久清除）**：删掉 `/usr/local/lib/libcurl.a`
这个符号链接（Cellar 原件不动，`curl3` 自身静态运行无碍）。判据：扫全
`/usr/local/lib` 的孤儿 `.a`，只有 `libcurl.a` 是"通用链接名被静态独占"
（`-lcurl` 人人探；webp/shaderc/tcl stub 等孤儿库都是生僻名，无人裸 `-l`，
不动）。清除后本机 `--build-from-source` 重编 libtatsu 一次过（16s），
闭环证明。**复发预警**：下次 `reinstall/link curl3` 会重建该链接（瓶里带着
`.a`），届时源码构建若再报同类 `ld: symbol(s) not found`，同一招（删链接）
即可；`curl3` 二进制本身永远不受影响。

入库分流（全量 formula.json 反查扇入，Tier 3 上 `brew uses --eval-all` 已禁用）：
自瓶 5 个——libplist（扇入 10，全 idevice 系）/glue（3）/tatsu（1）/
usbmuxd（扇入 2：ios-webkit-debug-proxy/libimobiledevice）/本体；
留 core 3 个——libtasn1（扇入 6：gnutls/p11-kit/samba/webkitgtk，枢纽）、
openssl@4（扇入 524）、ca-certificates。依赖改写按 6 节规则（叶子全名、枢纽裸名）。
`revision` 行（tatsu 1/usbmuxd 1/本体 2）照抄 core：watcher 只动 url/sha，
上游发新版时若 core 掉 revision，此行必须手工删（核心不会自动同步）。

本地 5 编 5 测全绿后入库；瓶由 bottle.yml 出（topo 自动排序，无需手工排）。
另：core scrcpy 5.0.1 至今不依赖 libimobiledevice（`brew deps` 实测只有
ffmpeg/libusb/sdl3）——用户日志里 scrcpy 头 + idevice 尾混在一起是两次安装
的输出拼贴，不必深究；本 tap 的 scrcpy 零依赖预装包不受任何影响。

### 11.50 wabt 入库：runner 预装 core cmake 撞全名依赖（2026-10-20 实测）

wabt 按 6 节 SOP 入库（core 拷入 + 双门槛；构建依赖写本 tap 全名
`depends_on "bemly/tahoe/cmake" => :build`——core cmake 在 Intel Tahoe 无瓶，
本 tap universal 包秒装，11.44 同因；`openssl@4` 枢纽裸名留 core）。本机
`--build-from-source` 一次过（style/audit/fetch/test 全绿、检查器 59/59 编译回归），
但触发制瓶 46 秒即挂：`cmake is already installed from homebrew/core!`。

根因：macos-26-intel 镜像**预装了 core 的 cmake 同名 keg**（与 11.10 node@24
同型），全名依赖解析时先撞「已装自别的 tap」的 odie。**本机不复现**（本机 cmake
装的是本 tap 版）——预装 keg 撞名只在 CI 出现，「本地全绿 ≠ CI 不炸」同族
（11.16/11.19 旧账再加一笔）。

修法（bottle.yml 已落地，循环内每个公式装回前）：解析 `depends_on` 行抽依赖名，
**只对「本 tap 拥有对应公式」的名字**（`Formula/<dep>.rb` 存在，即全名分流目标）
先 `brew uninstall --force --ignore-dependencies` + 兜底删 bin 链接，再交给
install 装回——全名依赖命中的是本 tap GHCR 瓶。裸名枢纽（openssl@4 等）不上
清理名单，`all` 制瓶不会因此多编一个枢纽。

### 11.51 同名依赖双 tap 混写必死锁：llvm/z3 实锤（2026-10-22 实测）

llvm `brew install --build-bottle` 三连红 `has already locked Cellar/cmake`
（两次 CI + 一次本机，次次 60 秒内死在依赖倒包阶段，与编译无关）。
用 lsof + 给 brew 源码临时打 backtrace 补丁（打完即还原）抓到现行，根因三段：

1. **macOS 的 flock 同进程双开也互斥**（实测：同一进程 open 两次同一 lockfile，
   第二个 `LOCK_EX|LOCK_NB` 必回 false）——所以只要同一进程里同一把锁被拿两次，
   必死，与有没有别的 brew 进程无关（`ps` 干干净净也照死）。
2. **触发条件是递归依赖里同一软件出现两个 full_name**：llvm 直挂
   `bemly/tahoe/cmake`，又经裸 `z3`（core z3 的构建依赖是裸 `cmake`）把
   `homebrew/core/cmake` 拉进来；`locked.uniq!` 按 full_name 去重留俩，
   `each(&:lock)` 第一把成功（fd 一直开着）、第二把当场 EWOULDBLOCK。
   堆栈两次逐行一致（`install→lock→each`），`lsof` 显示持锁 fd 与报错同 pid。
3. **裸名对照组一次过**（把 cmake/ninja 换裸名后锁点消失，死在后面的 bottle
   可行性检查——那是另一个预期行为），wabt 没事是因为它的树里没有第二份 cmake。

修法（已落地）：**z3 自瓶**（扇入 11 全小众工具+llvm/lldb，无枢纽，libplist 同例），
llvm 的 z3 依赖改全名；z3 自己的 cmake 改全名、python 退 3.14（runner 旧 core
不认 3.15，39755321416 实锤）。此后 llvm 树里 cmake 只有 tap 这一份，`uniq!`
正常去重。教训：**以后凡是全名依赖，必须反查它的递归树里有没有同名裸依赖
（`grep depends_on` core 原文 + 全量 formula.json 扇入），有就把那一整条一起自瓶，
否则就是给 CI 埋一颗确定性地雷**——与 11.11（同名跨 tap odie）并列为依赖分流的
第二条铁律：同名不同 tap 在锁层面同样互斥。

后续（同轮）：自瓶 z3 后发现光去重还不够——`python@3.14` 的递归树**自带裸 cmake**
（`brew ruby` 打印 `recursive_dependencies` 实锤），tap-cmake + python 共存即原罪，
故 llvm/z3 改为**不声明 cmake**（ninja 只此一份，保留声明），构建走 PATH。
另 `--build-bottle` 下任一依赖无瓶即硬拒（`UnbottledError`，2020 年旧逻辑，
满足的依赖才被 `expand` 排除；如 python 大版本升级要现编），而普通模式无此检查——
故循环里先 `brew install --only-dependencies` 装齐（缺的倒瓶、没瓶的现编，幂等），
再 `--build-bottle`。失败要红，不加 `|| true`（11.10）。三板斧缺一不可：
去声明 + PATH 预装 + 先装依赖，llvm/z3/wabt 三形各自对应，见 bottle.yml 注释。

订正（同轮）：workflow 预装光把瓶倒进 Cellar 不够——superenv 构建隔离了
`/usr/local/bin`，未声明的依赖 brew 不会注入 PATH，`system "cmake"` 照样
`ENOENT` 空死（wabt 因声明了才没事，天然对照组）。最终形态是公式 `install`
首行显式 `ENV.prepend_path "PATH", Formula["bemly/tahoe/cmake"].opt_bin`
（引用不产生依赖边，不进锁数组，flock 依然干净）。记住：**构建工具要么声明
（无锁对时，wabt 形），要么声明摘掉 + 公式内 prepend + workflow 预装三件套
（与 python 共存时，llvm/z3 形），只有 workflow 预装是半吊子，必空死**。

附带（同轮）：runner 镜像是 8 月 baked 的，凡 8 月之后进 brew 的 API 一律不能用——
`Formula#python3`（2026-09-02 才有）让 z3 制瓶死在 `NameError`。修法是内联展开
（`formula_opt_bin("python@3.14")` 是 6 月 API，安全），llvm/z3 的三处 `python3`
调用已全改。以后抄 core 新公式时，先 `git log -S` 查所用 helper 的年龄，
8 月 19 日之后的全部展开手写。

### 11.52 llvm 转向 pinned 预编译 19.1.7（2026-10-23 实测决策）

23.x PGO 三阶段在 runner 上实测 6.5~7 小时（stage1/stage2 各 72 分钟，尾巴 3 小时
没啃完），平台硬上限 6 小时，此路不通。而本仓对 llvm 的真实需求只是 bindgen 0.73
运行时的 libclang 9+（用户亲口：16~23 都吃，无版本绑定），回头翻预编译：
19.1.7 是最后一个 macOS-X64 官方包（20+ 全 ARM64；conda 有 23.x osx-64 但要
十来个包手工拼，又贵又脆；NDK 自带 libclang 可零安装顶着）。
故 `llvm` 改走 pinned 预编译（ffserver 同例：锁版本、无 updater、不跟 brew）：
thin x86_64（`clang-19` 与 `libclang.dylib` 双验）+ 全后端（`--print-targets` 含
AArch64/X86，配 sysroot 可 cross 到 Linux）+ 只链系统库零依赖 + `dlopen` 实测过。
`llc` 单二进制上游自带瑕疵（`unknown imports format` 起不来，dev 工具不影响 bindgen）。
包 1.6GB/解包 8.3GB（门槛 18GB，CI 磁盘已证够用）；文件名尾 `X64` 致盲版本扫描
（扫成 `"64"`）故显式 `version` 行；23.x 的 patch/检查器一并删除。
`z3` 不受影响（瓶已在 GHCR，单跑落瓶块即可）。

### 11.53 嘉立创EDA 双版入库：zip 套 dmg 的 cask 用 `container nested:`（2026-11-14 实测）

1. **专业版 zip 不是 app 直包**：`lceda-pro-mac-x64-<ver>.zip` 内是
   `嘉立创EDA(专业版).dmg` + 脚本/文档（多文件），brew 的 `extract_nestedly`
   只对「单文件容器」自动下钻，这里必须显式声明
   `container nested: "嘉立创EDA(专业版).dmg"`——cask 原生 DSL 会先解 zip 再挂载
   dmg 提取 app（core 的 orca 同例），切不可用公式装（app 会进 Cellar，
   Launchpad/Spotlight 不可见）。
2. **标准版 zip 是单顶层目录**：解包后停在 `lceda-mac-x64-<ver>/` 这一层
   （与公式不同，cask 不会自动下降进顶层目录），`app` 路径必须带目录名：
   `app "lceda-mac-x64-#{version}/嘉立创EDA.app"`（cask 文件是 Ruby，插值在
   加载时由 Ruby 完成，audit 也认）。
3. **下载页多产品多平台混排**：页面同时列出专业版/标准版、x64/arm64/linux/
   windows 的直链，检查器必须按产品专属文件名前缀锚定
   （`lceda-pro-mac-x64-` / `lceda-mac-x64-`），裸扫点分段版本必误抓
   （grok-bot 的 cursor 页同型）。
4. **版本以页面 Intel(x64) 行文件名为准**：专业版 4.1.100 与包内 `version`
   文件（36.3.2）、app 的 `CFBundleShortVersionString`（2.2.32.4）互不相同，
   那是上游自己的多套编号，cask 只认下载页文件名。
5. 两包均 thin x86_64 + 公证签名（`spctl accepted`，零 Gatekeeper 摩擦）；
   上游无 checksums 清单 → 有更新时下载实算（专业版约 373MB / 标准版约
   135MB，仅新版本时发生）。`brew install --cask` 双版实测通过
   （pro 的 nested dmg 解包 + 标准版顶层目录路径均正确）。
6. **镜像流写回后要手动恢复插值**：updater 把 url 整条换成字面版本，
   `brew audit --strict` 会判「URL is unversioned」要求 `sha256 :no_check`——
   提交前把 url 行改回 `lceda-<ver>` / `lceda-mac-x64-<ver>` 的 `#{version}`
   插值（mirage-wallpaper 同例，11.26）。另：`deleteOldCaskReleases` 的旧版
   清理已加「前缀后必须是数字」守卫，避免 `lceda-` 前缀误删 `lceda-pro-*`
   的 Release（双版同前缀实测中招）。

### 11.54 chisel 入库：gzip 裸二进制 + core 同名异物（2026-11-14 实测）

1. **gz 解包单文件 + 无执行位**：`chisel_<ver>_darwin_amd64.gz` 用 brew 原生
   Gzip 策略（系统 `gunzip -N`，无额外公式依赖），头里原名即 `chisel`；
   gunzip 不还原 mode，解出 0644 → `bin.install` 装成 0444，必须
   `chmod 0555`（frida-server 的 xz 同例，11.37）。
2. **core 同名异物**：homebrew/core 的 `chisel` 是 Facebook 的 LLDB 命令集
   （2.0.1，源码包），与 jpillora/chisel 完全无关但共用
   `Cellar/chisel`——同 tap 不能共存，caveats 写明先 `brew uninstall chisel`
   （h2spec/rustup 同型）。检查器不能走 brew 流（会拿错版本），走 github 流。
3. **checksums 形状**：`chisel_<ver>_checksums.txt` 是标准
   `<sha256>  <filename>`，核心按资产名精确匹配可用（约 8KB），不必下载
   4.8MB 实算；tag 带 `v` 前缀，默认 `githubTagPrefix` 即可。
4. 本机全链路实测：style/audit（装前装后）/fetch/install/test 全绿，
   `chisel --version` 输出裸版本号 `1.12.0`；摆拍 1.11.2 → 1.12.0
   改写（双处 url + sha + 摘瓶）逐字节正确。

### 11.55 exiftool 入库：纯 Perl 直装 + core 同名同物 + SourceForge 镜像兜底（2026-11-14 实测）

1. **纯 Perl 不算「代编译」**：上游 `Image-ExifTool-<ver>.tar.gz` 里 `exiftool`
   脚本 + `lib/` 就是全部运行时，零编译。core 公式为支持 JXL BrotliEXIF /
   LZMA 等可选元数据，额外 `depends_on "brotli"`/`"xz"` 并用 `Makefile.PL`
   编译 5 个 CPAN XS 模块（其中一个还要 patch）——在 Intel Tahoe 全无瓶，
   会拖出一整串源码编译。本 tap 只要常规 EXIF 读写，直接
   `libexec.install "exiftool", "lib"` + `write_env_script` 暴露 `bin/exiftool`：
   脚本 BEGIN 块按自身所在目录 `unshift @INC, "$dir/lib"`，两者必须同级放进
   libexec（core 同款 wrapper）。精简范围写进 caveats。
2. **没有 Mach-O 可校验**：`file(1)` + x86_64 断言不适用（neofetch 同例），
   `install` 尾部只做 `exiftool -ver` 版本自检；Intel + Tahoe 门槛仍由顶部
   `depends_on` 硬性保证。
3. **core 同名同物**（与 chisel 的「同名异物」不同）：core `exiftool` 有
   arm64_tahoe 等 `cellar: :any` 瓶，但**没有 `x86_64_tahoe`**；同 Cellar
   路径不能共存，caveats / README 写明先 `brew uninstall exiftool`。
4. **原料直链双保险**：core 的 `urls.stable.url` 是 `downloads.sourceforge.net`
   （302 跳 `*.dl.sourceforge.net`）；本机实测该 dl 主机偶发 SSL/超时不可达，
   而 core 自带的 CPAN 镜像 `cpan.metacpan.org/.../Image-ExifTool-<ver>.tar.gz`
   同版本同 sha256 可下。故公式 `url` 用 SourceForge、`mirror` 用 CPAN：
   全量式检查器整条替换 url，mirror 行靠版本子串替换同步（11.28），
   二者始终指向同一 tarball。`curlHeadOK` 不带 `-L`，302 本身即判可达，
   watcher 不受影响；直链失败时 brew 的 `CurlDownloadStrategy` 会打印
   `Trying a mirror...` 自动回落到 CPAN。
5. **版本跟随 core**：核对时上游 exiftool.org 已到 13.63，core 仍停在
   13.55（2026-10-21 最后更新）。按 SOP 9.1 的 brew 流判据取 13.55，
   core 升版后 watcher 自动跟上，不另接上游页面判新。
6. 本机全链路实测：style / audit --strict（装前装后）/ fetch / install / test
   （`exiftool -ver` + `test.jpg` 的 `MIME Type`）全绿。

### 11.56 lody / Qoder CN 入库：core 同名 token 与 installer 套壳（2026-11-17 实测）

1. **lody 走 core cask 版本 + Intel 变体**：core cask 默认 arm64，tahoe 变体是
   `Lody-<ver>-x64.dmg`（sha 与 core cask API 的 intel 值一致，下载实测
   `3cf968…`）；本 tap 自建 `lody` cask 锁 Intel + tahoe，镜像到 Release
   `lody-0.112.0`。主二进制 thin x86_64，Sparkle 为 universal；包内另有
   `better-sqlite3/prebuilds/darwin-arm64.node`（可选模块，Intel 运行用不到；
   cask audit 不扫已装文件，无需 `audit_exceptions`）。检查器 brewCask 流
   （版本跟 core）+ uploadRelease。
2. **Qoder CN 的下载页链接是安装器，不是 app 本体**：qoder.cn/download 的
   Mac Intel 行给 `.../releases/latest/Qoder-CN-Installer-mac-x64.zip`（浮动、
   无版本），zip 里 `Qoder CN Installer.app/Contents/Resources/payload/` 才是
   真身 `Qoder-CN-<ver>-mac-x64.zip`，同目录 `installer-manifest.json` 也给出
   `qoderDmgDownloadUrl`。cask 不能装安装器，直接取版本化真身
   `https://static.qoder.com.cn/qoder-app/releases/<ver>/Qoder-CN-mac-x64.dmg`
   （0.5.13 实测 337.7MB，sha `18588f…`，thin x86_64，公证签名；app 名
   `Qoder CN.app`，bundle `com.qodercn.app`）。
3. **版本判据用官方更新日志锚点**：`https://changelog.qoder.cn/qoder` 是按
   发布时间倒序的 Qoder CN 更新记录，首个 `<a id="x.y.z">` 即最新版（0.5.13）。
   检查器 customRelease 抓该锚点拼版本化 DMG；日志先于安装包发布时 HEAD
   探测 404 → `upstream-missing` 开 issue，不会写坏文件。上游无 checksums
   → 有更新时下载实算（约 322MB），再镜像到 Release `qoder-<ver>`。
4. **cask token 用 `qoder`（用户拍板）**：与 core 的国际版 cask 同名但不同物
   （core 装 `Qoder.app`，本 tap 装 `Qoder CN.app`），二者共用 Caskroom/qoder，
   先卸一方再装。本 tap 的 url 用 `#{version}` 插值过 audit；镜像流下次更新
   会整条换成字面 Release URL，届时按 11.26/11.53 的做法手动改回插值再提交
   （audit 的 unversioned 判定）。
5. **验证**：`brew style` / `audit --strict --cask`（装前装后）/ `brew fetch
   --cask` / `brew install --cask` 全绿；两 app 的 `file` 均 thin x86_64，
   `spctl` 均 `accepted`（Notarized Developer ID）。Release 资产已上传
   （`lody-0.112.0` / `qoder-0.5.13`）。

### 11.57 watcher 的 fetch 验证必须先 trust；cmake 模板必须同源（2026-11-17 实测）

1. **brew 7 起未信任 tap 的公式拒绝加载**：`watch-updates` 在 ubuntu 上对更新的
   公式逐个 `brew fetch` 做 url+sha 端到端校验，没 trust 时全部报
   `Refusing to load formula bemly/tahoe/<name> from untrusted tap`，本轮 19 个
   公式被误判为 fetch 失败并还原，只有 6 个 cask 进了提交。
   修法：fetch 前先 `brew tap bemly/tahoe "$GITHUB_WORKSPACE"` +
   `brew trust bemly/tahoe`（tap 级信任覆盖全部公式，不用逐个 `--formula`）。
2. **模板流的 `downloadURL` 必须与公式主 url 同源**：cmake 主 url 是 Kitware
   GitHub，检查器原模板却拼 cmake.org，改写后字面 url 对不上，自检直接 fail
   （`url 未成功更新到 https://cmake.org/files/v4.5/...`）。已把 cmake 检查器
   模板改成 GitHub；cmake.org 只保留在 `checksumsURL` 与 mirror 行。
3. **镜像 URL 的 `vX.Y` 目录段同步已自动化**：`rewriteFormula` 原先只做版本
   子串替换，cmake 的 `/files/v4.4/` 换不到；现额外把 mirror 行里的旧
   `v<major>.<minor>/` 路径段换成新值（仅完整路径段，不碰文件名），
   cmake 4.4.4→4.5.0 实测两行镜像同时变为 `/v4.5/`。

### 11.58 python@3.15 / meson 入源：同名接管 + 全名依赖（2026-11-17 实测）

1. **需要编的是 `python@3.15`，不是 meson**：core 的 meson 瓶是 `all`（架构无关），
   但它裸依赖 `python@3.15`；python 3.15.2 在 core 只有 arm64/x86_64_linux 瓶，
   Intel Tahoe 上 meson 一更新就把 Python 拖进源码编译（`openssl@4` 等依赖同缺瓶）。
2. **按 node 同款同名接管**：`Formula/python@3.15.rb` 从 core 拷入，摘 bottle、
   加 `arch: :x86_64` + `macos: :tahoe`；`Formula/meson.rb` 同样处理，但依赖改
   `bemly/tahoe/python@3.15` 与 `bemly/tahoe/ninja`，确保 meson 真正用上 tap 瓶。
   python 是 730 个公式的反依赖枢纽，装 tap 版前必须先卸 core 版；core 公式后续
   裸依赖 python@3.15 时可能报跨 tap 冲突（用户已知并接受，node 同款）。
3. **补丁必须随 tap 入库**：core 公式引用的 `patches/python/3.13-sysconfig.diff`
   不会自动带过来；已复制到 tap 根 `Patches/python/3.13-sysconfig.diff`
   （`LocalPatch` 按 tap 根解析）。
4. **runner 没有 `python3` helper**（11.51 同款 API 年龄问题）：meson 首轮制瓶
   （`44098767439`）python 瓶成功、meson 在 install 起始报
   `NameError: undefined local variable or method 'python3'`。修法是显式定位：
   `python = formula_opt_bin("bemly/tahoe/python@3.15")/"python3.15"`，
   `Language::Python.site_packages(python)` 也传这条路径；`formula_opt_bin`
   是 2026-06-22 API，runner 可用。第二轮 `44102485426` meson 出瓶成功。
5. **瓶块提交的 `if: always()` 已救场**：首轮 meson 失败仍把已推的 python 瓶块
   提交（`e3ce9aa`），第二轮只补 meson 瓶块（`b7782ad`），无需重制 python。
6. 检查器都用 brew 全量流：python/meson 直取 formulae.brew.sh 的
   `urls.stable.url`/checksum；meson 的 `revision 1` 与 core 同步，core 升版掉
   revision 时手工删（11.49）。
7. `lz4`/`pkgconf` 不单独入源：Intel 上源码编译仅 25–36 秒，且 pkgconf 只是
   python 的构建依赖；真正的瓶颈是 python 本体。

### 11.59 GHCR 瓶只含本体 + 递归依赖门控（2026-11-17 实测，graphviz 16.1.1）

1. **现象**：`brew upgrade bemly/tahoe/graphviz`（16.1.0 → 16.1.1）时，本体瓶
   `e708885…` 已在 GHCR，却开始源码编译一大串 core 依赖：`libpng 1.6.58→1.6.59`、
   `librsvg 2.62.3→2.63.4_1`，而 librsvg 现编又要 `rust`/`cargo-c`/`libgit2`/
   `gobject-introspection`/`help2man`/`llhttp` 等。查 API 这些公式的 `bottle` 全是 `{}`。
2. **根因不是门控漏检，是此前门控根本没查依赖**：`bottle.yml` 只有 `brew readall`
   （语法/门禁），制瓶循环又先用 `brew install --only-dependencies` 把缺瓶依赖在 runner 上
   现编掉，再 `brew install --build-bottle` + `brew bottle` 只给目标公式出瓶。瓶不含依赖，
   所以 CI 绿 ≠ 用户端免编译。
3. **规则已写进文档（§8.1 / README / README.zh）**：GHCR 瓶只含本体；需要依赖就把依赖
   一起放本仓出瓶，公式里写全名 `bemly/tahoe/<name>`，不要写裸名留 core。
4. **门控已补递归检查**：`bottle.yml` 的「递归检查依赖瓶覆盖」步骤用
   `brew deps --full-name --union` 展开每批公式的**运行时**依赖闭包（build deps 只在 CI
   现编，不检查）；本仓依赖无瓶块（且不在本批拓扑内）直接红，core 依赖经
   formulae.brew.sh API 查无 `tahoe`/`x86_64_tahoe`/`all` 瓶则列出并红掉（`brew info
   --json=v2` 对未安装的 core 公式不返回 bottle 元数据，不能用）。确需重建旧枢纽公式时，
   手动触发可勾 `allow_unbottled_core: true` 放行（代价是重新引入用户端源码编译，
   违背本仓承诺，应尽快把依赖搬进本源）。
5. **graphviz 的解法**：不搬 57 个 core 依赖，而是把公式改成零运行时依赖——
   关掉 cairo/pango/librsvg/gd/freetype/webp/gts 等第三方插件，改用
   `--with-included-ltdl` + 系统 expat/zlib，Quartz 与内置插件仍提供 PDF/PNG/SVG。
   本机 `--build-from-source` 1 分 41 秒装完、`dot -V`/`-Tpdf`/`-Tsvg`/`-Tpng` 全过。

### 11.60 doubao-ime 迁移声明式 steps + 命令式 block 加载即告警（2026-11-20 实测）

11.40.1 的「存量 doubao-ime.rb 本轮未改」已过时：用户运行时撞
`Calling 'postflight' is deprecated!` 告警（brew 7 后期版本加载 cask 即打警告，
**不只是 lint 腐化，运行时也刷**），本轮完成迁移（afm 为模板）：

1. `preflight do` → `preflight_steps do`：解包安装器内层 `DoubaoIme.zip` 的
   Ruby 通配逻辑包进 `run "/bin/sh", args: ["-c", ...]`。steps 是序列化后带
   context 执行的（`install_steps.rb` 实读），**块内拿不到 `staged_path` 方法**，
   要用模板 token `{{staged_path}}`（CONTENT_PATH_TOKENS 之一，runner 展开）；
   取「第一个匹配」用 `set -- <glob>; "$1"` 模拟旧 `.fetch(0)`。解包目标在
   caskroom 内，sandbox 默认放行，无需 `writable_paths`。
2. `postflight do` → `postflight_steps do`：`set_permissions … base: :home`
   （原 chmod u+w）、`run` 包 sh -c 的 defaults 判重写（同 afm，配
   `writable_paths` + `must_succeed: false`）、三条 `terminate_process`。
   原 `ohai` 横幅无对应 DSL，删（不影响功能）。
3. **顺手治愈 audit 存量红**：url 文件名段无版本被判 unversioned（audit 收紧
   漂化，11.43.4 同型）——tag 段改 `doubao-ime-#{version}` 插值过审
   （mirage/lceda 同法）。镜像流下次更新仍会整条写回字面 url，**届时需手动
   改回插值**（11.26/11.53.6 的既有流程，watcher 不管这个）。
4. 验证链（本机未安装该 cask，全静态 + 摆拍）：style 绿；audit --strict 绿；
   `brew ruby` 的 `artifacts_list` 序列化出完整 steps JSON（DSL 合法硬证）；
   preflight 的 sh 通配在 /tmp 摆拍双安装器目录实测取对 zip 解出 app；
   `brew fetch --cask` ✔︎（插值 url 端到端）；`CaskLoader.load` 零告警
   （用户症状消失的直接证据）。真实 `install --cask` 未跑——会往用户系统
   装输入法并改输入源偏好，需要时用户自行安装即全链路验证。

### 11.61 antigravity 补丁成品：asar 静态改写全链路实录（2026-11-21 实测）

交付形态与许可破例见 1 节；本节只记执行中拿到的事实，动手前务必读完 1、2 条。

1. **asar 头部的 4 字节对齐陷阱（本轮最贵的一条）**。帧是
   `[u32=4][u32=align4(jsonLen)+8][u32=align4(jsonLen)+4][u32=jsonLen][JSON 补 NUL 到 4 字节][数据]`，
   **@4/@8 用的是补齐后的长度，@12 是真实长度**，Chromium 按 `8+@4` 定位数据区。
   若按直觉写成 `jsonLen+8`，则 `jsonLen % 4 == 0` 时**恰好正确**、不为 0 时数据区起点
   偏移 1–3 字节，`package.json` 读到尾部 NUL 填充变成 `"\n}{…"` 垃圾 →
   Electron 认为没有应用包，回落 `default_app.asar` 并打印 `Usage: electron [options] [path]`，
   且**进程照常起、无任何报错**。症状极具误导性：实测「只往 asar 加文件」能启动、
   「改任一个已有文件」就起不来——那只是 header 长度撞没撞上 4 对齐的运气，不是语义差别。
   两个已知可加载的包（Google 原始包、汉化引擎写回的包）帧一致，可当参照。
   **定位手段**（比读日志猜快一个数量级）：
   `ELECTRON_RUN_AS_NODE=1 <App>/Contents/MacOS/<App> probe.js`，用宿主自带、带 asar 支持的
   `fs` 直接读 `<x>.asar/package.json`，错误原文会告诉你在哪一步偏了。
   对策已固化：`tools/asar-lib.mjs` 的 `writeAsar` 写完立刻自校验 `8+@4 === 16+align4(jsonLen)`，
   不一致直接抛错，不产出半成品。

2. **asar 完整性 fuse 没启用**——这是整条「静态改写」路线成立的前提。官方包的
   `Contents/Info.plist` 里写了 `ElectronAsarIntegrity`（`Resources/app.asar` 与
   `default_app.asar` 都有），官方包的头块 SHA256 与 plist **逐字节一致**、779 个 packed
   文件 integrity **零失配**；汉化引擎改写 9 个模块后既不动 plist 也不重算 integrity
   （实测 9 个失配 + 头哈希对不上），应用仍正常启动并执行注入代码。结论：**改写 asar
   可行，不需要碰 plist**；本仓写包器仍为每个条目重算 integrity（约 10 行，保持自洽，
   万一 Google 将来开 fuse 至少不欠账）。

3. **禁自更新是必需项，不是偏好**。`Contents/Resources/app-update.yml` 是
   `provider: generic` + Google 的 Cloud Run 源，宿主会自己拉新版覆盖 `app.asar`，
   补丁静默消失。实测唯一通往网络的函数是 `dist/updater.js` 的 `checkForUpdates()`
   （周期检查与菜单手动都走它），另有 `startAutoUpdateChecks()`、`autoDownload`、
   `autoInstallOnAppQuit` 三处；四处锚点各出现 1 次，改写后 `AutoUpdater` 日志为 **0 行**
   （连 `Starting auto update checks` 都不再打印，说明定时器根本没 armed）。
   版本更新权因此完全交给本 tap 的 watcher + cask。

4. **ad-hoc 重签必须丢掉 hardened runtime**。汉化引擎的注释即结论：绝不能传
   `--preserve-metadata=flags,runtime`——保留硬化运行时会强制 Library Validation，
   ad-hoc 签名没有 Team ID，dyld 启动即 SIGABRT。实测重签后 `flags=0x2(adhoc)`、
   `TeamIdentifier=not set`、`codesign --verify --deep` 通过、`spctl` rejected。
   **quarantine 由 cask 的声明式 `postflight_steps` 清掉**（用户拍板：不要每次升级都
   弹 Gatekeeper）：brew 解包后会主动给 app 打 `com.apple.quarantine`（`Cask::Quarantine`），
   不清的话 ad-hoc 签名 + 隔离属性 = 首启必拦。step 用
   `run "/usr/bin/xattr", args: ["-d","-r","-s", …, "{{appdir}}/Antigravity.app"]`，
   `writable_paths` 同路径、`must_succeed: false`（macOS「App 管理」权限可能拒绝改写
   /Applications 里的 app，缺权限时只是没清掉，不该让安装失败）。
   **`-s` 不可省**：brew 把属性递归打到包内每个条目，framework 的 14 个**符号链接**
   （`Versions/Current`、`Squirrel.framework/Resources` 这类）属性挂在链接自身上，
   只 `-d -r` 清完仍剩 14 个（实测），`-d -r -s` 才归零。清完 `open -a` 直接起、无弹窗。
   与 11.22 的区分仍成立：TSKMGR 是「签名已破 → 已损坏」必须清；本包是「签名有效但
   无公证」，清隔离属性是为了免弹窗而非救损坏。cask 侧用声明式 steps（11.40/11.60），
   不写命令式 flight。

5. **额度接口在 macOS 上直通**，Windows 那套 Win32 依赖整个可以丢掉。
   `~/.gemini/antigravity/daemon/hub_*.json` 给 `{pid, httpPort, csrfToken, lsVersion}`，
   `POST http://127.0.0.1:<httpPort>/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary`
   （body `{}`、头 `X-Codeium-Csrf-Token`）实测 200，返回 3 分组 5 个 bucket 的
   `remainingFraction` + `resetTime`。Windows 侧用 `Get-NetTCPConnection` 验端口归属，
   macOS 用 `process.kill(pid,0)` + 请求成败即可。**意外发现**：监听该端口的进程可能是
   `~/.gemini/bin/agy --hub`（CLI），即桌面版没在跑也读得到额度。
   `status.json` 形状与上游 Windows 挂件保持一致，配套的 `antigravity-plugin` 额度 MCP
   仍可直接读。

6. **挂件形态：页内 DOM，不开独立窗口**（2026-11-21 用户纠正后重做；初版是透明覆盖窗，
   被否）。初版覆盖窗有两个真问题：① 宿主有 `[Auto-Restart] Port changed! Reloading all
   windows`——LS 换端口时把**所有** BrowserWindow 一起 `loadURL`，我们的浮窗被劫持去
   加载宿主登录页，用户看到「登录页上多出一块英文欢迎窗」；② 登录/欢迎页本就不该有宠物。
   现形态与汉化引擎面板同路：UI 代码（`inject/renderer/widget-page.js`）由
   `inject-widget.mjs` 追加进**宿主自己的 `dist/preload.js`**（标记块
   `__AGY_WIDGET_PAGE_START__`），preload 有 DOM 访问权，挂件直接长在页面里：
   跟窗/最小化/全屏/重载后重建全是天然行为，零窗口、零辅助功能权限。
   三个实现要点：
   - **门控**用引擎面板同款选择器 `[data-testid="agent-input-box"]`（工作台输入框）：
     登录/欢迎页没有该节点 → 不挂载；SPA 切换不重跑 preload，靠 MutationObserver
     （250ms 防抖）+ 1.5s 定时器补判。
   - **preload 是 webpack bundle**，拿 ipcRenderer 要靠 bundle 作用域里的 `electron_1`
     别名（引擎的 bridge 注入也依赖它），`require('electron')` 仅作兜底；只挂主框架
     （`top === self`）且限 127.0.0.1/localhost 的 http(s) 页。
   - **图片走 data URL**：页内拿不到 fs，主进程 `gy:portrait` 读 asar/导入目录回
     base64。实测本页 CSP 只有 `frame-ancestors`（`curl -kI` 本地服务确认），
     script/style/img 全不设限，内联 `<style>` 与 data: 图都放行。
   容器 `pointer-events:none`、交互子元素 `auto`，透明区域不吃宿主点击；拖拽用
   pointer capture 改 right/bottom 偏移并经 `gy:action{type:offset}` 持久化。
   主进程模块只留数据层（额度/图库/导入对话框/设置），`pushState` 广播给所有
   `getType()==='window'` 的 webContents，由页内自行决定挂不挂。

7. **`path.join(os.homedir(), 'Library', 'Application', 'Support')` 是错的**——
   `'Application Support'` 必须**一段**传入，否则拼成 `Library/Application/Support/…`。
   最阴的地方在于 `mkdirSync(recursive)` 和写入**都成功**，只是落到错误目录，日志无异常，
   只有去 `~/Library/Application Support/` 查才发现没落盘。已在真机跑出来后修正。

8. **仓库根目录残留的 `"type": "module"` package.json 会破坏仓库内任何 CommonJS 脚本**。
   Node 向上找最近的 `package.json` 决定模块类型；`localization_engine.js` 第一行
   `require('fs')` 因此 `ReferenceError: require is not defined in ES module scope`，
   而报错路径指向引擎自己的目录，很容易误判成上游坏了。对策两层：该文件已
   `.gitignore`（`/package.json`），且 `build.sh` 在引擎目录里显式钉
   `{"type":"commonjs"}`（仅当上游没带 package.json 时），让构建对周边环境免疫。

9. **版本形态与产物命名**：core cask 版本是 `2.33.0,4731201358004224`（Homebrew 的
   `version,build` 约定）。本包版本取 **`<宿主版本>-<宿主构建号>-cn<补丁序号>`**
   → `2.33.0-4731201358004224-cn1`：留构建号是为了让「宿主只跳构建号」的发布也能判新，
   `-cnN` 是为了让「同一宿主版本重打补丁」也有可升级的版本差。
   tag `antigravity-<版本>`、资产 `Antigravity-<版本>.dmg` 加
   `Antigravity-<版本>.dmg.sha256` sidecar（sidecar 先例见 mirage-wallpaper /
   交叉工具链，省掉每次 250MB 实算）。**版本号是 tag 与资产名的纯函数**，cask 的
   url 因此写 `#{version}` 双插值（手工重打补丁时只需动 version/sha256 两行）。
   但**插值活不过第一次自动更新**（/tmp 摆拍实测）：`UpdaterCore` 的 `replaceURLLine`
   取 `config.uploadRelease || config.downloadURL == nil`，而 customRelease 的 url 来自
   `UpstreamRelease` 而不是 `downloadURL` 模板 → 命中「按全量式整条替换 url 行」，
   写回的是含版本号的字面量（`.../antigravity-<版本>/Antigravity-<版本>.dmg`）。
   结果依然正确、audit 也照样过（版本字面就在 url 里），想要插值按 11.26 / 11.53.6
   的老办法手工改回——**别以为核心会保留插值**。
   检查器 `updater/antigravity.swift` 与 `build.sh` 的 `REVISION` **必须同步**：检查器里
   写死 `cn1`（新宿主版本的第一个补丁包），同宿主重打时人工用 `--revision 2` 构建、
   手改 cask 的 version/sha256，此时检查器算出的 `-cn1` 小于本地 `-cn2` →
   `newer-than-brew` 不动文件（防回退，符合预期）。走 customRelease、**不开 uploadRelease**
   （产物不是「下载上游」而是本地 `build.sh` 构建）。sidecar 缺失（=补丁包还没构建）时
   故意返回 `sha256: nil`，由核心的 HEAD 探测 404 → `upstream-missing` 开 issue，
   这样「需要跑构建」走既有告警通道，而不是把指向空资产的 url 写进 cask。

10. **`hdiutil create` 出的 dmg 不是逐字节可复现的**：同一份 app 连打三次得到三个 sha
    （卷时间戳等元数据内嵌）。所以 **cask 的 sha256 必须取「实际上传到 Release 的那次
    构建」的 sidecar 值**，不能拿另一次构建的顶；`build.sh --upload` 把出包与上传放在
    同一次运行里就是为了不让两者脱节。上传后以 `brew fetch --cask` 打出
    `✔︎ Cask antigravity` 为准——那才是「Release 上的字节 == cask 声明的 sha」的硬证据。

11. **上游的巡检脚本是白送的质量门**：`ag_audit.js check --asar <path>` 会从包里
    动态提取引擎依赖的 20 个锚点逐个报 `[OK]`，实测 2.33.0 全过；字典侧还顺带查
    重键/大小写/高危单字（2596 条，5 个单字预警属正常）。构建脚本把它当硬门用。
    注意它 `asar` 子命令**不认 `--asar`**（只有 `check` 认），单独跑 `asar` 会报
    「未定位到 app.asar」，别误判成包坏了。

12. **从 core 版切过来时，「手动删掉 .app」会卡住本包安装**：cask 元数据还登记着
    core 的 `antigravity`（`brew list --cask` 有、`/usr/local/Caskroom/antigravity/` 在），
    但 `/Applications/Antigravity.app` 已被人手动拖走。此时装本 tap 的同名 cask，
    brew 走「同名先卸旧版」路径，卸载阶段找不到 app 直接
    `Error: bemly/tahoe/antigravity: It seems the App source '/Applications/Antigravity.app' is not there.`
    ——`brew list --cask --versions | grep` 这类检查看不到它（元数据在、文件不在，
    版本目录已是空的）。清掉这条僵尸登记即可：
    `brew uninstall --cask --force antigravity`（只删登记与空的 Caskroom 目录），
    然后重装本 cask 一次过。用户侧遇到同一句报错也是这个原因，caveats 里那句
    「先卸 core 版」要用 `--cask --force` 才治得住。

13. **两条 cask 侧的工程常识**：
    - `Cask/ArrayAlphabetization` 的排序键是 **`line.strip.downcase`**（源码
      `rubocops/cask/array_alphabetization.rb`，大小写不敏感），所以照抄 core 的
      `zap` 清单再插一条自己的目录时，`…/Application Support/com.apple.sharedfilelist/…`
      必须排在 `…/Application Support/GeminiNiangWidget` **前面**（`c` < `g`），
      按「大写字母开头的名字在前」的直觉排会红。`brew audit --strict` 内部会跑同一套
      cop，所以它报的 exit 1 常常就是 style 红，别只盯 audit 的文案。
    - 本机（Intel）单文件 `brew style` 要 **6–10 分钟**（portable-ruby + 全部 cop，
      实测 97% CPU 在算，不是死锁）。别按 `pkill -f "brew style"` 杀——真正的进程是
      `brew.rb style` 与 `vendor/.../rubocop.rb`，模式不匹配只会留下一堆
      `--parallel` 孤儿 worker。要判死活看 `%cpu`，不是看存活时间。

14. **本机验收证据（2.33.0-4731201358004224-cn1，sha `b7213237…`）**：
    `brew style --cask` 零 offense；`brew audit --strict --cask` 在**已安装**状态下
    exit 0（zap/uninstall 与真实残留的比对一并过）；`brew fetch --cask` 出
    `✔︎ Cask antigravity`（Release 上的字节 == cask 声明的 sha）；
    `install --cask` 装成 519MB，`codesign --verify --deep` 有效、`TeamIdentifier` 未设、
    `spctl` rejected（预期，见第 4 条）；quarantine 全包计数 **0**，`open -a` 直接起、
    无 Gatekeeper 弹窗；从安装位置起进程，`AutoUpdater` 相关日志 **0 行**；
    与官方包对比 CJK 汉字净增 **145,094** 个（字典确实进了交付物）；
    包内 13 个内置角色 + `custom-<32hex>` 导入通路（`DATA_DIR/characters.json` 持久化）。
    cn2（页内 DOM 形态）复验：preload 含页内块、登录页**不挂载**（无「页内挂件就绪」
    日志）、主进程零窗口创建；用户登录后 cn3 日志出
    `页内挂件就绪：角色图=loaded 额度行数=5 语录=45 条 工作台=true` 与
    `补充词典生效：累计替换文本节点 N 个`——挂载门与词典都在真工作台里生效。
    终端无屏幕录制权限，看不了截图，模型菜单的肉眼验收交给用户。

15. **汉化引擎跟「宿主版本的 tag」，不 pin commit**（2026-11-21 用户纠正后改）。
    上游 `Silas-02/antigravity-desktop-cn` 是**按 Antigravity 版本打 tag** 的
    （`v2.33.0`、`v2.33.0.1`…每个宿主版本一对，通常两天内跟上），初版 pin 死 commit
    意味着宿主每次升版都要人工改脚本，是错的。现 `build.sh` 用
    `git ls-remote --tags`（不耗 API 限额）取 `v<宿主版本>` 与 `v<宿主版本>.<n>` 里
    版本号最大者；**tag 缺失 = 上游还没适配 → 直接 die**，绝不拿旧字典硬上（旧字典
    锚点对不上，最坏是「装得上但没汉化」）。`--cn-ref <tag|commit>` 保留人工锁定口子。
    实测 `v2.33.0.1` peel 后正是初版 pin 的 `c6ba0b83…`，重跑构建 `app.asar` 与已发布
    产物逐字节一致（`9b8f9789…`）——tag 化不改变内容，故无需重传 dmg。
    **门当天就真拦了一次**：core 把宿主升到 2.33.1 而引擎尚无 `v2.33.1` tag，构建按设计
    die；该轮改用 `--version 2.33.0 --build …` 显式锁旧宿主出补丁版。等引擎跟上后再跑
    一次默认解析即回到自动跟版。

16. **补充汉化词典是自有注入层，不改上游引擎**（`inject/extra-l10n.js`，标记块
    `__AGY_EXTRA_L10N_START__`，追加在页内挂件块之后）。上游字典没覆盖模型名，用户要求：
    Gemini→哈基米、元素代号→周期表中文字（**全表 118 元素**，含 Aluminium/Cesium 等
    双拼写）、Claude→克劳德、Opus→巨著 / Sonnet→十四行诗 / Haiku→俳句 / Fable→神话 /
    Flash→闪电 等、思考档位 Low/Medium/High→低/中/高、New→新。
    实现是文本节点替换 + MutationObserver，四条硬约束：
    - **只改可见文本节点**，`script/style/textarea/input/select/code/pre/.monaco-editor/
      .xterm/[contenteditable]` 整子树剪枝——模型 id 与编辑器/终端内容保持英文，
      服务端标识不被破坏；
    - TreeWalker 用**元素级 FILTER_REJECT 剪枝**（SHOW_ELEMENT|SHOW_TEXT），否则 Monaco
      里每个文本节点都要跑一次 `closest`，忙时卡死；也不做周期性全 body 重扫，
      新增节点走 addedNodes、改字走 characterData；
    - `\b` 词边界 + 长词优先：`Leading`/`Golden` 不被 `Lead`/`Gold` 误伤（样本串实测）；
    - 计数上报**只在变化时**发 `gy:l10n`（初版每 500ms 重发同值，日志刷屏，cn4 修）。
    替换幂等：译成中文后不再命中拉丁模式，observer 回环自然终止。

### 11.62 github-copilot-app 补丁成品：Tauri 运行时注入全链路（2026-11-21）

宿主与 antigravity 完全不同，**没有 asar 可改**，所以走运行时注入。动手前读完 1–4 条，
第 2 条是本轮最贵的坑（探针几秒就证伪了初版方案，省下一次 CI 空跑）。

1. **宿主形态**：GitHub Copilot 桌面版是 **Tauri（WKWebView）**，前端资源 brotli 压在
   500MB+ 的 `Contents/MacOS/github` 里；bundle id `com.github.githubapp`；另有
   `Contents/MacOS/git-credential-copilot`、`Contents/Frameworks/*.dylib`（4 个）、
   `Contents/Resources/plugins/computer-use/`（含嵌套 app 与 mcp 二进制）、
   `embedded.provisionprofile`。上游中文插件 `shuhuNB515/githubcopilot-desktop-zh-mac`
   是 **MIT**（`licenses/ZH-MIT.txt` 随仓），手法是 `DYLD_INSERT_LIBRARIES` 注入
   `CopilotCN.dylib`，swizzle `-[WKWebView initWithFrame:configuration:]` 挂
   `WKUserScript`，词典/脚本从 `COPILOT_CN_DIR` 读。上游只编 arm64，本仓改 `-arch x86_64`
   （实测可编，无 arm64-only API）。

2. **`LSEnvironment` + `@executable_path` 会 SIGABRT 掉所有子进程（探针实测，初版方案被证伪）**。
   初版想「不改 Mach-O、不用启动器」：Info.plist 写
   `LSEnvironment:DYLD_INSERT_LIBRARIES = @executable_path/../Resources/CopilotCN/*.dylib`。
   主进程确实注入成功，但 **LaunchServices 设的环境会被所有子进程继承**，而
   `@executable_path` 在子进程里按**子进程自己的**可执行文件路径展开 → 路径不存在 →
   dyld 直接 SIGABRT。证据：`/tmp` 造最小 app bundle（`probe` + `libprobe.dylib` +
   一个普通 ad-hoc 签名的 `child`），`open` 启动后 `main.log` 里 `ctor_marker=present`
   但 `child_rc=6`、`child.log` 空。Copilot 会大量 spawn git / shell / MCP 子进程，
   这条路等于把功能全废掉。**改用启动器 + 绝对路径后同一探针 `child_rc=0`、子进程正常输出**
   （子进程也会载入注入库，但两个库都有主程序判定，非主进程直接 return，无副作用）。
   方法论：**这种「dyld/签名/环境」假设先用几秒编译的最小探针验证，别拿 500MB 真包赌 CI**。

3. **启动器形态**：官方主二进制改名 `Contents/MacOS/github-real`，`CFBundleExecutable`
   仍指 `github`——那个位置换成自编译的 `launcher.c`：`_NSGetExecutablePath` + `realpath`
   拿到自身目录 → 拼两个 dylib 的**绝对路径**（GyWidgetCN 在前）→ `setenv` → `execv`
   `github-real`（argv[0] 换成真实路径）。**dylib 缺失时照常 exec**（fail-soft：界面回英文
   但 app 能用，绝不拦启动）。两个注入库的主程序判定都要认 `github-real`：上游
   `CNIsMainApp` 与本仓 `GyIsMainApp` 都是「exe 后缀 **or** bundle id」，bundle id 兜住了，
   本仓仍显式加了后缀分支。**不要删 `embedded.provisionprofile`**（上游也不删）。

4. **签名照上游 `src/sign.sh` 逐组件签，不用 `--deep` 一把梭**：`--deep` 会把主程序的
   entitlements 灌给所有嵌套代码，而上游给 `git-credential-copilot` 用的是另一份
   `ent-git-credential.plist`（只有 audio/camera），computer-use 两个二进制单独签。
   顺序：Frameworks 的 dylib（ad-hoc，无 runtime）→ git-credential（runtime + 它自己的 ent）
   → computer-use-mcp / 嵌套 app（runtime）→ **`github-real`（runtime + 注入 ent）**
   → app 本体（runtime + 注入 ent，不带 --deep）。
   **`github-real` 必须显式签**：不带 `--deep` 的 codesign 不会重签嵌套 Mach-O，漏了它
   dyld 就会剥掉启动器设的 `DYLD_INSERT_LIBRARIES`。
   **保留 hardened runtime 也能注入**——靠的是 `disable-library-validation` +
   `allow-dyld-environment-variables` 两条例外 entitlement（ad-hoc 签名同样被承认，探针实证）。
   这与 11.61 第 4 条「antigravity 必须丢 runtime」不矛盾：那边**压根没传 entitlements**。

5. **运行时文件落用户目录，且每次启动覆盖同步**：`~/Library/Application Support/CopilotCN`
   （往签名过的 bundle 里写文件会破坏封印）。GyWidgetCN 构造函数 `setenv COPILOT_CN_DIR`
   并把包内 `runtime/{dict,translator,bridge,collector,menu}.json|js` 与 `gy/pet.js`
   同步过去——**不是「缺才补」**：否则升级后旧词典/旧宠物会一直留着。用户自己的数据在
   `dumps/`、`queue/`、`copilot-cn.log` 与宠物的 localStorage 里，不受影响。
   装载顺序 GyWidgetCN 在前（它负责铺目录与设 env），上游库随后读同一目录。

6. **词典重建**：上游 `tools/build_dict.py` 自己 `chdir` 到仓库根（读 `src/dict-*.tsv`
   写 `runtime/dict.json`），从任意 CWD 跑都安全；但它对 BAD/DUP 行**只打印不失败**
   （`DUP: Show the GitHub Copilot icon in the / menu bar` 是上游自带的重复键，正常），
   所以本仓加了「JSON 可解析 + 条目数下限」自检。**下限要按实测定，别猜**：
   初版写 `>1000` 把 CI 拦红了——上游 v1.0.1 实际只有 **504 条 / 39KB**，现取 300
   （只拦「词典几乎为空」的真故障）。质量门宁可宽到只拦真故障，也不要拿臆测的规模当门。

7. **宠物是纯 DOM，没有 Electron 那套 IPC/fs**：WKWebView 里拿不到 `ipcRenderer`，
   所以 13 个内置角色（base64 data URL，约 3.2MB 原图）+ 45 条语录在**构建期**打进
   `gy/pet.js`（`pet-template.js` 的 `__PAYLOAD__` 占位由 node 替换，替换后 grep 不到占位才算过）；
   导入自己的图片走隐藏 `<input type=file>` + FileReader + **localStorage**（有配额上限，
   超了要提示而不是静默失败），设置也存 localStorage。素材与 antigravity 页内挂件同源
   （`Widgets/antigravity-niang/characters` + `assets/quotes.json`），实现各写一份。

8. **自更新未禁用，且 cask 不能写 `auto_updates true`**：Tauri updater 嵌在二进制里，
   静态禁用代价过高。上游 `launch.sh` 的做法是每次启动检测签名被还原就重签（1–2 分钟 +
   依赖用户目录里的脚本），本仓不引入这套——cask 成品应自包含。改为 caveats 明示
   「一旦自更新，补丁被官方包覆盖、界面回英文 → `brew reinstall --cask`」。
   连带：`auto_updates true` 会让 `brew upgrade` **跳过**这个 cask，补丁更新就永远送不到，
   所以必须去掉（本包更新权归 brew）。

9. **版本 / 检查器 / CI 顺序**：版本 `<宿主版本>-cn<N>`（宿主版本取 core cask API 的
   `.version`，无构建号段）；tag `github-copilot-app-<版本>`、资产
   `GitHub-Copilot-<版本>.dmg` + `.sha256` sidecar；检查器 `customRelease` + sidecar、
   不开 `uploadRelease`（同 antigravity）。`patched.yml` 的步骤顺序是
   **构建 → 把 sidecar 的 version/sha 写回工作区 cask → lint → 绿了才提交 cask**：
   lint 必须在构建之后，才能审到「维护者将要提交的那份文件」；首轮 CI 就是因为
   lint 在前、审到 main 上那份**资产名无版本的字面 url** 而红（`Use sha256 :no_check
   when URL is unversioned`，11.43/11.53 的存量漂化）。新收录时 cask 的 sha 可先写
   `PENDING_CI_SIDECAR`，由 workflow 填实——**占位只在 main 上短暂存在，CI 自愈**。

10. **裸 `clang` 在开发机找不到 SDK 头**（`stdio.h file not found`）：一律 `xcrun clang`
    （CI 上裸 clang 可能可用，但别赌）。`xcrun swiftc` 同理（11.61 同轮踩过）。

11. **`$VAR` 紧跟中文标点会被 bash 吞掉一个字节（CI 首轮 9 秒即红）**：
    `say "官方包：$APP_VERSION（Intel 直链…"` 在 runner 上报
    `APP_VERSION\xef: unbound variable`——bash 的变量名合法性判断走 `isalnum()`，
    **受 locale 影响**，某些 locale 下高位字节（中文全角括号的首字节 0xEF）被当成名字的一部分。
    开发机 locale 不同，`bash -n` 也查不出来（语法合法，运行才炸）。
    修法：凡 `$VAR` 后面紧跟非 ASCII 字符，一律写 `${VAR}`。本轮用脚本扫全仓
    `*.sh` 与 workflow（正则 `\$([A-Za-z_][A-Za-z0-9_]*)(?=[\x80-\xff])`），
    copilot 6 处 + antigravity 7 处 + patched.yml 1 处全部加花括号。
    **写含中文提示的 shell 时，变量一律带花括号**，别省。

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
      `ghcr.io/v2/bemly/tahoe`，不是 GitHub Releases——早期设想已废弃，见 6 节
      「qemu 代编译模式」）。qemu + capstone/dtc/libslirp/vde 已收录并本机验收。
- [x] **anomalyco 分支（feat/anomalyco-3）已合并回 main 并逐个制瓶完成**（2026-09-03~04）：
      `ea02f08 Merge branch 'feat/anomalyco-3' into main`；opencode/sst/torpedo/ripgrep 走 raw 流
      公式 + 代编译/直引流程逐个制瓶（Log 见 `bottle: 更新 GHCR 瓶块（opencode,sst,torpedo）`、
      `（ripgrep）`），workbuddy/doubao-ime cask 也已落地；15 个公式现均带 `bottle do` 块。
      合并时的 worktree 注意事项已失效（分支已合回 main，软链指向 main 即可）。
- [x] **watcher 已覆盖全部版本来源**：brew 公式（模板 / 全量）、brew cask、raw（单 / 双架构）、
      github release tag、上游自有接口，以及双架构产物、`alwaysUpdate`。`versions.head`
      仍不跟踪（本 tap 不装 HEAD 版），需要时再扩展。
- [ ] 接入 `brew livecheck` 作为可选的辅助检查手段。
- [ ] 新增 `fork-*` / 同名接管包时，同步更新 6.2 / 6.3 两张表（清单即依赖闭包的事实来源）。
