# AGENTS.md

> 本文件是 `bemly/tahoe` 仓库的开发约定与运行手册。改动本仓库前先读完本文档。
>
> **提交与推送（硬性约定）**：每次改动完成（代码 / 公式 / cask / 文档）后，
> 一律立即 `git add` + `commit` + `git push origin main`，无需用户再次确认。

## 1. 项目定位

`bemly/tahoe` 是一个 Homebrew 第三方 tap，专为 **Intel（x86_64）Mac 上的 macOS 26（Tahoe）** 提供可直接安装的软件。

Homebrew 官方从 macOS 26 起不再构建 `x86_64_tahoe` bottle（core 中为 0）。本 tap 优先取上游官方 **macOS amd64 预构建包**打包分发到 GHCR（`ghcr.io/v2/bemly/tahoe`）；无预编译的源码软件及无 Intel 瓶的依赖层，统一在 CI（`macos-26-intel`）一次性代编译成瓶，用户端始终装瓶、不在本地编译。

### 收录范围（硬性约束）

只收录**同时满足**以下两点的软件：

1. 提供 **x86_64（amd64）macOS** 预编译产物，或可在 `macos-26-intel` 一次性代编译出瓶；
2. 能在 **macOS 26（Tahoe）** 上正常安装运行。

不收录：仅 arm64 的软件、必须在用户本地编译的软件、只支持 Linux 或 macOS 25 及以下的软件。

**例外约定**：

- **arm64-only 自有软件（`afm`）**：`Casks/afm.rb` 使用 `depends_on arch: :arm64`（Intel 直接拒绝安装），`macos: :tahoe` 门槛不变；仅对自有软件开口，不收外部 arm64-only 包。
- **分发修改版专有二进制（`antigravity`）**：在官方 darwin-x64 dmg 上静态改写 `app.asar`（中文汉化 + 补充词典 + 页内 Gemini 娘挂件 + 禁用自更新）后 ad-hoc 重签并重打 dmg 发布。约束：构建必须由 `Widgets/antigravity-niang/build.sh` 一条命令复现、官方输入 sha256 与 core cask API 核对一致、每步设硬质量门、`RELEASE-NOTES.template` 如实披露上游许可状态。

## 2. 命名约定

| 项 | 值 | 说明 |
| --- | --- | --- |
| tap 名 | `bemly/tahoe` | 用户使用时的名字，**不得改写** |
| 仓库名 | `bemly/homebrew-tahoe` | GitHub 仓库名必须带 `homebrew-` 前缀，`brew tap bemly/tahoe` 才能简写解析 |
| 公式 / Cask 目录 | `Formula/` / `Casks/` | 标准 Homebrew 布局 |
| 依赖引用全名 | `bemly/tahoe/<name>` | 指向本 tap 的依赖必须写全名（裸名永远解析到 core） |
| 依赖改名 | `fork-<core>` | core 有依赖方、不能同名接管时改名并设 `keg_only`；无 core 依赖方则直接同名接管（见 6.3） |

## 3. 目录结构

```
homebrew-tahoe/
├── AGENTS.md                          # 本文件：开发约定与索引
├── README.md / README.zh.md           # 面向用户的使用说明（英文 / 中文）
├── Formula/                           # 141 个公式（含 14 个 fork-*）
├── Casks/                             # 25 个 cask（桌面 app / 输入法）
├── Patches/                           # glib / libssh2 / libtool / python 补丁
├── Widgets/antigravity-niang/         # antigravity 补丁成品构建（挂件源码 + asar 工具 + build.sh）
├── audit_exceptions/                  # 装后 audit 豁免（mismatched_binary_allowlist.json）
├── updater/
│   ├── UpdaterCore.swift              # 检查器共享核心（版本来源 / 比对 / 改写 / 输出协议）
│   └── <name>.swift                   # 155 个检查器入口，与 Formula|Casks 一一同名
└── .github/workflows/
    ├── watch-updates.yml              # 手动触发的批量版本 watcher（ubuntu-latest + Swift）
    ├── bottle.yml                     # 手动触发的制瓶 + 推 GHCR（macos-26-intel）
    ├── patched.yml                    # 手动触发的补丁成品构建 + cask lint（macos-26-intel）
    └── sysroots.yml                   # 手动触发的交叉编译 sysroot 构建（发 Release）
```

## 4. 公式与 Cask 编写规范

标准公式骨架：

```ruby
class Xxx < Formula
  desc     "..."                       # 一句话，≤80 字符
  homepage "..."
  # 不要写与 URL 扫描结果相同的 version 行（audit 判冗余）；仅 URL 扫错或扫不出时显式声明
  url      "https://.../xxx_X.Y.Z_macOS_amd64.zip"
  sha256   "..."
  license  "..."                       # 闭源软件省略 license 行

  depends_on arch: :x86_64             # 强制 Intel
  depends_on macos: :tahoe             # 强制 macOS 26+

  def install; end                     # 安装，结尾做架构与版本自检
  def caveats; end                     # 可选：使用提示
  test do ... end                      # brew test 用例
end
```

要点：

- **`depends_on arch: :x86_64` + `depends_on macos: :tahoe` 是公式硬门槛**（`opencode` / `ripgrep` 为双架构例外，保留 `macos: :tahoe`）。
- **勿写 `def pre_install` 与 `def post_install`**：Homebrew `Formula` 并无 `pre_install` 生命周期钩子（写了也不会被调用），且 Homebrew 6+ 已废弃命令式 `post_install`（style 拒绝）。二进制架构与版本校验一律放在 `def install` 尾部，或用声明式 `post_install_steps`（全仓所有公式已迁移清零）。
- **`bottle do` 块不要手填**：由 `bottle.yml` 制瓶后自动写回，标签为纯系统名 `tahoe`。
- **桌面 app / 输入法走 `Casks/`**：cask 无 bottle 机制，全部将安装包镜像到本仓 GitHub Release（`uploadRelease: true`）。全仓 cask 统一使用声明式 `preflight_steps` / `postflight_steps`（禁止命令式 `preflight do` / `postflight do`）。

## 5. Workflow 约定

**所有 workflow 一律只允许 `workflow_dispatch` 手动触发**，严禁 `schedule`、`push`、`pull_request` 自动触发。

| 约定 | 实现 |
| --- | --- |
| 检查与制瓶分离 | 版本检查用 `ubuntu-latest`（Swift 检查器用 `swiftc -O` 编译运行，禁用解释器模式）；制瓶必须跑在 `macos-26-intel` 才产出 `x86_64_tahoe` 标签 |
| 一次 runner 出多瓶 | `watch-updates.yml` 仅扫全仓，仅触发**一次** `bottle.yml`（逗号列表传入公式，绝不逐个触发、绝不传 cask 名）；遇到依赖外部补丁构建的成品 cask（`antigravity`）且上下游都已就绪时自动触发一次 `patched.yml` |
| 递归依赖门控 | `bottle.yml` 在 `brew readall` 后递归展开每批公式的**运行时**依赖闭包：本仓依赖必须已有 `tahoe` 瓶（同批由拓扑排序出瓶者豁免），core 依赖经 formulae.brew.sh API 查无 `tahoe`/`x86_64_tahoe`/`all` 瓶即阻断（`allow_unbottled_core: true` 仅作临时放行开关） |
| 重型任务走 CI | `patched.yml` 在 `macos-26-intel` 执行 `antigravity` 构建上传、写回 sidecar sha 并跑 `brew style`/`audit --strict`；开发机只跑轻量验证，避免卡死 |
| 交叉 sysroot 构建 | `sysroots.yml` 在 `macos-26` / `ubuntu-22.04` 构建 `openssl-macos-arm64` 与 `linux-sysroot-x64/a64` 并发布到 GitHub Release（目标端头库不进 `Formula/` 或 GHCR），默认 `openssl_version` 与 `fork-openssl@4` 对齐 |
| 控制 GitHub 负载 | `fetch-depth: 1`；brew 流走 `formulae.brew.sh`、github 流走 `HEAD releases/latest` 跳转（不耗 API 限额）；优先读 `checksums.txt`；配 `concurrency` 防并发互踩 |

## 6. 当前收录

> **141 个公式（含 14 个 `fork-*`）+ 25 个 cask**，`updater/` 共 155 个检查器（另有 `UpdaterCore.swift`）。

### 6.1 预编译直引（上游 macOS Intel 包）

| 软件 | 版本 | 来源 | 备注 |
| --- | --- | --- | --- |
| `aarch64-unknown-linux-gnu` | 15.2.0 | messense 交叉工具链 GitHub Releases | 只收 Intel host 段；交叉到 aarch64 Linux；github 流 + `.sha256` sidecar；运行时依赖走本源 `guile`/`python@3.14`/`fork-*` |
| `antigravity-cli` | 1.5.14 | Google GCS `antigravity-public` 的 `cli_mac_x64.tar.gz`（按构建号分目录） | 扁平裸二进制装成 `agy`；customRelease 跟官方 auto-updater manifest（只给 sha512，核心回退下载实算）；core 无同名公式 |
| `boost@1.85` | 1.85.0 | MarkusJx/prebuilt-boost GitHub `boost-<ver>-macos-13-clang-static+shared-x86.tar.gz` | 第三方预编译 static+shared；dylib 补 `@rpath` + ad-hoc 重签；与 core 同名；freeling 依赖 |
| `bun` | 1.4.5 | GitHub `bun-darwin-x64.zip` | 单二进制 + `bunx` 软链；显式 version 行；github 流（tag `bun-v`）+ `SHASUMS256.txt`；与 core 同名 |
| `caddy` | 2.11.9 | 官方 `caddy_<ver>_mac_amd64.tar.gz` | 扁平包；H2/H3 基线；brew 模板流 |
| `chisel` | 1.12.0 | GitHub `chisel_<ver>_darwin_amd64.gz` | gzip 裸二进制；github 流；与 core 同名异物 |
| `cmake` | 4.5.1 | Kitware GitHub `cmake-<ver>-macos-universal.tar.gz` | universal；core 无 Intel 瓶；brew 模板流 |
| `cmd` | 1.45.0 | npm `command-code` tarball | 纯 JS 装进 libexec；依赖本 tap node；不检查更新 |
| `deepseek-harness` | 0.2.2-rc.5 | npm `@deepseek-ai/dsh` tarball | 纯 JS；`dsh web`；依赖本 tap node；跟 npm latest |
| `docker` | 29.10.0 | Docker 官方 `mac/static/stable/x86_64/docker-<ver>.tgz` | Docker 静态 CLI + 自动生成补全；brew 模板流；与 core 同名 |
| `docker-buildx` | 0.39.1 | GitHub 裸二进制 `buildx-v<ver>.darwin-amd64` | brew 模板流 |
| `docker-compose` | 5.8.0 | GitHub 裸二进制 `docker-compose-darwin-x86_64` | 文件名无版本；brew 模板流 |
| `dotnet` | 11.0.100 | 官方 builds.dotnet.microsoft.com `dotnet-sdk-<ver>-osx-x64.tar.gz` | .NET SDK；整包进 prefix + `write_exec_script`；显式 version 行；customRelease 跟 release-metadata API；与 core 同名 |
| `exiftool` | 13.55 | SourceForge `Image-ExifTool-<ver>.tar.gz` | 纯 Perl 直装；与 core 同名同物 |
| `fastfetch` | 2.71.0 | GitHub `fastfetch-macos-amd64.tar.gz` | release tag 无 `v`；brew 模板流 |
| `ffmpeg` | 9.0.2 | evermeet 静态 `ffmpeg-<ver>.zip` | 单二进制；版本跟 core ffmpeg |
| `ffplay` | 9.0.2 | evermeet 静态 `ffplay-<ver>.zip` | 同上；core 无同名公式 |
| `ffprobe` | 9.0.2 | evermeet 静态 `ffprobe-<ver>.zip` | 同上；core 无同名公式 |
| `ffserver` | 3.4.2 | evermeet 静态 `ffserver-3.4.2.zip` | 上游 4.0 已移除；不检查更新 |
| `fish` | 4.9.3 | 官方 `fish-<ver>.app.zip` 内 unix 树 | universal Intel 切片；只装 `base/` |
| `frida-server` | 17.27.4 | GitHub `frida-server-<ver>-macos-x86_64.xz` | 裸二进制；github 流；需 sudo |
| `fzf` | 0.75.0 | GitHub `fzf-<ver>-darwin_amd64.tar.gz` | 单二进制；github 流 |
| `gh` | 2.105.0 | GitHub `gh_<ver>_macOS_amd64.zip` | brew 模板流；sha 走 checksums.txt |
| `git-lfs` | 3.8.1 | GitHub `git-lfs-darwin-amd64-v<ver>.zip` | 全套 man；brew 模板流 |
| `go` | 1.27.4 | 官方 `go<ver>.darwin-amd64.tar.gz` | 完整工具链；零依赖；显式 version 行 |
| `h2spec` | 2.6.0 | GitHub `h2spec_darwin_amd64.tar.gz` | 单二进制；brew 模板流 |
| `hyperfine` | 2.0.0 | GitHub `hyperfine-v<ver>-x86_64-apple-darwin.tar.gz` | 带 man/补全；brew 模板流 |
| `iperf3` | 3.22.1 | userdocs `iperf3-amd64-osx-15` | 静态零依赖；customRelease 取最大世代 |
| `jadx` | 1.5.7 | GitHub `jadx-<ver>.zip` | 官方预编译（`jadx` + `jadx-gui`）；依赖本 tap `openjdk`；github 流；与 core 同名 |
| `lima` | 2.3.0 | GitHub `lima-<ver>-Darwin-x86_64.tar.gz` | 官方预编译全套 bin/libexec/share；github 流 + `SHA256SUMS`；与 core 同名 |
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
| `starship` | 1.27.0 | GitHub `starship-x86_64-apple-darwin.tar.gz` | 单二进制 + 生成补全；github 流；与 core 同名 |
| `swift` | 6.4.2 | swift.org 官方 `swift-<ver>-RELEASE-osx.pkg` | 重打包只暴露 `swift`/`swiftc`；customRelease |
| `torpedo` | 0.0.13 | anomalyco raw（Intel 段） | 无版本命令，不做版本自检 |
| `x86_64-unknown-linux-gnu` | 15.2.0 | messense 预编译（Intel host） | 203MB；`.sha256` sidecar；运行时依赖走本源 `guile`/`python@3.14`/`fork-*` |
| `xcodegen` | 2.48.0 | GitHub `xcodegen.zip` | 官方 universal 预编译（二进制 + `SettingPresets`）；github 流；与 core 同名 |
| `yt-dlp` | 2026.10.26 | GitHub `yt-dlp_macos` 单二进制 | universal；零依赖；brew 模板流 |
| `z3` | 5.3.3 | 官方 `z3-<ver>-x64-osx-13.3.zip` | 预编译；显式 version（URL 会扫成 13.3） |
| `zig` | 0.17.1 | 官方 `zig-x86_64-macos-<ver>.tar.xz` | 预编译；与 core 同名 |

### 6.2 源码 / 代编译（core 拷入或上游源码）

| 软件 | 版本 | 来源 | 备注 |
| --- | --- | --- | --- |
| `abseil` | 20260817.0 | core 拷入（源码） | cmake；与 core 同名 |
| `aria2` | 1.37.0 | core 拷入（源码） | autotools；`c-ares`/`libssh2`/`sqlite`/fork-openssl@4 |
| `automake` | 1.20 | core 拷入（源码） | 纯 autotools；无运行时依赖 |
| `bash` | 5.3.20 | core 拷入（源码） | `ncurses`/fork-readline/fork-gettext；与 core 同名 |
| `brotli` | 1.2.1 | core 同名接管（源码） | cmake；curl3 依赖 |
| `c-ares` | 1.34.9 | core 同名接管（源码） | cmake；aria2/nghttp2 依赖 |
| `capstone` | 5.0.9 | core 拷入（源码） | cmake；fork-gettext；qemu 依赖 |
| `curl3` | 8.23.0 | core 拷入（源码） | 改名 + `--enable-proxy-http3`；纯客户端；`brotli`/`libpsl`/`libssh2`/`libidn2` + fork-* 依赖 |
| `dtc` | 1.8.1 | core 拷入（源码） | meson；依赖 `libyaml`；qemu 依赖 |
| `dynet` | 2.1.2 | core 同名接管（源码） | cmake；`eigen@3` 依赖；freeling 依赖；`revision` 与 core 同步；上游 2020 停更 |
| `eigen@3` | 3.4.1 | core 同名接管（源码） | cmake；`keg_only :versioned_formula`；`dynet` 依赖 |
| `freeling` | 4.2.1 | core 同名接管（源码） | cmake；解捆自带 dynet/eigen；依赖本 tap `boost@1.85`/`icu4c@78`/`dynet`；`revision` 与 core 同步 |
| `git` | 2.56.1 | core 拷入（源码） | make；`fork-pcre2`/`fork-gettext`（macOS 用 CommonCrypto，`fork-openssl@4` 仅在 `on_linux`）；与 core 同名 |
| `glib` | 2.90.1 | core 同名接管（源码） | meson；libslirp/qemu 依赖；`fork-pcre2`/`fork-gettext` |
| `gnupg` | 2.5.24 | core 同名接管（源码） | autotools；依赖本 tap `gnutls`/`libusb`/`fork-readline`/`fork-gettext` + 同名 GnuPG C 库全家桶；`revision` 与 core 同步 |
| `gnutls` | 3.8.14 | core 同名接管（源码） | autotools；`libidn2`/`nettle`/`p11-kit`/`fork-gmp`/`fork-libtasn1`/`fork-libunistring`/`fork-gettext` |
| `graphviz` | 16.1.2 | core 拷入（源码） | 零第三方渲染插件；autotools |
| `guile` | 3.0.11 | core 同名接管（源码） | fork-bdw-gc/gmp/libunistring…；交叉工具链依赖 |
| `icu4c@78` | 78.3 | core 同名接管（源码） | autotools；`keg_only`；freeling 依赖；`revision` 与 core 同步 |
| `jemalloc` | 5.4.0 | core 同名接管（源码） | autotools；nghttp2 依赖 |
| `jpeg-turbo` | 3.2.1 | core 同名接管（源码） | cmake；qemu 依赖 |
| `libassuan` | 3.0.2 | core 同名接管（源码） | autotools；`gnupg`/`pinentry` 依赖；依赖 `libgpg-error` |
| `libev` | 4.33 | core 同名接管（源码） | autotools；nghttp2 依赖 |
| `libgcrypt` | 1.12.4 | core 同名接管（源码） | autotools；`gnupg` 依赖；依赖 `libgpg-error` |
| `libgpg-error` | 1.61 | core 同名接管（源码） | autotools；GnuPG 全家桶基础库；依赖 `fork-gettext` |
| `libidn2` | 2.3.8 | core 同名接管（源码） | autotools；curl3/gnutls/libpsl/wget 依赖 |
| `libimobiledevice` | 1.4.0 | core 拷入（源码） | idevice 栈主包；30+ 工具；全部依赖自瓶化 |
| `libimobiledevice-glue` | 1.3.3 | core 拷入（源码） | 依赖 `libplist` |
| `libksba` | 1.9.1 | core 同名接管（源码） | autotools；`gnupg` 依赖；依赖 `libgpg-error` |
| `libnghttp2` | 1.71.0 | core 同名接管（源码） | lib-only；curl3/nghttp2 依赖 |
| `libnghttp3` | 1.19.0 | core 拷入（源码） | cmake；curl3 依赖 |
| `libngtcp2` | 1.26.0 | core 拷入（源码） | cmake；fork-openssl@4 |
| `libplist` | 2.8.1 | core 拷入（源码） | idevice 栈叶子 |
| `libpng` | 1.6.59 | core 同名接管（源码） | autotools；qemu 依赖 |
| `libpsl` | 0.23.3 | core 同名接管（源码） | autotools；curl3/wget 依赖 |
| `libslirp` | 4.9.7 | core 拷入（源码） | meson；`glib`；qemu 依赖 |
| `libssh` | 0.12.2 | core 同名接管（源码） | cmake；fork-openssl@4 |
| `libssh2` | 1.11.1 | core 同名接管（源码） | autotools；aria2/curl3 依赖；fork-openssl@4 |
| `libtatsu` | 1.1.1 | core 拷入（源码） | TSS 库；revision 与 core 同步 |
| `libusb` | 1.0.30 | core 同名接管（源码） | autotools；gnupg/qemu 依赖 |
| `libusbmuxd` | 2.1.1 | core 拷入（源码） | idevice USB 复用；revision 同步 |
| `libyaml` | 0.2.5 | core 同名接管（源码） | autotools；dtc 依赖 |
| `lzo` | 2.10 | core 同名接管（源码） | autotools；qemu 依赖 |
| `make` | 4.4.1 | core 拷入（源码） | 装成 `gmake`；与 core 同名 |
| `mercurial` | 7.2.4 | core 拷入（源码） | `pip install` + `contrib/chg`；依赖本 tap `python@3.11`（避开 Python 3.15 反爬补丁）；与 core 同名 |
| `meson` | 1.12.1 | core 拷入（pip 安装） | 依赖本 tap `ninja` + `python@3.15`；与 core 同名 |
| `mpdecimal` | 4.0.1 | core 同名接管（源码） | autotools；python 家族依赖 |
| `ncurses` | 6.6 | core 同名接管（源码） | autotools；`keg_only :provided_by_macos`；bash/qemu 依赖 |
| `neofetch` | 7.1.0 | GitHub archive tag（纯脚本） | 已归档最后一版；不检查更新 |
| `nettle` | 4.0 | core 同名接管（源码） | autotools；gnutls 依赖；fork-gmp |
| `nghttp2` | 1.71.0 | core 拷入（源码） | `--enable-app`；`c-ares`/jemalloc/libev/libnghttp2/fork-openssl@3 |
| `npth` | 1.8 | core 同名接管（源码） | autotools；`gnupg` 依赖；零运行时依赖 |
| `p11-kit` | 0.26.6 | core 同名接管（源码） | meson；gnutls 依赖；fork-libtasn1 |
| `pinentry` | 1.3.3 | core 同名接管（源码） | autotools；`gnupg` 依赖；依赖 `libassuan`/`libgpg-error` |
| `pixman` | 0.46.4 | core 同名接管（源码） | meson；qemu 依赖 |
| `python@3.11` | 3.11.18 | core 拷入（源码） | `mpdecimal`/`sqlite`/fork-openssl@3/fork-xz；与 core 同名 |
| `python@3.14` | 3.14.10 | core 同名接管（源码） | `mpdecimal`/`sqlite`/fork-openssl@4/fork-xz/fork-zstd；交叉工具链依赖 |
| `python@3.15` | 3.15.2 | core 拷入（源码） | `mpdecimal`/`sqlite`/fork-openssl@4/fork-xz/fork-zstd；meson 依赖；与 core 同名 |
| `qemu` | 11.1.3 | 上游源码 tar.xz | CI 代编译 68 目标；`glib`/`gnutls`/`jpeg-turbo`/`libpng`/`libusb`/`lzo`/`ncurses`/`pixman`/`capstone`/`dtc`/`libslirp`/`vde`/fork-zstd |
| `ripgrep` | 15.2.0 | core 拷入（源码） | fork-pcre2；opencode 依赖 |
| `simdjson` | 5.2.0 | core 同名接管（源码） | cmake |
| `snappy` | 1.3.1 | core 同名接管（源码） | cmake；fork-pkgconf 构建 |
| `socat` | 1.8.1.3 | core 拷入（源码） | fork-openssl@3；test 走回环 |
| `spirv-tools` | 1.4.363.0 | core 同名接管（源码） | cmake；`glslang` 等着色器工具链依赖；零运行时依赖（`spirv-headers` 为纯构建依赖 `all` 瓶） |
| `sqlite` | 3.54.1 | core 同名接管（源码） | autotools；`keg_only :provided_by_macos`；aria2/python 依赖；fork-readline |
| `svt-av1` | 4.3.0 | core 同名接管（源码） | cmake |
| `vde` | 2.3.3 | core 拷入（源码） | 2016 旧代码需 `-std=gnu17` |
| `vulkan-loader` | 1.4.363.0 | core 同名接管（源码） | cmake；Vulkan ICD Loader；运行时仅依赖 core `vulkan-headers`（`all` 瓶） |
| `wabt` | 1.0.42 | core 拷入（源码） | cmake；fork-openssl@4 |
| `wget` | 1.25.0 | core 拷入（源码） | `libidn2`/`libpsl`/fork-openssl@4/fork-gettext |
| `wimlib` | 1.14.5 | core 拷入（源码） | autotools；fork-pkgconf 构建 |

### 6.3 `fork-*` 依赖层（14 个）

Homebrew 禁止跨 tap 安装同名包：本机或生态中仍有 core 依赖方的底层依赖不能同名接管，因此保留改名 `fork-<core>` + `keg_only`，本仓公式按全名 `bemly/tahoe/fork-<core>` 引用；已无 core 依赖方的依赖公式已在 §6.1 / §6.2 中以原名接管（`boost@1.85` 走预编译、`abseil` 与其余 40 个源码包标为 `core 同名接管`）。`fork-*` 全部走 brew JSON 全量流，补丁随 `Patches/` 入库。

| fork 公式 | 对应 core | 版本 | 说明 |
| --- | --- | --- | --- |
| `fork-bdw-gc` | `bdw-gc` | 8.2.12 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-gettext` | `gettext` | 1.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-gmp` | `gmp` | 6.3.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-json-c` | `json-c` | 0.19 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-libtasn1` | `libtasn1` | 4.21.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-libunistring` | `libunistring` | 1.5 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-lz4` | `lz4` | 1.11.1 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-openssl@3` | `openssl@3` | 3.5.9 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-openssl@4` | `openssl@4` | 4.1.0 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-pcre2` | `pcre2` | 10.49 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-pkgconf` | `pkgconf` | 3.0.11 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-readline` | `readline` | 8.3.6 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-xz` | `xz` | 5.8.4 | 源码现编；`keg_only`；依赖方写全名 |
| `fork-zstd` | `zstd` | 1.5.7 | 源码现编；`keg_only`；依赖方写全名 |

### 6.4 cask（25 个，桌面 app / 输入法）

cask 无 bottle 机制：watcher 检测到新版后下载发布包、上传本仓 GitHub Release、改写 `Casks/<name>.rb`，**不触发 `bottle.yml`**。

| 软件 | 版本 | 架构 | 说明 |
| --- | --- | --- | --- |
| `afm` | 2026.09.15 | arm64 | 输入法；用户级 `~/Library/Input Methods`；arm64 破例；不检查更新 |
| `amd` | 2026.09.18 | universal | 自有软件；app + `obcli`；本地构建镜像；不检查更新 |
| `antigravity` | 2.34.0-5887025308631040-cn1 | Intel | 官方 darwin-x64 + 汉化/补充词典/页内 DOM 挂件/禁自更新；`patched.yml` 构建并传 `.sha256` sidecar；customRelease 读 core cask API 判新 |
| `blender-5x` | 5.2.2 | Intel | Intel 社区构建；github 流；镜像 |
| `brewui` | 0.6.0 | universal | universal；github 流；镜像 |
| `checkra1n` | 0.12.4 | Intel | core cask 已 disable；镜像；不检查更新 |
| `doubao-ime` | 1.1.1 | universal | 输入法；custom API；声明式 steps；镜像 |
| `dsh-gui` | 0.2.1-rc.4 | Intel | nightly feed 判新；镜像 |
| `github-copilot-app` | 1.4.3 | Intel | brewCask 判新；Intel dmg 实算；镜像 |
| `grok-bot` | 1.2.3 | Intel | Cursor 下载页锚定；镜像 |
| `heliport` | 2.0.0-alpha | universal | universal；不检查更新 |
| `konsole` | 5493 | dual | KDE CI 构建号；双架构；`alwaysUpdate`；每月手动跑 |
| `lceda-pro` | 4.1.105 | Intel | 官网下载页 Intel 行；zip 套 dmg；镜像 |
| `lceda` | 6.5.61 | Intel | 官网下载页 Intel 行；镜像 |
| `lody` | 0.113.1 | Intel | brewCask 判新；镜像 |
| `macos-tskmgr` | 1.1.1 | dual | 双架构；不检查更新 |
| `mirage-wallpaper` | 1.1.6 | Intel | customRelease + `.sha256`；镜像 |
| `palera1n` | 3.0.0-beta.2 | universal | universal dmg；不检查更新 |
| `qoder` | 0.5.17 | Intel | qoder.cn 更新日志；镜像；与 core 同名 |
| `qwen-ime` | 1.2.60.60 | universal | 上游下载 API；镜像 |
| `toshllm` | 0.88.0 | Intel | github 流；app 自带更新器 |
| `winstart` | 0.13.6 | universal | 本地包人工发版；不检查更新 |
| `wireshark` | 4.4.20 | Intel | Sparkle appcast Intel 项；镜像；ChmodBPF |
| `workbuddy` | 5.11.3.43806934 | Intel | Electron 更新接口；镜像 |
| `zcode` | 3.19.1 | dual | brewCask + 双架构；镜像 |

## 7. Watcher 工作原理

`watch-updates.yml`（只有全量模式）在 `ubuntu-latest` 上运行：

1. 遍历 `Formula/*.rb` 与 `Casks/*.rb`，按同名匹配 `updater/<name>.swift`（11 个 pinned 包故意无检查器：`afm`、`amd`、`checkra1n`、`cmd`、`ffserver`、`heliport`、`llvm`、`macos-tskmgr`、`neofetch`、`palera1n`、`winstart`）。
2. `swiftc -O updater/UpdaterCore.swift updater/<name>.swift` 编译并运行（每包 `timeout 600`）。
3. 本地版本优先取顶层 `version` 行（跳过 `fails_with` 块内），否则从 `url` 解析。
4. 上游来源（优先级 `customRelease` > `raw` > `github` > `brew`）：

| 流 | 版本判据 | url / sha 来源 | 典型 |
| --- | --- | --- | --- |
| `customRelease` | 检查器闭包调上游接口 / 页面 | 返回 `UpstreamRelease`（sha 置空则下载实算） | workbuddy、dsh-gui、qwen-ime、openjdk、swift、antigravity |
| `raw` | 源 tap 公式 raw 文本 `version` | GoReleaser 结构（`rawDualArch` 同步双块） | opencode、sst、torpedo |
| `github` | `HEAD releases/latest` 跳转 tag | 剥 `githubTagPrefix` 套 `downloadURL` 模板 | fzf、chisel、brewui、frida-server、交叉工具链 |
| `brew` 模板式 | `api/formula/<brewName>.json` | 自拼 `downloadURL` / `checksumsURL`（无清单则实算） | gh、node 家族、fastfetch、cmake |
| `brew` 全量式 | 同上 | JSON 的 `urls.stable.url` / `.checksum` | `fork-*`、qemu 链、ripgrep、python 家族 |
| `brew` cask | `api/cask/<brewName>.json` | 自给 x64 `downloadURL` 模板，sha 实算 | zcode、lody、github-copilot-app |

5. 版本按数值段比较（含预发布后缀 < 正式版；`alwaysUpdate` 例外）；设置了 `manualSyncReason` 的包（`git` / `bash` / `fork-readline`）检测到新版时不自动改写，输出 `status=manual-sync` 触发 issue 告警；设置了 `patchedReadinessCheck` 的补丁成品 cask（`antigravity`）在 Release 尚未产出时检测上游依赖 tag，已就绪则发 `status=needs-patched-build` 自动触发 `patched.yml`，未就绪则发 `status=waiting-upstream` 暂缓等待；`HEAD` 探测不可达则发 `status=upstream-missing` 并开 `automated-alert` issue。
6. 改写前先在内存通过自检再落盘：同步 `url`、`mirror`（含 `vX.Y/` 段）、顶层 `version`、`sha256`，摘除公式旧 `bottle do` 块并折叠相邻多余空行，并在版本升级时清掉旧的 `revision N`；`uploadRelease: true` 的 cask 同步上传本仓 Release 并清掉该 cask 的旧 Release。

### 7.1 workflow 复核、提交与状态契约

- 改写文件统一过 `ruby -c`；公式先将工作区软链进 Taps 目录并 `brew trust` 再跑 `brew fetch --force`，失败则还原该文件并记入 `failed`，不污染其它包。
- 非 `dry_run` 时一次性提交到 `main`，若有公式更新则用**一次** `gh workflow run` 触发 `bottle.yml`（只传公式列表），若有 `needs-patched-build` 则触发 `patched.yml`。

| status | 含义 | workflow 处理 |
| --- | --- | --- |
| `updated` | 已改写 | 语法 / fetch 复核后提交 |
| `needs-patched-build` | 补丁成品依赖已就绪 | 自动触发 `patched.yml` 构建发布 |
| `waiting-upstream` | 补丁上游尚未适配 | 暂缓跳过（不开告警 issue） |
| `up-to-date` / `newer-than-brew` | 无需更新 / 本地更新 | 跳过 |
| `brew-missing` | 未接入来源 | 跳过 |
| `manual-sync` | 含版本耦合资源 / 补丁列表 | 跳过改写 + 开 `[需人工同步]` issue |
| `upstream-missing` | 新版资源不可达 | 还原 + 开 `[告警]` issue |
| `check-failed` / 无 status | 网络故障 / 崩溃 | 还原 + 公示，绝不当成无需更新 |

## 8. GHCR 瓶策略

- **分发地址**：`root_url "https://ghcr.io/v2/bemly/tahoe"`（Homebrew 剥离 `homebrew-` 前缀）。
- **构建环境**：必须 `macos-26-intel` 才生成 `x86_64_tahoe` 标签；瓶只含当前公式自身 Cellar 内容，不含依赖，因此全部运行时依赖必须已在本仓出瓶并写全名引用。
- **核心实现细节（`bottle.yml`）**：
  - 将 `$GITHUB_WORKSPACE` 软链到 `Taps/bemly/homebrew-tahoe` 并 `brew trust bemly/tahoe`，`brew bottle --merge --write` 才会改到工作区文件。
  - 批内依赖做拓扑排序（被依赖者先出瓶）；安装前清理 runner 预装的冲突 keg（`node@24`、`cmake`、Python 3.11 等）及本批用到的同源依赖。
  - 先 `brew install --only-dependencies` 再 `--build-bottle` + `brew bottle`；版本号取 `brew list --versions`。
  - **推送前删整个包重建**：GitHub 禁止删除最后一个带标签版本，而 `pr-upload` 撞已存在标签会直接报错，因此先通过 `DELETE users/{owner}/packages/container/tahoe%2F<pkg>` 删除旧包再由 `pr-upload` 重建（重建会继承公开状态，后续仍有匿名可拉体检）。
  - 循环步骤失败时，提交瓶块步骤使用 `if: always()` 先把已成功部分的瓶块提交入库，再由失败门槛步令 job 报错退出。

## 9. 新增或修改软件 SOP

1. **调研原料**：优先找上游 **macOS amd64** 预编译包；无预编译则从 core 原文拷贝源码公式（`lib` 前缀公式在 `Formula/lib/`）。
2. **编写公式 / Cask**：严格按 §4 写 `Formula/<name>.rb` 或 `Casks/<name>.rb`，显式声明双门槛；不要手填 `bottle do`；所需运行时依赖一律在本仓闭环（同名接管或 `fork-*`）并写全名 `bemly/tahoe/<name>`；若为纯源码拷贝，同步拷贝所需补丁进 `Patches/`。
3. **登记检查器与文档**：新增 `updater/<name>.swift`（如不锁定版本），并同步更新 `README.md`、`README.zh.md` 与 `AGENTS.md §6` 表格。
4. **本地轻量验证**：按 §10 运行语法、检查器编译与必要的 fetch/install 测试（**不在开发机跑重型全量 `brew style` / `audit` 或重打包**）。
5. **提交并触发 CI**：`git add` + `commit` + `push origin main` → 视情况触发 `bottle.yml`（逗号列表或单个）或 `patched.yml`，阻塞等 CI 跑完后再本地 `git pull --ff-only` 验证。

## 10. 本地与 CI 验证边界

工作区路径为 `/Users/bemly/Projects/tahoe-intel`，本地开发建议将 Taps 目录软链到该工作区：

```bash
rm -rf "$(brew --repository)/Library/Taps/bemly/homebrew-tahoe"
ln -s /Users/bemly/Projects/tahoe-intel "$(brew --repository)/Library/Taps/bemly/homebrew-tahoe"
brew trust bemly/tahoe
```

- **开发机（轻量验证）**：
  - 语法检查：`"$(brew --repository)/Library/Homebrew/vendor/portable-ruby/current/bin/ruby" -c Formula/<name>.rb`（或 `Casks/<name>.rb`；macOS 自带 `/usr/bin/ruby` 为 2.6，遇到 `def foo = ...` 无尽方法会误报语法错）或 `brew readall bemly/tahoe`
  - 检查器编译与运行：`swiftc -O updater/UpdaterCore.swift updater/<name>.swift -o /tmp/check-<name> && /tmp/check-<name>`
  - 需要确认包体时：`brew info` / `brew fetch` / `brew install` / `brew test`
- **CI（重型任务）**：
  - 全仓或大包 `brew style` / `brew audit --strict`、瓶包构建（`bottle.yml`）、`antigravity` 补丁包重打与 lint（`patched.yml`）一律在 GitHub Actions `macos-26-intel` runner 执行，避免拖死 Intel 开发机。

## 11. 核心规范与避坑清单

### 11.1 公式解包、权限与版本扫描

- **解压路径用通配**：brew 解压若只有唯一顶层目录（过滤 `__MACOSX` 后）会自动下降进入；`install` 内用 `Dir["**/bin/foo"]` 或 `Dir["*"]` 兼容下降与否。
- **可执行位**：`xz` / `gz` 裸二进制与 `write_exec_script` 不会自动带执行位（0444/0644），必须在 `install` 内显式 `chmod 0555`。公式安装勿手动清 `com.apple.quarantine`（`0555` 会 Permission denied，brew 公式层已处理）。
- **`version` 行准则**：与 URL 扫描结果一致时不能写（audit 判冗余）；仅当尾缀数字（`-x64` / `-X64` / `osx-13.3`）、版本目录（`/glib/2.88/`、`/v3.8/`）或无版本扩展名（`.pem`）导致扫错/扫不出时才显式声明。
- **其他公式约束**：闭源软件不写 `license`；在 core `curl` 递归树内的源码公式须保留至少一条 `http://` `mirror` 行；2016 年前后的旧 C 代码（如 `vde`）在 Xcode 26 Clang 默认 `gnu23` 下会因 `int f()` 语义改变报错，需加 `ENV.append "CFLAGS", "-std=gnu17"`；`brew test` 涉网用例（如 `socat`、`curl3`）须优先走本地回环以免沙箱挂死。

### 11.2 依赖闭环与同名冲突

- **跨 tap 同名互斥**：同名公式或同 token cask 与 core 共用 `Cellar/<name>` / `Caskroom/<token>`，Homebrew 会在安装校验无条件报错，依赖同样适用。因此除改名 `fork-*`（`keg_only`）与本仓独有包外，同源软件安装/切换前必须先卸载另一方；公式命名也不可撞 core 的历史改名别名（如 `rustup-init` → `rustup`）。
- **严禁全名与裸名在递归树共存**：同一软件在依赖树中同时以 `bemly/tahoe/X` 与 `X`（core）出现时，macOS `flock` 同进程双开会自锁卡死（如 `python@3.14` 隐含裸 `cmake`）。冲突的构建工具（如 `llvm`/`z3` 用到的 `cmake`）须摘除 `depends_on`，改在 `install` 顶部用 `ENV.prepend_path "PATH", Formula["bemly/tahoe/cmake"].opt_bin` 并在 `bottle.yml` 预装。
- **runner 兼容**：`macos-26-intel` runner 镜像自带的 brew 版本较旧，抄写 core 新公式时须避开新引入的 helper（如 `Formula#python3`），改用 `formula_opt_bin(...)` 等既有 API；且依赖的本地补丁必须一并拷入 `Patches/`。
- **装后审计与豁免**：`audit --strict` 只在包**已安装**时扫描异架构二进制；随包附带、运行时用不到的文件（如 `deepseek-harness` 内的 `darwin-arm64` 预编译件与 `swift` 工具链内的跨架构运行时库）才进 `audit_exceptions/mismatched_binary_allowlist.json`（glob 须 `/**/*` 结尾），跑不起来的可执行文件直接不装。

### 11.3 Watcher 检查器与改写

- **Swift 编译规则**：`updater/` 必须用 `swiftc -O` 编译执行；检查器构造实参必须严格与 `CheckConfig.init` 声明同序；HTTP header 解析统一用 `CharacterSet.newlines` 兼容 runner curl 的纯 `\r` 分隔；`github` 流只认含 `/tag/` 的 `Location` 跳转。
- **版本解析与比较**：解析与改写 `version` 时跳过 `fails_with ... do ... end` 块；数字段按数值判等（兼容去零/补零，如 `yt-dlp`），预发布后缀小于正式版；raw 流先截 `on_linux` 并识别 `intel?` 块。
- **sha 与改写安全**：brew JSON 的 `urls.stable.checksum` 只属于源码包（仅全量式可用），模板式必须读 `checksums.txt`（注意 `*` 前缀不匹配时置 `nil`）或下载实算；`customRelease` 与全量式整条替换 `url` 行（因此原本使用 `#{version}` 插值的镜像 cask 在 watcher 跑过后会变字面量，需保持插值时按需改回），模板式同步替换 `url` 与 `mirror` 版本子串及 `vX.Y/` 目录段；改写时摘除 `bottle do` 并折叠相邻多余空行、版本变更时清掉旧 `revision N`，且在内存自检通过后才落盘；含版本耦合资源/补丁列表的公式（`git`、`bash`、`fork-readline`）通过 `manualSyncReason` 走 `status=manual-sync` 告警，无 `status` 输出一律视为失败还原。

### 11.4 GHCR 制瓶

- 传给 `bottle.yml` 的名单绝不能混入 cask 名；批内依赖靠 `bottle.yml` 拓扑排序保证先出瓶。
- 同版本改布局验证必须用 `--build-from-source`（否则本机按有效瓶块倒旧瓶）；删包重建后若本机报错 `Couldn't find manifest matching bottle checksum`，执行 `brew fetch --force --bottle-tag=tahoe <formula>` 刷缓存即可。

### 11.5 Cask 镜像与声明式 Steps

- **全 cask 镜像策略**：所有 cask 均镜像最新版至本仓 Release（tag `<name>-<ver>`，空格与 `%20` 替换成 `.`），`deleteOldCaskReleases` 只删「`<name>-` 后紧跟数字」的旧 tag（防误删 `lceda-` 下的 `lceda-pro-*`）。
- **容器与命名**：zip 内含多文件套 dmg 时用 `container nested: "<name>.dmg"`；`Cask/ArrayAlphabetization` 按 `line.strip.downcase` 排序（如 `com.*` 排在大写开头的目录名之前）。
- **声明式 steps 与输入法**：brew 7 禁止命令式 `preflight`/`postflight`，统一用 `preflight_steps` / `postflight_steps`（内部使用 `{{staged_path}}` / `{{appdir}}` token，写家目录配置需声明 `writable_paths` + `writable_base: :home`）。输入法直接解出真身装到 `~/Library/Input Methods`（免 sudo）、`set_permissions` 加 `u+w`、幂等写入 `AppleEnabledInputSources` 并重启 `cfprefsd` / `TextInputMenuAgent` / `SystemUIServer`。

### 11.6 `antigravity` 补丁成品构建

- **asar 格式与完整性**：`tools/asar-lib.mjs` 写入头部的 `@4/@8` 必须使用 4 字节对齐后的长度（`align4(jsonLen)+8` / `+4`），`@12` 为真实 JSON 长度；官方包未启用 integrity fuse，修改 `app.asar` 后无需改动 `Info.plist`，写包器仍重算条目哈希。可用 `ELECTRON_RUN_AS_NODE=1 Antigravity ...` 实读 `app.asar` 验证。
- **汉化与注入**：`build.sh` 通过 `git ls-remote --tags` 自动解析汉化引擎最新适配 tag（缺失直接失败，绝不拿旧字典硬上）；引擎目录显式置 `{"type":"commonjs"}` 防外部 `"type":"module"` 污染；`ag_audit.js check` 作为硬质量门；`inject-widget.mjs` 禁用 `dist/updater.js` 中 4 处更新锚点（`AutoUpdater` 日志归零），并在 `dist/preload.js` 注入页内 DOM 挂件（门控选择器 `[data-testid="agent-input-box"]`，图片走 base64 data URL）及 `extra-l10n.js` 补充词典（元素级 `FILTER_REJECT` 剪枝、词边界匹配）。
- **重签与交付**：`codesign --force --deep --sign -` 绝不保留 hardened runtime（否则无 Team ID 会 SIGABRT）；cask 的 `postflight_steps` 用 `xattr -d -r -s com.apple.quarantine` 连同 framework 符号链接一起清零（`must_succeed: false`）。因 `hdiutil create` 不逐字节可复现，cask sha256 必须取当次上传 Release 的 `.sha256` sidecar（由 `patched.yml` 回填并 lint 后提交）。在 `patched.yml` / `build.sh` 中锁定非最新宿主版本时，须同时提供 `version`、`build` 与 `official_sha` 以保持官方 dmg 校验门。

## 12. 后续演进

- [ ] 补齐当前 watcher 升级后尚未制瓶的 6 个公式瓶块（`docker-buildx`、`frida-server`、`gh`、`graphviz`、`iperf3`、`llvm-mingw`）。
- [ ] 在真实多包更新下持续验证 `watch-updates.yml` → 单次 `bottle.yml` 端到端链路稳定性。
- [ ] 评估接入 `brew livecheck` 作为辅助版本验证手段。
- [ ] 新增或移除公式 / cask 时，同步保持 `AGENTS.md §6`、`README.md`、`README.zh.md` 与 `updater/` 完全一致。
