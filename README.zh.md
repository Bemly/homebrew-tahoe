# bemly/tahoe

[English](README.md) | 中文说明

一个 Homebrew 第三方 tap，专为 **Intel（x86_64）Mac 上的 macOS 26（Tahoe）** 提供可直接安装的软件。

## 为什么

Homebrew 官方从 macOS 26 起不再为 Intel 构建 bottle。实测 core tap 中 `x86_64_tahoe` 瓶的数量为 0，
`gh`、`node` 等软件在 Intel Mac 上若不走第三方瓶只能从源码编译。

本 tap 优先取上游官方的 **macOS amd64 预构建包**制瓶（不重新编译）；对于上游仅发源码的软件及无 Intel 瓶的运行时依赖层（`fork-*` / 同名接管），由 **CI 在 `macos-26-intel` 上一次性代编译成瓶**并分发到 **GHCR**（`ghcr.io/v2/bemly/tahoe`），用户端始终装瓶、不在本地编译；桌面应用与输入法走 **cask** 并镜像到本仓 GitHub Release。

## 要求

- 处理器：**Intel（x86_64）**，Apple Silicon 请勿使用（直接用 `homebrew/core` 即可）
- 系统：**macOS 26（Tahoe）** 或更高

公式内已用 `depends_on arch: :x86_64` 与 `depends_on macos: :tahoe` 强制校验，条件不满足会直接拒绝安装。

显式例外：
- `opencode` / `ripgrep`：双架构公式（仍强制 `macos: :tahoe`；Intel 走本源 GHCR 瓶，Apple Silicon 走上游直链或源码构建）。
- `afm`：仅 Apple Silicon（`depends_on arch: :arm64`）的自有输入法 cask（Intel 机直接拒绝安装）。
- universal / 双架构 cask（`amd`、`brewui`、`doubao-ime`、`heliport`、`konsole`、`macos-tskmgr`、`palera1n`、`qwen-ime`、`winstart`、`zcode`）：同时支持 Intel 与 Apple Silicon。

## 安装

```bash
brew tap bemly/tahoe

# 若之前装过 homebrew/core 的 gh / fastfetch / opencode，必须先卸载：
# 同名公式跨 tap 不能共存，brew 会直接拒绝安装
brew uninstall gh
brew uninstall fastfetch
brew uninstall opencode # core 的 opencode 是 npm 版，同名

brew install bemly/tahoe/gh
brew install bemly/tahoe/fastfetch
brew install bemly/tahoe/opencode # 会连带装上本 tap 的 ripgrep 依赖

# workbuddy 是桌面 app，走 cask（装进 /Applications，Launchpad/Spotlight 可见）
brew install --cask bemly/tahoe/workbuddy
# doubao-ime 是输入法，走 cask（装进用户级 ~/Library/Input Methods 免 sudo，并自动写入系统输入源启用）
brew install --cask bemly/tahoe/doubao-ime
# antigravity 也走 cask，但分发的是「打补丁的成品」：app.asar 里已静态注入中文汉化
# 与伴生挂件，并禁用应用内自动更新（否则补丁会被官方新包覆盖）。
# 重签是 ad-hoc（无公证）；cask 安装后会清掉隔离属性，正常免 Gatekeeper 弹窗。
brew install --cask bemly/tahoe/antigravity
```

## 收录的软件

> 共收录 **146 个公式**（61 个预编译直引 + 74 个源码代编译 + 11 个 `fork-*` 依赖层）与 **25 个 cask**。

### CLI 与开发工具 — 预编译直引公式（61 个）

| 软件 | 说明 |
| --- | --- |
| `aarch64-unknown-linux-gnu` | 面向 aarch64 Linux 的 GCC 交叉工具链（Intel host 预编译，thin x86_64）；运行时依赖走本源 `guile`、`python@3.14`、`fork-bdw-gc`、`fork-xz`、`fork-zstd` |
| `antigravity-cli` | Google Antigravity CLI（装成 `agy` 命令），官方 Intel macOS 扁平二进制重打包；版本跟随官方 auto-updater manifest |
| `boost@1.85` | Boost C++ 库 1.85，取第三方 `prebuilt-boost` 的 macOS x86 `static+shared` 包（预编译 dylib 补 `@rpath` 后 ad-hoc 重签）；`freeling` 依赖；与 core 同名 |
| `bun` | JS 运行时 / 打包 / 包管理器，取官方 Intel 预编译包（`bun-darwin-x64.zip`，提供 `bun` 与 `bunx` 软链）；与 core 同名 |
| `caddy` | 自带自动 HTTPS 的可扩展 Web 服务平台，上游 Intel 静态构建（`caddy_<ver>_mac_amd64.tar.gz`） |
| `chisel` | 基于 HTTP(S) 的快速 TCP/UDP 隧道工具，官方 Intel 裸二进制（`chisel_<ver>_darwin_amd64.gz`，零依赖）；与 core 同名异物（core 版是 LLDB 命令集），先卸一方再装 |
| `cmake` | 跨平台构建工具，上游 universal macOS 包（Intel 切片）；core 无 Intel 瓶，秒装代替源码编译 |
| `cmd` | 终端 AI 编程 agent，npm 包 `command-code`（只暴露 `cmd` 命令）；依赖本 tap 的 `node` 瓶；锁定版本不检查更新 |
| `deepseek-harness` | DeepSeek agent harness，npm 包 `@deepseek-ai/dsh`（只暴露 `dsh` 命令，`dsh web` 起浏览器 UI）；依赖本 tap 的 `node` 瓶；版本跟随 npm `latest` |
| `docker` | Docker 命令行客户端，取官方 macOS x86_64 静态二进制（`docker-<ver>.tgz`）并生成补全；与 core 同名 |
| `docker-buildx` | Docker Buildx 插件，官方 `buildx-v<ver>.darwin-amd64` 裸二进制；版本跟随 `homebrew/core` |
| `docker-compose` | Docker Compose 插件，官方 `docker-compose-darwin-x86_64` 裸二进制；版本跟随 `homebrew/core` |
| `dotnet` | .NET SDK，官方 macOS x64 tarball 重打包（整包进 prefix + `dotnet` 垫片）；版本跟随微软 release-metadata API；与 core 同名 |
| `exiftool` | 读写/编辑图片元数据的 Perl 工具，取官方 `Image-ExifTool-<ver>.tar.gz` 直装（省略 core 版可选 XS/Brotli/LZMA 模块）；与 core 同名 |
| `fastfetch` | 类 neofetch 的系统信息工具，直接取 `fastfetch-macos-amd64.tar.gz`（release tag 无 `v` 前缀） |
| `ffmpeg` | FFmpeg 本体，evermeet 的 Intel x86_64 静态构建（`ffmpeg-<ver>.zip`）；版本跟随 `homebrew/core` |
| `ffplay` | FFmpeg 播放器，evermeet 静态构建，与本 tap 的 `ffmpeg` 同版本；core 无此公式 |
| `ffprobe` | FFmpeg 流分析器，evermeet 静态构建，与本 tap 的 `ffmpeg` 同版本；core 无此公式 |
| `ffserver` | 上游已移除（4.0）的流媒体服务器，最后一个静态构建 3.4.2；锁定版本不检查更新 |
| `fish` | 友好交互式 shell，取官方 `fish-<ver>.app.zip` 内的 unix 树（universal 二进制的 Intel 切片）；版本跟随 `homebrew/core` |
| `frida-server` | Frida 动态插桩服务端，frida/frida 官方裸二进制（仅 Intel）；需 `sudo` 运行，默认监听 `127.0.0.1:27042` |
| `fzf` | 命令行模糊查找工具，上游 `fzf-<ver>-darwin_amd64.tar.gz` 单二进制；版本跟 GitHub release |
| `gh` | GitHub 官方 CLI，直接取 `gh_<ver>_macOS_amd64.zip` |
| `git-lfs` | Git 大文件扩展，上游 Intel 构建（带全套 man 页，`git-lfs-darwin-amd64-v<ver>.zip`）；装完手动跑一次 `git lfs install` |
| `go` | Go 工具链，官方 `go<ver>.darwin-amd64.tar.gz`（自包含零依赖）；版本跟随 `homebrew/core` |
| `h2spec` | HTTP/2 协议一致性测试器，官方 `h2spec_darwin_amd64.tar.gz` |
| `hyperfine` | 命令行基准测试工具，官方 `hyperfine-v<ver>-x86_64-apple-darwin.tar.gz`（带 man 页与补全） |
| `iperf3` | 网络带宽测速工具，静态构建（`iperf3-amd64-osx-15`，无 `openssl@4` 依赖） |
| `jadx` | Dex 转 Java 反编译器（含 `jadx` 与 `jadx-gui`），直接取官方 `jadx-<ver>.zip` 预编译包；依赖本 tap 的 `openjdk`；与 core 同名 |
| `jpeg-turbo` | JPEG 编解码库，官方 universal2 DMG 重打包（thin x86_64、重定位 dylib/rpath）；`qemu` 依赖 |
| `lima` | macOS 上的 Linux 虚拟机工具（`limactl`/`lima` 等），取官方 `lima-<ver>-Darwin-x86_64.tar.gz` 预编译包并生成补全；与 core 同名 |
| `llvm` | 编译器基础设施，上游 19.1.7 Intel 预编译 pinned（后续版本仅 ARM64；23.x 源码编译超 6 小时 CI 上限）；thin x86_64，零依赖，keg-only；bindgen 用 `LIBCLANG_PATH` 指过去即用 |
| `llvm-mingw` | LLVM/Clang 的 mingw-w64 交叉工具链（Intel host → Windows），版本跟 GitHub release |
| `mufetch` | 系统信息工具，取 release 的 `mufetch_darwin_x86_64.tar.gz` |
| `nasm` | 官方 NASM 3.02 macOS universal 预编译包（thin x86_64，含 `nasm`/`ndisasm`）；`svt-av1` 构建依赖；与 core 同名 |
| `ninja` | 小而快的构建系统，上游 universal 包（Intel 切片） |
| `nzbget` | 二进制新闻组下载工具，官方 `nzbget-<ver>-bin-macos-x64.zip` 预编译包（CLI + WebUI）；运行时使用本仓 `sevenzip`；与 core 同名 |
| `node` | Node.js 运行时，直接取官方 `node-v<ver>-darwin-x64.tar.gz` |
| `node@20` | Node.js 20 LTS，直接取官方 `node-v20.x-darwin-x64.tar.gz`；与 core 同名 |
| `node@22` | Node.js 22 LTS，直接取官方 `node-v22.x-darwin-x64.tar.gz` |
| `node@24` | Node.js 24 LTS，直接取官方 `node-v24.x-darwin-x64.tar.gz` |
| `opencode` | AI 编程 agent，取 `anomalyco/homebrew-tap` 的 mac 双架构段（Intel 走瓶、ARM 走直链）；依赖 `bemly/tahoe/ripgrep`；与 core 的 npm 版同名 |
| `openjdk` | OpenJDK 26 GA 官方 macOS x64 预编译包（`keg_only`）；与 core 同名 |
| `openjdk@17` | Eclipse Temurin 17 x64 JDK（Adoptium API 判新，`keg_only`）；与 core 同名 |
| `openjdk@21` | Eclipse Temurin 21 x64 JDK（Adoptium API 判新，`keg_only`）；与 core 同名 |
| `openjdk@26` | OpenJDK 26 GA 官方 macOS x64 预编译包（`keg_only`，锁 26 线）；与 core 同名 |
| `postgresql@13` | PostgreSQL 13，EDB 官方 macOS x64 二进制包重打包（只装 bin/include/lib/share，跳过 pgAdmin 等 app）；`keg_only` 避免自带 openssl/icu 撞 core；把 `opt/postgresql@13/bin` 加进 `PATH` 使用 |
| `protobuf` | Protocol Buffers 编译器（`protoc` + 头文件），官方 macOS x86_64 预编译包（`protoc-<ver>-osx-x86_64.zip`）；与 core 同名 |
| `ripgrep` | 快速文本搜索工具，官方 macOS x86_64/arm64 预编译且带 PCRE2；零构建依赖；`opencode` 依赖 |
| `rustup` | 官方静态 Rust 工具链安装器，与 core 同名；提供 `rustup` 及 cargo/rustc 代理垫片，工具链走 `rustup toolchain install stable` |
| `scrcpy` | 安卓投屏工具，上游 Intel 静态构建（零运行时依赖，内置 `adb` 与 `scrcpy-server`） |
| `sevenzip` | 官方 7-Zip 26.06 Intel 预编译（`7zz`）；是 `binwalk`、`nzbget` 的运行时依赖及 `jpeg-turbo` 的构建依赖；与 core 同名 |
| `sst` | SST 开发框架，取 `anomalyco/homebrew-tap` 的 Intel 段（`sst-mac-x86_64.tar.gz`） |
| `starship` | 跨 Shell 提示符工具，取官方 x86_64 预编译包（`starship-x86_64-apple-darwin.tar.gz`）并生成补全；与 core 同名 |
| `swift` | 官方 Swift macOS `.pkg` 重打包，只暴露 `swift`/`swiftc`（不污染其它工具链）；版本跟 swift.org |
| `torpedo` | `sst/torpedo` VPC 数据库访问工具，取 `anomalyco/homebrew-tap` 的 Intel 段（`torpedo-mac-x86_64.tar.gz`） |
| `x86_64-unknown-linux-gnu` | 面向 x86_64 Linux 的 GCC 交叉工具链（Intel host 预编译，thin x86_64）；运行时依赖走本源 `guile`、`python@3.14`、`fork-bdw-gc`、`fork-xz`、`fork-zstd` |
| `xcodegen` | 按配置文件生成 Xcode 工程，取官方 universal 预编译包（`xcodegen.zip`，含 `SettingPresets`，零依赖）；与 core 同名 |
| `yt-dlp` | 音视频下载器，上游 universal macOS 单二进制（零依赖，不拖整套 Python 栈） |
| `z3` | 高性能定理证明器，官方 macOS x64 预编译包（`z3-<ver>-x64-osx-13.3.zip`，零依赖）；与 core 同名 |
| `zig` | Zig 工具链，官方 `zig-x86_64-macos-<ver>.tar.xz`（Intel host）；与 core 同名 |

### 源码代编译公式（32 个工具与专用栈）

在 `macos-26-intel` CI 上从 `homebrew/core` 或上游源码一次性编译出瓶，经 GHCR 分发。

| 软件 | 说明 |
| --- | --- |
| `aria2` | 多协议下载工具（`c-ares`/`libssh2`/`sqlite`/`fork-openssl@4`/`fork-gettext`）；与 core 同名 |
| `automake` | GNU Automake 构建工具（运行时依赖 `autoconf`）；与 core 同名 |
| `bash` | GNU Bash 5.3（`ncurses`/`fork-readline`/`fork-gettext`）；与 core 同名 |
| `binwalk` | 固件分析与嵌入式文件提取，内嵌官方 Rust 1.91.1 rustc/cargo/rust-std 构建资源；backport `7zz` 并依赖本仓 `sevenzip`；与 core 同名 |
| `capstone` | 反汇编框架（`fork-gettext`），`qemu` 依赖 |
| `curl3` | 独立 HTTP/3 客户端（含 MASQUE/CONNECT-UDP 的 `--enable-proxy-http3`，core 没开）；改名与 core 的 curl 共存，仅提供 `curl3` 命令 |
| `dtc` | 设备树编译器（`libyaml`），`qemu` 依赖 |
| `freeling` | 自然语言分析器套件（分词 / 词性标注 / 命名实体等），解捆自带 dynet/eigen，改用 `boost@1.85`、`dynet`、`icu4c@78`；与 core 同名 |
| `git` | 分布式版本控制系统（macOS 用 CommonCrypto，依赖 `pcre2`/`fork-gettext`）；与 core 同名 |
| `gnupg` | GNU Privacy Guard（OpenPGP），使用 `gnutls`、`libusb`、`fork-readline`、`fork-gettext` 与 GnuPG C 库全家桶；与 core 同名 |
| `graphviz` | 图形可视化软件，零运行时依赖构建（Quartz 与内置插件支持 PDF/PNG/SVG） |
| `libimobiledevice` | iOS 设备通信工具集（`idevice*`），使用本源 `libimobiledevice-glue`、`libplist`、`libtatsu`、`libusbmuxd`、`libtasn1`、`fork-openssl@4` |
| `libimobiledevice-glue` | `libimobiledevice` 胶水库（`libplist`）；与 core 同名 |
| `libnghttp3` | HTTP/3 C 库，`curl3` 依赖 |
| `libngtcp2` | QUIC 协议 C 库（`fork-openssl@4`），`curl3` 依赖 |
| `libplist` | Apple Property List 库，`libimobiledevice` 栈基础库 |
| `libslirp` | 用户态网络库（`glib`），`qemu` 依赖 |
| `libtatsu` | Apple TSS 库，`libimobiledevice` 栈依赖 |
| `libusbmuxd` | iOS 设备 USB 复用库 |
| `make` | GNU make（装成 `gmake`）；core 虽有 tahoe 瓶仍镜像 |
| `mercurial` | 分布式版本控制系统（`hg` + `chg`），使用本 tap 的 `python@3.11` 现编出瓶；与 core 同名 |
| `meson` | 快速构建系统，依赖本 tap 的 `ninja` + `python@3.15` 出瓶，不再拖 core 的源码 Python；与 core 同名 |
| `neofetch` | 系统信息脚本（上游已归档最后一版 7.1.0）；锁定版本不检查更新 |
| `nghttp2` | HTTP/2 客户端工具集（`nghttp`/`h2load`/`nghttpx`，`--enable-app`，`c-ares`/`jemalloc`/`libev`/`libnghttp2`/`fork-openssl@3`） |
| `python@3.11` | Python 3.11 解释器（`mpdecimal`/`sqlite`/`fork-openssl@3`/`fork-xz`）；`mercurial` 依赖；与 core 同名 |
| `python@3.15` | Python 3.15 解释器（`mpdecimal`/`sqlite`/`fork-openssl@4`/`fork-xz`/`fork-zstd`）；`meson` 依赖；与 core 同名 |
| `qemu` | 通用模拟器/虚拟机（全量 68 目标，完整依赖闭包已在本仓出瓶） |
| `socat` | SOcket CAT 中继工具（`fork-openssl@3`），源码现编出瓶 |
| `vde` | 虚拟分布式以太网（Clang 26 下加 `-std=gnu17`），`qemu` 依赖 |
| `wabt` | WebAssembly Binary Toolkit（`wat2wasm`/`wasm2wat` 等，`fork-openssl@4`；上游 macOS 包仅 arm64） |
| `wget` | 命令行下载工具（`libidn2`/`libpsl`/`fork-openssl@4`/`fork-gettext`/`fork-libunistring`）；与 core 同名 |
| `wimlib` | 创建 / 解包 / 修改 WIM 映像的库与 `wimlib-imagex` 工具（macOS 零运行时依赖，`fork-pkgconf` 构建） |

### 运行时依赖层 — 同名接管（42 个源码库）与 `fork-*`（11 个）

`homebrew/core` 中无 `x86_64_tahoe` 瓶的运行时依赖，按「无 core 依赖方则同名接管、有 core 依赖方则保留改名 `fork-*`」打包出瓶：

- **同名接管的运行时依赖（42 个源码库，连同上述 32 个共 74 个源码代编译公式；`boost@1.85` 预编译包亦属同名依赖）**：
  `abseil`、`brotli`、`c-ares`、`dynet`、`eigen@3`、`glib`、`gnutls`、`guile`、`icu4c@78`、`jemalloc`、`json-c`、`libassuan`、`libev`、`libgcrypt`、`libgpg-error`、`libidn2`、`libksba`、`libnghttp2`、`libpng`、`libpsl`、`libssh`、`libssh2`、`libtasn1`、`libusb`、`libyaml`、`lz4`、`lzo`、`mpdecimal`、`ncurses`、`nettle`、`npth`、`p11-kit`、`pcre2`、`pinentry`、`pixman`、`python@3.14`、`simdjson`、`snappy`、`spirv-tools`、`sqlite`、`svt-av1`、`vulkan-loader`
  *（注：`vulkan-loader` 仅运行时依赖在 core 中拥有 `all` 瓶的 `vulkan-headers`。）*
- **改名且 `keg_only` 的 `fork-*` 依赖（11 个）** *（不与 `homebrew/core` 冲突，按全名 `bemly/tahoe/fork-*` 引用）*：
  `fork-bdw-gc`、`fork-bison`、`fork-gettext`、`fork-gmp`、`fork-libunistring`、`fork-openssl@3`、`fork-openssl@4`、`fork-pkgconf`、`fork-readline`、`fork-xz`、`fork-zstd`

### 桌面应用与输入法 — Cask（25 个）

| Cask | 架构 | 说明 |
| --- | --- | --- |
| `afm` | arm64 | AFM 拼音输入法（仅 Apple Silicon 的自有软件例外）；装进 `~/Library/Input Methods` 并自动启用输入源；锁定版本 |
| `amd` | universal | 自有歌词汉化下载器 + `obcli` 命令行；镜像到本仓 Release；锁定版本 |
| `antigravity` | Intel | Google Antigravity 智能体 IDE，**分发的是打补丁后的成品**：解包官方 Intel dmg → 静态改写 `app.asar`（中文汉化 + 补充词典 + 页内 Gemini 伴生挂件 + 禁用自动更新）→ ad-hoc 重签，安装后自动清掉 quarantine；由 `Widgets/antigravity-niang/build.sh` 复现构建；与 core 未打补丁同名 cask 不能共存 |
| `blender-5x` | Intel | Blender 5.x Intel 优化社区构建；镜像到本仓 Release；会与 core 的 `blender` 共用 `/Applications/Blender.app` |
| `brewui` | universal | Homebrew 官方图形界面（`Homebrew-<ver>.zip`）；从 GitHub Release 镜像 |
| `checkra1n` | Intel | checkm8 越狱工具（core 同名 cask 因 Gatekeeper 已被 disable）；镜像；锁定版本 |
| `doubao-ime` | universal | 豆包 AI 输入法；装进用户级 `~/Library/Input Methods`（免 sudo）并自动写入系统输入源启用；镜像 |
| `dsh-gui` | Intel | DeepSeek Harness 桌面端；版本/sha 来自上游 nightly feed；镜像 |
| `github-copilot-app` | Intel | GitHub Copilot 桌面 app；镜像官方 Intel dmg；版本跟 core cask |
| `grok-bot` | Intel | Cursor Grok Bot 桌面 agent；镜像；版本跟随 Cursor 下载页 |
| `heliport` | universal | Intel 无线网卡客户端（`itlwmx`）；镜像；锁定版本 |
| `konsole` | dual | KDE 终端；ARM/Intel 独立判版，各自镜像到本仓 Release |
| `lceda` | Intel | 嘉立创 EDA 标准版；镜像；版本跟随官网下载页 Intel(x64) 行 |
| `lceda-pro` | Intel | 嘉立创 EDA 专业版（zip 内套 dmg 自动解包）；镜像；版本跟随官网下载页 Intel(x64) 行 |
| `lody` | Intel | Lody 桌面 app（跨桌面/移动端同步 coding agent 会话）；镜像官方 Intel dmg；版本跟 core cask |
| `macos-tskmgr` | dual | 任务管理器，按 `arch` 分包；镜像；锁定版本 |
| `mirage-wallpaper` | Intel | Mirage 原生动态壁纸管理器（公证签名）；镜像；由自定义检查器跟踪 |
| `palera1n` | universal | checkm8 越狱工具（universal dmg）；镜像；锁定版本 |
| `qoder` | Intel | 阿里巴巴 Qoder CN（国内版）AI 编程平台；镜像；与 core 国际版 `qoder` 同名互斥 |
| `qwen-ime` | universal | 千问输入法；装进用户级 `~/Library/Input Methods`（免 sudo）并自动写入系统输入源启用；镜像 |
| `toshllm` | Intel | ToshLLM 本地 LLM 运行器（Intel Mac + AMD GPU Metal 加速，公证签名，自带更新器）；镜像 |
| `winstart` | universal | Metro 风应用启动器；镜像到本仓 Release；锁定版本 |
| `wireshark` | Intel | 网络协议分析器（官方 Intel dmg；Intel 构建停在 4.4 系）；附 `tshark`/`editcap` 命令垫片；镜像 |
| `workbuddy` | Intel | 腾讯 WorkBuddy AI 办公工作台（Electron 桌面 app）；镜像；版本由更新接口获取 |
| `zcode` | dual | 智谱 z.ai AI 辅助开发环境（`arch` 双架构）；镜像；版本跟 core cask |

## 注意事项（同名冲突）

Homebrew 禁止同时安装来自不同 tap 的同名公式或同 token cask——它们共用同一份
`Cellar/<name>` 或 `Caskroom/<token>` 目录。

除改名且 `keg_only` 的 `fork-*`（11 个）与本仓独有包（`curl3`、`ffplay`、`ffprobe`、
`ffserver`、`antigravity-cli`、`aarch64-unknown-linux-gnu`、`x86_64-unknown-linux-gnu`、
`llvm-mingw`、`cmd`、`deepseek-harness`、`frida-server`、`mufetch`、`sst`、`torpedo`
以及本仓独有 cask）外，**凡与 `homebrew/core` 同名的软件都必须先卸载另一方**
（`brew uninstall <name>` / `brew uninstall --cask <token>`）：

```bash
# 从 homebrew/core 切换到 bemly/tahoe：
brew uninstall gh
brew install bemly/tahoe/gh

# 切回 homebrew/core：
brew uninstall bemly/tahoe/gh
brew install gh
```

`python@3.15` / `meson` 是配套版本，必须先卸载再安装：

```bash
brew uninstall meson
brew uninstall --ignore-dependencies python@3.15
brew install bemly/tahoe/meson
```

`antigravity` 是特例：core 也有同名 cask，装的是未打补丁的官方包，本 tap 这份是
汉化 + 挂件 + 禁自更新的成品；二者共用 `Caskroom/antigravity`，同样只能二选一：

```bash
brew uninstall --cask --force antigravity
brew install --cask bemly/tahoe/antigravity
```

`blender-5x` 虽不同 token，但同样会装进 `/Applications/Blender.app` 与 core 的
`blender` 冲突。`fork-*` 是改名且 `keg_only` 的包，与 core 不冲突，不需要卸载。

## GHCR 瓶

安装包从 **GHCR** 分发：`ghcr.io/v2/bemly/tahoe`
（Homebrew 会剥掉仓库名的 `homebrew-` 前缀，与核心的 `ghcr.io/v2/homebrew/core` 同构）。

瓶的内容优先直接来自上游预构建包；只有源码包（如 `qemu`、`python@3.15`、`meson`）
才在同一个 `macos-26-intel` runner 上代编译一次——用户端始终装瓶，不在本地编译。

**GHCR 瓶只含公式本体，不含依赖。** 所有运行时依赖也均已在本仓出瓶并写全名
`bemly/tahoe/<name>` 引用。`bottle.yml` 会在开编前递归展开每批公式的运行时依赖闭包并校验
瓶覆盖情况（`allow_unbottled_core: true` 仅作维护者临时放行开关）。

| 场景 | 处理 |
| --- | --- |
| 软件有新版本 | `watch-updates` 把公式改动上传为 artifact；`bottle.yml` 在 `main` 工作区应用，每个公式制瓶成功后才发布该版本 |
| GHCR 尚未出瓶 | `main` 保持带旧瓶的版本；watcher 更新不会逼用户源码编译 |
| 上游资源取不到或需人工同步 | `watch-updates.yml` 自动开 `automated-alert` issue 告警 |

## 维护者说明

### 触发 CI 制瓶

公式新增或升级后，把瓶推到 GHCR：

1. 进入 GitHub 仓库的 **Actions → Build bottle and publish to GHCR**。
2. 点击 **Run workflow**。
3. 填入公式名（单个 / 逗号分隔多个如 `gh,fastfetch` / `all` 表示全部）并运行。

workflow 会：信任 tap → 递归校验运行时依赖 → 拓扑排序按序 `--build-bottle` 安装
→ `brew bottle` → 清理旧包并用 `brew pr-upload` 推 GHCR → 立即把该公式的版本与
`bottle do` 块单独提交到 `main`，再处理下一个公式。

> 提示：新建的 GHCR 包默认私有，匿名 `brew install` 会返回 401。若匿名拉取体检发出告警，
> 请到 `https://github.com/bemly?tab=packages` 对应包 → **Package settings** → **Danger Zone**
> 改为 Public。

### Workflows

共四个 workflow：`watch-updates` **每天 UTC 04:00（北京时间 12:00）自动运行**，同时支持 `workflow_dispatch` 手动触发；其余三个**只支持 `workflow_dispatch` 手动触发**。均不使用 `push` / `pull_request` 触发。

| Workflow | 作用 | Runner |
| --- | --- | --- |
| `watch-updates` | 批量扫描全部 `Formula/*.rb` 与 `Casks/*.rb`（`updater/*.swift` 覆盖 `customRelease`、`raw`、`github`、`brew` 4 类上游流）；cask 自动镜像本仓 Release，公式改写并摘瓶后提交 `main` 并触发一次制瓶 | `ubuntu-latest` |
| `bottle` | 递归校验运行时依赖瓶覆盖 → 拓扑排序按序制瓶 → 推 GHCR → 匿名可拉体检 → 把 `bottle do` 块写回公式并提交 | `macos-26-intel` |
| `patched` | 构建补丁成品 cask（`antigravity`：`build.sh --upload`）→ 回填 sidecar sha256 → CI 跑 `brew style` / `audit --strict` 后提交 | `macos-26-intel` |
| `sysroots` | 构建交叉编译所需的预编译 sysroot（`openssl-macos-arm64`、`linux-sysroot-x64/a64`）并发布到 GitHub Release | `macos-26` / `ubuntu-22.04` |

开发者约定见 [AGENTS.md](AGENTS.md)。

[![](https://img.shields.io/badge/powered_by-dsh-4D6BFE?style=flat-square&logo=deepseek&logoColor=white)](https://github.com/deepseek-ai/deepseek-harness)
