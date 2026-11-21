# bemly/tahoe

一个 Homebrew 第三方 tap，专为 **Intel（x86_64）Mac 上的 macOS 26（Tahoe）** 提供可直接安装的软件。

## 为什么

Homebrew 官方从 macOS 26 起不再为 Intel 构建 bottle。实测 core tap 中 `x86_64_tahoe` 瓶的数量为 0，
`gh`、`node` 等软件在 Intel Mac 上只能从源码编译。

本 tap 优先取上游官方的 **macOS amd64 预构建包**制瓶（不重新编译）；对于上游仅发源码的软件及无 Intel 瓶的运行时依赖层（`fork-*` / 同名接管），由 **CI 在 `macos-26-intel` 上一次性代编译成瓶**并分发到 **GHCR**（`ghcr.io/v2/bemly/tahoe`），用户端始终装瓶、不在本地编译；桌面应用与输入法走 **cask** 并镜像到本仓 GitHub Release。

## 要求

- 处理器：**Intel（x86_64）**，Apple Silicon 请勿使用（直接用 `homebrew/core` 即可）
- 系统：**macOS 26（Tahoe）** 或更高

公式内已用 `depends_on arch: :x86_64` 与 `depends_on macos: :tahoe` 强制校验，条件不满足会直接拒绝安装。

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

| 软件 | 说明 |
| --- | --- |
| `gh` | GitHub 官方 CLI，直接取 `gh_<ver>_macOS_amd64.zip` |
| `fastfetch` | 类 neofetch 的系统信息工具，直接取 `fastfetch-macos-amd64.tar.gz`（release tag 无 `v` 前缀） |
| `workbuddy` | 腾讯 WorkBuddy AI 办公工作台（Electron 桌面 app），cask，装进 `/Applications`；不在 brew core，版本由其自动更新接口动态获取 |
| `doubao-ime` | 豆包 AI 输入法，cask，装进用户级 `~/Library/Input Methods`（免 sudo）并自动写入系统输入源启用；不在 brew core，版本由其下载接口动态获取 |
| `node` | Node.js 运行时，直接取官方 `node-v<ver>-darwin-x64.tar.gz` |
| `node@24` | Node.js 24 LTS，直接取官方 `node-v<ver>-darwin-x64.tar.gz` |
| `node@22` | Node.js 22 LTS，直接取官方 `node-v<ver>-darwin-x64.tar.gz` |
| `opencode` | AI 编程 agent，取 `anomalyco/homebrew-tap` GoReleaser 公式的 mac 双架构段（`opencode-darwin-x64/arm64.zip`；Intel 走瓶、ARM 走直链）；与 core 的 npm 版同名，装前须先卸载另一方 |
| `sst` | SST 开发框架，取 `anomalyco/homebrew-tap` GoReleaser 公式的 Intel 段（`sst-mac-x86_64.tar.gz`） |
| `torpedo` | sst/torpedo VPC 数据库访问工具，取 `anomalyco/homebrew-tap` GoReleaser 公式的 Intel 段（`torpedo-mac-x86_64.tar.gz`） |
| `ripgrep` | grep 类搜索工具，`opencode` 的依赖（随本 tap 出瓶） |
| `mufetch` | 系统信息工具，取 release 的 `mufetch_darwin_x86_64.tar.gz` |
| `cmd` | 终端 AI 编程 agent，npm 包 `command-code`（只暴露 `cmd` 命令）；依赖本 tap 的 node 瓶；不检查更新 |
| `zcode` | 智谱 z.ai 的 AI 辅助开发环境，cask 取上游 CDN（x64/arm64 双架构）；版本跟随 core 的 cask |
| `deepseek-harness` | DeepSeek agent harness，npm 包 `@deepseek-ai/dsh`（只暴露 `dsh` 命令，`dsh web` 起浏览器 UI）；依赖本 tap 的 node 瓶；版本跟随 npm `latest` 标签 |
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
| `go` | Go 工具链，官方 `go<ver>.darwin-amd64.tar.gz`（自包含零依赖）；版本跟随 core 的 go |
| `heliport` | Intel 无线网卡客户端，cask 取其 GitHub release；锁定版本不检查更新 |
| `konsole` | KDE 终端，双架构包镜像到本仓 Release；版本即 CI 构建号，每月手动检查一次 |
| `qemu` | 通用模拟器/虚拟机，Intel 现编译出瓶（core 无 Intel 瓶） |
| `capstone` | 反汇编框架，`qemu` 的出瓶依赖 |
| `dtc` | 设备树编译器，`qemu` 的出瓶依赖 |
| `libslirp` | 用户态网络库，`qemu` 的出瓶依赖 |
| `vde` | 虚拟分布式以太网，`qemu` 的出瓶依赖 |
| `neofetch` | 系统信息脚本（上游已归档，最后一版）；不检查更新 |
| `curl3` | 独立 HTTP/3 客户端（含 MASQUE/CONNECT-UDP 的 `--enable-proxy-http3`，core 没开）；改名与 core 的 curl 共存，提供 `curl3` 命令（系统 curl 不动），纯客户端静态构建、不带开发件 |
| `libnghttp3` | HTTP/3 C 库，`curl3` 的出瓶依赖 |
| `libngtcp2` | QUIC 协议实现，`curl3` 的出瓶依赖 |
| `nghttp2` | H2 客户端（`nghttp`/`h2load`/`nghttpx`，`--enable-app`）；H3 开关 Phase 4 再补 |
| `socat` | SOcket CAT 中继工具，源码现编出瓶 |
| `make` | GNU make（装成 `gmake`）；core 虽有 tahoe 瓶仍镜像 |
| `graphviz` | 图形可视化软件，源码现编出瓶 |
| `protobuf` | Protocol Buffers 编译器（`protoc` + 头文件），官方 macOS x86_64 预编译包（`protoc-<ver>-osx-x86_64.zip`）；与 core 同名 |
| `caddy` | 可扩展服务平台，上游 Intel 静态构建（`caddy_<ver>_mac_amd64.tar.gz`）；H2/H3 基线服务 |
| `h2spec` | H2 一致性测试器，Phase 2 用 |
| `hyperfine` | 命令行基准工具，Phase 4 重复基准用 |
| `iperf3` | 静态构建（无 `openssl@4` 依赖），Phase 4 裸网络吞吐基线用 |
| `ninja` | 小而快的构建系统，上游 universal 包（Intel 切片） |
| `rustup` | 官方静态 Rust 工具链安装器，与 core 同名（先卸 core 版）；提供 `rustup` 及 cargo/rustc 代理垫片，工具链走 `rustup toolchain install stable` |
| `wireshark` | 网络协议分析器，cask 取官方 Intel dmg（Intel 构建停在 4.4 系）；附 `tshark`/`editcap` 命令垫片 |
| `git-lfs` | Git 大文件扩展，上游 Intel 构建（带全套 man 页）；装完手动跑一次 `git lfs install` |
| `github-copilot-app` | GitHub Copilot 桌面 app，cask 镜像官方 Intel dmg（`GitHub-Copilot-darwin-x64.dmg`）；版本跟 core cask，装进 `/Applications` |
| `frida-server` | Frida 动态插桩服务端，frida/frida 官方裸二进制（仅 Intel）；需 sudo 运行，默认监听 `127.0.0.1:27042` |
| `afm` | AFM拼音输入法，仅 Apple Silicon（本 tap 首个破 Intel 门槛的例外）；用户级安装并自动启用输入源；锁定版本不检查更新 |
| `amd` | AMD 歌词汉化下载器（universal 双架构，本地构建后镜像）；附带 `obcli` 命令行；锁定版本不检查更新 |
| `blender-5x` | Blender 5.x Intel 优化社区构建（仅 x86_64）；镜像到本仓 Release，版本跟随上游 releases |
| `dsh-gui` | DeepSeek Harness 桌面端（仅 Intel）；版本/sha 来自上游 nightly feed，版本化 dmg 镜像到本仓 Release，按版本判新与其他包一致 |
| `cmake` | 跨平台构建工具，上游 universal macOS 包（Intel 切片）；core 无 Intel 瓶，秒装代替源码编译 |
| `grok-bot` | Cursor Grok Bot 桌面 agent（仅 Intel）；镜像到本仓 Release，版本跟随 Cursor 下载页 |
| `scrcpy` | 安卓投屏工具，上游 Intel 静态构建（零依赖）；core 无 Intel 瓶且依赖树全源码编 |
| `yt-dlp` | 音视频下载器，上游 universal macOS 单二进制（零依赖）；core 无 Intel 瓶且拖 Python 栈 |
| `libplist` / `libimobiledevice-glue` / `libtatsu` / `libusbmuxd` / `libimobiledevice` | iOS 设备通信栈，Intel 现编出瓶（core 无 Intel 瓶）；运行时依赖全部走本 tap 的 `fork-libtasn1` 与 `fork-openssl@4` 瓶 |
| `wabt` | WebAssembly Binary Toolkit（`wat2wasm`/`wasm2wat` 等全套工具）——上游 macOS 资产仅 arm64、core 无 Intel Tahoe 瓶，core 拷入代编译；cmake 构建依赖走本 tap |
| `x86_64-unknown-linux-gnu` | 面向 x86_64 Linux 的 GCC 交叉工具链（Intel host 预编译，thin x86_64）；运行时依赖全部走本 tap 的 `fork-bdw-gc` / `fork-python@3.14` / `fork-zstd` / `guile` 瓶；版本跟随 GitHub release，sha 走 `.sha256` sidecar |
| `mirage-wallpaper` | Mirage 原生动态壁纸管理器，兼容 Wallpaper Engine（仅 Intel cask，thin x86_64，公证签名）；上游按架构分包，镜像到本仓 Release，版本由自定义检查器跟踪 |
| `llvm` | 新一代编译器基础设施——上游 19.1.7 Intel 预编译 pinned（之后只有 ARM64 包；23.x 源码编超 6 小时上限）；thin x86_64，零依赖，keg-only；bindgen 用 `LIBCLANG_PATH` 指过去即用 |
| `z3` | 高性能定理证明器，官方 macOS x64 预编译包（`z3-<ver>-x64-osx-13.3.zip`，零依赖）；与 core 同名 |
| `toshllm` | ToshLLM 本地 LLM 运行器（Intel Mac + AMD GPU，Metal 加速；仅 Intel cask，thin x86_64，公证签名，app 自带更新器）；上游 dmg 镜像到本仓 Release，版本跟随上游 releases |
| `lceda-pro` | 嘉立创EDA专业版（仅 Intel x64，thin x86_64，公证签名）；cask 镜像到本仓 Release（zip 内套 dmg 自动解包），版本跟随官网下载页 Intel(x64) 行 |
| `lceda` | 嘉立创EDA标准版（仅 Intel x64，thin x86_64，公证签名）；cask 镜像到本仓 Release，版本跟随官网下载页 Intel(x64) 行 |
| `chisel` | 基于 HTTP(S) 的快速 TCP/UDP 隧道工具，官方 Intel 裸二进制（`chisel_<ver>_darwin_amd64.gz`，零依赖）；版本跟随 GitHub release；与 core 同名异物（core 版是 Facebook 的 LLDB 命令集），二者先卸一方再装 |
| `exiftool` | 读写/编辑图片元数据的 Perl 工具（纯脚本，零编译）；官方 `Image-ExifTool-<ver>.tar.gz` 直装出瓶，版本跟随 homebrew/core；精简掉 core 版那套 brotli/xz + CPAN XS 可选模块（Intel Tahoe 无瓶）；与 core 同名同物，二者先卸一方再装 |
| `python@3.15` | Python 3.15 解释器，Intel 现编出瓶（core 无 Intel Tahoe 瓶）；与 core 同名同物，先卸 core 版；本 tap 的 meson 依赖它，避免每次 meson 更新都源码编 Python |
| `meson` | 快速构建系统，与 core 同名同物，先卸 core 版；依赖本 tap 的 `ninja` + `python@3.15`，出 Intel Tahoe 瓶，不再拖 core 的源码 Python |
| `lody` | Lody 桌面 app（跨桌面/移动端同步 coding agent 会话）；cask 镜像官方 Intel dmg（`Lody-<ver>-x64.dmg`），版本跟随 core cask |
| `qoder` | 阿里巴巴 Qoder CN（国内版）AI 编程平台；cask 镜像官网 Intel dmg（`Qoder-CN-mac-x64.dmg`），版本跟随 qoder.cn 更新日志；与 core 的国际版 `qoder` 同名，二者先卸一方再装 |
| `fork-*`（39 个） | 依赖层：core 里没有 Intel Tahoe 瓶的运行时依赖，按「能同名就同名接管、有 core 依赖方就改名 fork」处理。`fork-glib`/`fork-gnutls`/`fork-openssl@3`/`fork-openssl@4`/`fork-python@3.14`/`fork-xz`/`fork-zstd`/`fork-dynet`/`fork-eigen@3` 等 39 个，全部 `keg_only`、源码现编，依赖方按全名 `bemly/tahoe/fork-*` 引用（清单见 AGENTS.md 6.3） |
| `openjdk` / `openjdk@26` | OpenJDK 26 GA 官方 macOS x64 预编译包（`keg_only`）；与 core 同名，先卸 core 版 |
| `openjdk@17` / `openjdk@21` | Eclipse Temurin x64 JDK（Adoptium API 判新，`keg_only`）；与 core 同名 |
| `git` | Git 本体，core 拷入源码现编（依赖 fork-pcre2/gettext/openssl@4）；与 core 同名 |
| `bash` | GNU Bash 5.3，core 拷入源码现编（fork-ncurses/readline）；与 core 同名 |
| `wget` / `aria2` | 下载工具，core 拷入源码现编（fork-libidn2/libpsl/openssl@4 等）；与 core 同名 |
| `automake` / `abseil` / `svt-av1` / `python@3.11` | core 拷入源码现编的构建/运行依赖（automake、abseil、SVT-AV1、Python 3.11）；与 core 同名 |
| `guile` / `jemalloc` / `libev` / `libnghttp2` / `libssh` / `libyaml` / `simdjson` / `snappy` | 可同名接管的依赖层（直接沿用 core 名字，先卸 core 版），源码现编出瓶；`libnghttp2` 同时是 curl3/nghttp2 的依赖 |
| `fzf` | 命令行模糊查找，上游 `fzf-<ver>-darwin_amd64.tar.gz` 单二进制；版本跟 GitHub release |
| `zig` | Zig 工具链，官方 `zig-x86_64-macos-<ver>.tar.xz`（Intel host）；与 core 同名 |
| `swift` | 官方 Swift 6.4.2 macOS pkg 重打包，只暴露 `swift`/`swiftc`（不污染其它工具链）；版本跟 swift.org |
| `llvm-mingw` | LLVM/Clang 的 mingw-w64 交叉工具链（Intel host → Windows），版本跟 GitHub release |
| `aarch64-unknown-linux-gnu` | 面向 aarch64 Linux 的 GCC 交叉工具链（Intel host 预编译），与 `x86_64-unknown-linux-gnu` 配套 |
| `qwen-ime` | 千问输入法，cask 取上游下载 API 的 Mac dmg，镜像到本仓 Release |
| `antigravity-cli` | Google Antigravity CLI（装成 `agy` 命令），官方 Intel macOS 扁平二进制重打包；版本跟随官方 auto-updater manifest |
| `dotnet` | .NET SDK 11，官方 macOS x64 tarball 重打包（整包进 prefix + `dotnet` 垫片）；版本跟随微软 release-metadata API；与 core 同名 |
| `node@20` | Node.js 20 LTS，直接取官方 `node-v20.x-darwin-x64.tar.gz`；与 core 同名 |
| `postgresql@13` | PostgreSQL 13，EDB 官方 macOS x64 二进制包重打包（只装 bin/include/lib/share，跳过 pgAdmin 等 app）；`keg_only`（自带 openssl/icu 会撞 core），用其中的命令需把 `/usr/local/opt/postgresql@13/bin` 加进 PATH；与 core 同名 |
| `freeling` | 自然语言分析器套件（分词 / 词性标注 / 命名实体等），core 同名接管源码现编；解捆自带的 dynet/eigen，改用本源的 `fork-dynet`/`fork-eigen@3`/`boost@1.85`/`icu4c@78`；与 core 同名 |
| `icu4c@78` | ICU 78 Unicode / 国际化库，core 同名接管源码现编（`keg_only`）；`freeling` 的依赖 |
| `boost@1.85` | Boost C++ 库 1.85，取第三方 prebuilt-boost 的 macOS x86 `static+shared` 包（预编译 dylib 补 `@rpath` 后 ad-hoc 重签）；`freeling` 的依赖；与 core 同名 |
| `wimlib` | 创建 / 解包 / 修改 Windows Imaging（WIM）映像的库与 `wimlib-imagex` 工具集，core 拷入源码现编（autotools，`fork-pkgconf` 构建）；macOS 上零运行时依赖 |
| `antigravity` | Google Antigravity 智能体 IDE，**分发的是打补丁后的成品**：解包官方 Intel dmg → 静态改写 `app.asar`（中文汉化 + 模型名补充词典：哈基米/氖/氩/克劳德/十四行诗等 + 右下角 Gemini 伴生挂件：额度剩余与重置时间、可导入自己的图片换立绘；同时禁用应用内自动更新，避免补丁被官方新包覆盖）→ ad-hoc 重签名 → 镜像到本仓 Release。构建可复现（`Widgets/antigravity-niang/build.sh`），版本跟随 core cask + 本 Release 的 `.sha256` sidecar。安装后 cask 会清掉 brew 打的隔离属性，正常免 Gatekeeper 弹窗（ad-hoc 重签、无公证）；与 core 的未打补丁同名 cask 不能共存，先卸一方再装 |
| `jadx` | Dex 转 Java 反编译器（含 `jadx` 与 `jadx-gui`），直接取官方 `jadx-<ver>.zip` 预编译包；依赖本 tap 的 `openjdk`；与 core 同名 |
| `xcodegen` | 按配置文件生成 Xcode 工程，取官方 universal 预编译包（`xcodegen.zip`，含 `SettingPresets`，零依赖）；与 core 同名 |
| `starship` | 跨 Shell 提示符工具，取官方 x86_64 预编译包（`starship-x86_64-apple-darwin.tar.gz`）并生成补全；与 core 同名 |
| `bun` | JS 运行时 / 打包 / 包管理器，取官方 Intel 预编译包（`bun-darwin-x64.zip`，提供 `bun` 与 `bunx` 软链）；与 core 同名 |
| `docker` | Docker 命令行客户端，取官方 macOS x86_64 静态二进制（`docker-<ver>.tgz`）并生成补全；与 core 同名 |
| `lima` | macOS 上的 Linux 虚拟机工具（`limactl`/`lima` 等），取官方 `lima-<ver>-Darwin-x86_64.tar.gz` 预编译包并生成补全；与 core 同名 |
| `mercurial` | 分布式版本控制系统（`hg` + `chg`），使用本 tap 的 `python@3.11` 源码现编出瓶；与 core 同名 |
| `spirv-tools` | SPIR-V 着色器优化与校验工具集，core 拷入源码现编出瓶（零运行时依赖）；与 core 同名 |
| `vulkan-loader` | Vulkan ICD 加载器，core 拷入源码现编出瓶（仅依赖 core 的 `vulkan-headers` `all` 瓶）；与 core 同名 |
| `gnupg` | GNU Privacy Guard（OpenPGP），core 拷入源码现编出瓶，复用本源 `fork-gnutls`/`fork-libusb`/`fork-readline`/`fork-gettext` 与同名接管的 `libassuan`/`libgcrypt`/`libgpg-error`/`libksba`/`npth`/`pinentry`；与 core 同名 |

## 注意事项（同名冲突）

Homebrew 禁止同时安装来自不同 tap 的同名公式或同 token cask——它们共用同一份
`Cellar/<name>` 或 `Caskroom/<token>` 目录。

除改名且 `keg_only` 的 `fork-*`（39 个）与本仓独有包（`curl3`、`ffplay`、`ffprobe`、
`ffserver`、`antigravity-cli`、`aarch64-unknown-linux-gnu`、`x86_64-unknown-linux-gnu`、
`llvm-mingw`、`cmd`、`deepseek-harness`、`mufetch`、`sst`、`torpedo` 以及本仓独有 cask）外，
**凡与 `homebrew/core` 同名的软件都必须先卸载另一方**（`brew uninstall <name>` /
`brew uninstall --cask <token>`）：

```bash
# 同名包在 Cellar 里已有双份时，可切换链接来源：
brew unlink gh && brew link --overwrite bemly/tahoe/gh
brew unlink fastfetch && brew link --overwrite bemly/tahoe/fastfetch

# 切回 core 版本：
brew unlink bemly/tahoe/gh && brew link gh
brew unlink bemly/tahoe/fastfetch && brew link fastfetch
```

`python@3.15` / `meson` 是配套版本，必须卸载切换：

```bash
brew uninstall meson
brew uninstall --ignore-dependencies python@3.15
brew install bemly/tahoe/meson
```

其余与 core 同名的公式（`node`、`node@20`/`22`/`24`、`go`、`cmake`、`git`、`bash`、`wget`、
`aria2`、`automake`、`abseil`、`svt-av1`、`python@3.11`、`openjdk*`、`guile`、`jemalloc`、
`libev`、`libnghttp2`、`libssh`、`libyaml`、`simdjson`、`snappy`、`zig`、`swift`、`fzf`、
`protobuf`、`z3`、`wimlib`、`ripgrep`、`dotnet`、`freeling`、`boost@1.85`、`icu4c@78`、
`postgresql@13`、`chisel`、`exiftool`、`opencode`、`jadx`、`xcodegen`、`starship`、`bun`、
`docker`、`lima`、`mercurial`、`spirv-tools`、`vulkan-loader`、`gnupg`、`libassuan`、`libgcrypt`、
`libgpg-error`、`libksba`、`npth`、`pinentry` 等）和同名 cask（`zcode`、`lody`、
`qoder`、`github-copilot-app`、`wireshark`、`checkra1n`、`palera1n`、`antigravity`；
`blender-5x` 虽不同 token，但同样会装进 `/Applications/Blender.app` 与 core 的 `blender` 冲突）
装前均须先卸另一方。`fork-*` 是改名包，与 core 不冲突，不需要卸载。

`antigravity` 是特例：core 也有同名 cask，装的是未打补丁的官方包，本 tap 这份是
汉化 + 挂件 + 禁自更新的成品；二者共用 `Caskroom/antigravity`，同样只能二选一
（若曾装过 core 版，安装前先执行 `brew uninstall --cask --force antigravity`）。

## GHCR 瓶

安装包从 **GHCR** 分发：`ghcr.io/v2/bemly/tahoe`
（Homebrew 会剥掉仓库名的 `homebrew-` 前缀，与核心的 `ghcr.io/v2/homebrew/core` 同构）。

瓶的内容优先直接来自上游预构建包；只有源码包（如 `qemu`、`python@3.15`、`meson`）
才在同一个 Intel runner 上代编译一次——用户端始终装瓶，不在本地编译。
瓶标签由构建机的架构与系统决定，为了产出 `x86_64_tahoe`，制瓶跑在 `macos-26-intel` runner 上。

**GHCR 瓶只含公式本体，不含依赖。** 公式若需要依赖，依赖也必须一并放进本仓出瓶，
并在公式里写全名 `bemly/tahoe/<name>`，不能留裸名由 `homebrew/core` 解析——core 在 Intel
Tahoe 不出瓶，裸名依赖会回落到用户端源码编译（graphviz 16.1.1 升级曾因此触发
`libpng`/`librsvg`/`rust` 一整串编译）。`bottle.yml` 现在会在开编前递归展开每批公式的**运行时**依赖闭包（构建依赖只在 CI
现编，不影响用户端）：本仓依赖无瓶块（且不在本批拓扑内）直接红；core 依赖没有
`tahoe`/`x86_64_tahoe`/`all` 瓶的也会列出并红掉。旧枢纽依赖确需兼容时，可在手动触发时
勾 `allow_unbottled_core` 放行，但这会重新引入本地源码编译，只是临时豁免。`graphviz` 已改为
零运行时依赖构建（关闭第三方渲染插件，Quartz 与内置插件仍提供 PDF/PNG/SVG），
不再拖那条 57 项的编译链。

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

四个 workflow，**都只支持 `workflow_dispatch` 手动触发**，不设定时任务：

| Workflow | 作用 | Runner |
| --- | --- | --- |
| `watch-updates` | 批量扫描全部 `Formula/*.rb` 与 `Casks/*.rb`（`updater/*.swift` 覆盖 brew 公式/cask、GitHub Release、源 tap raw、自定义接口 5 类版本流）；cask 自动镜像本仓 Release，公式改写并摘瓶后提交 `main` 并触发一次制瓶 | `ubuntu-latest` |
| `bottle` | 递归校验运行时依赖瓶覆盖 → 拓扑排序按序制瓶 → 推 GHCR → 把 `bottle do` 块写回公式并提交 | `macos-26-intel` |
| `patched` | 构建补丁成品 cask（`antigravity`：`build.sh --upload`）→ 回填 sidecar sha256 → CI 跑 `brew style` / `audit --strict` 后提交 | `macos-26-intel` |
| `sysroots` | 构建交叉编译所需的预编译 sysroot（`openssl-macos-arm64`、`linux-sysroot-x64/a64`）并发布到 GitHub Release | `macos-26` / `ubuntu-22.04` |

开发者约定见 [AGENTS.md](AGENTS.md)。

[![](https://img.shields.io/badge/powered_by-dsh-4D6BFE?style=flat-square&logo=deepseek&logoColor=white)](https://github.com/deepseek-ai/deepseek-harness)
