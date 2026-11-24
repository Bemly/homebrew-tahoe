# bemly/tahoe

English | [中文说明](README.zh.md)

A third-party Homebrew tap that provides directly installable software for
**Intel (x86_64) Macs running macOS 26 (Tahoe)**.

## Why

Starting with macOS 26, Homebrew no longer builds `x86_64` bottles. In practice the
number of `x86_64_tahoe` bottles in `homebrew/core` is 0, so software like
`gh` and `node` would otherwise require compiling from source on Intel Macs.

This tap prioritizes upstream **official macOS amd64 prebuilt packages** (no recompilation);
for source-only software and unbottled runtime dependencies (`fork-*` and same-name takeovers),
it compiles them once on a `macos-26-intel` CI runner and distributes all bottles via **GHCR**
(`ghcr.io/v2/bemly/tahoe`) so users never compile locally. Desktop apps and input methods are
delivered as **casks** mirrored to this repository's GitHub Releases.

## Requirements

- CPU: **Intel (x86_64)** — do NOT use on Apple Silicon (use `homebrew/core` instead).
- OS: **macOS 26 (Tahoe)** or later.

Formulae enforce this with `depends_on arch: :x86_64` and `depends_on macos: :tahoe`;
installation is rejected outright if requirements are not met.

Explicit exceptions:
- `opencode` / `ripgrep`: dual-arch formulae (`macos: :tahoe` still enforced; Intel uses GHCR bottles, Apple Silicon uses direct upstream links or source builds).
- `afm`: Apple Silicon-only (`depends_on arch: :arm64`) own-software input method cask (Intel refuses install).
- Universal / dual-arch casks (`amd`, `brewui`, `doubao-ime`, `heliport`, `konsole`, `macos-tskmgr`, `palera1n`, `qwen-ime`, `winstart`, `zcode`): support both Intel and Apple Silicon.

## Installation

```bash
brew tap bemly/tahoe

# If you previously installed the homebrew/core build, uninstall it first:
# formulae with the same name across taps cannot coexist — brew refuses to install.
brew uninstall gh
brew uninstall fastfetch
brew uninstall opencode # core ships an npm-based opencode under the same name

brew install bemly/tahoe/gh
brew install bemly/tahoe/fastfetch
brew install bemly/tahoe/opencode # pulls bemly/tahoe/ripgrep as a dependency

# workbuddy is a desktop app, delivered as a cask (installed into /Applications,
# visible in Launchpad/Spotlight)
brew install --cask bemly/tahoe/workbuddy
# doubao-ime is an input method, delivered as a cask (installed into user-level
# ~/Library/Input Methods without sudo, auto-enables the system input source)
brew install --cask bemly/tahoe/doubao-ime
# antigravity is delivered as a cask too, but as a *patched artifact*: Chinese
# localization and an in-page companion widget are baked into app.asar, and the
# in-app auto-update is disabled so the patch survives. The cask clears brew's
# quarantine flag after install, so it opens without a Gatekeeper prompt
# (the re-sign is ad-hoc, so there is no notarization).
brew install --cask bemly/tahoe/antigravity
```

## Packages

> Total: **144 formulae** (60 prebuilt + 70 source-built + 14 `fork-*` dependency forks) and **25 casks**.

### CLI & Developer Tools — Prebuilt Formulae (60)

| Package | Notes |
| --- | --- |
| `aarch64-unknown-linux-gnu` | GCC cross toolchain targeting aarch64 Linux (Intel host prebuilt, thin x86_64); runtime deps use this tap's `guile`, `python@3.14`, `fork-bdw-gc`, `fork-xz`, and `fork-zstd` |
| `antigravity-cli` | Google Antigravity CLI (`agy`), repackaged from the official Intel macOS flat binary; version tracked from the official auto-updater manifest |
| `boost@1.85` | Boost C++ 1.85 libraries from third-party `prebuilt-boost` macOS x86 `static+shared` archive (dylibs get `@rpath` patched and re-signed ad-hoc); dependency of `freeling`; same-name conflict with core |
| `bun` | JavaScript runtime/bundler/package manager, official Intel prebuilt (`bun-darwin-x64.zip`, ships `bun` + `bunx` symlink); same-name conflict with core |
| `caddy` | Extensible web server with automatic HTTPS, Intel static build from upstream (`caddy_<ver>_mac_amd64.tar.gz`) |
| `chisel` | Fast TCP/UDP tunnel over HTTP(S), official Intel bare binary (`chisel_<ver>_darwin_amd64.gz`, zero dependencies); shares its name with core's unrelated LLDB command set — uninstall one before installing the other |
| `cmake` | Cross-platform build tool, upstream universal macOS package (Intel slice); core has no Intel bottle, installs in seconds instead of compiling |
| `cmd` | Terminal AI coding agent, npm package `command-code` (exposes the `cmd` command only); depends on this tap's `node` bottle; pinned, no update checks |
| `deepseek-harness` | DeepSeek agent harness, npm package `@deepseek-ai/dsh` (exposes `dsh`, `dsh web` serves the browser UI); depends on this tap's `node` bottle; tracks npm `latest` |
| `docker` | Docker CLI, official macOS x86_64 static binary (`docker-<ver>.tgz`) with generated completions; same-name conflict with core |
| `docker-buildx` | Docker Buildx CLI plugin, official `buildx-v<ver>.darwin-amd64` bare binary; version tracks `homebrew/core` |
| `docker-compose` | Docker Compose plugin, official `docker-compose-darwin-x86_64` bare binary; version tracks `homebrew/core` |
| `dotnet` | .NET SDK, repackaged from the official macOS x64 tarball (whole tree into prefix plus a `dotnet` shim); tracked via Microsoft's release-metadata API; same-name conflict with core |
| `exiftool` | Read/write/edit image metadata, pure Perl from official `Image-ExifTool-<ver>.tar.gz` (omits core's optional XS/Brotli/LZMA modules); same-name conflict with core |
| `fastfetch` | Neofetch-like system info tool, taken from `fastfetch-macos-amd64.tar.gz` (release tag has no `v` prefix) |
| `ffmpeg` | FFmpeg itself, Intel x86_64 static build from evermeet (`ffmpeg-<ver>.zip`); version tracks `homebrew/core` |
| `ffplay` | FFmpeg media player, Intel static build from evermeet, versioned with this tap's `ffmpeg`; no core counterpart |
| `ffprobe` | FFmpeg stream analyzer, Intel static build from evermeet, versioned with this tap's `ffmpeg`; no core counterpart |
| `ffserver` | Legacy FFmpeg streaming server (last static build 3.4.2, removed upstream in 4.0); pinned, no update checks |
| `fish` | User-friendly shell, unix tree from the official `fish-<ver>.app.zip` (Intel slice of universal binary); version tracks `homebrew/core` |
| `frida-server` | Frida dynamic instrumentation server, upstream bare binary from `frida/frida` releases (Intel only); run with `sudo`, listens on `127.0.0.1:27042` |
| `fzf` | Command-line fuzzy finder, upstream `fzf-<ver>-darwin_amd64.tar.gz` single binary; version tracked from GitHub releases |
| `gh` | GitHub CLI, taken directly from `gh_<ver>_macOS_amd64.zip` |
| `git-lfs` | Git extension for versioning large files, upstream Intel build with full man pages (`git-lfs-darwin-amd64-v<ver>.zip`); run `git lfs install` once after install |
| `go` | Go toolchain, official `go<ver>.darwin-amd64.tar.gz` (self-contained, zero dependencies); version tracks `homebrew/core` |
| `h2spec` | HTTP/2 specification conformance testing tool, official `h2spec_darwin_amd64.tar.gz` |
| `hyperfine` | Command-line benchmarking tool, official `hyperfine-v<ver>-x86_64-apple-darwin.tar.gz` with man pages and completions |
| `iperf3` | Network bandwidth measurement tool, static build (`iperf3-amd64-osx-15`, zero `openssl@4` dependency) |
| `jadx` | Dex to Java decompiler (`jadx` and `jadx-gui`), official `jadx-<ver>.zip` prebuilt release; depends on this tap's `openjdk`; same-name conflict with core |
| `jpeg-turbo` | JPEG codec, repackaged from the official universal2 DMG (thin x86_64, relocated dylibs/rpaths); dependency of `qemu` |
| `lima` | Linux virtual machines (`limactl`/`lima` and friends), official `lima-<ver>-Darwin-x86_64.tar.gz` prebuilt with generated completions; same-name conflict with core |
| `llvm` | Compiler infrastructure, upstream 19.1.7 Intel macOS prebuilt pinned (later releases are ARM64-only; building 23.x from source exceeds the 6h CI limit); thin x86_64, zero deps, keg-only; point bindgen at it via `LIBCLANG_PATH` |
| `llvm-mingw` | LLVM/Clang-based mingw-w64 cross toolchain (Intel host → Windows), version tracked from GitHub releases |
| `mufetch` | System info tool, from `mufetch_darwin_x86_64.tar.gz` |
| `ninja` | Small build system, upstream universal binary (Intel slice) |
| `nzbget` | Binary newsgrabber, official `nzbget-<ver>-bin-macos-x64.zip` prebuilt with CLI and WebUI; uses this tap's `sevenzip`; same-name conflict with core |
| `node` | Node.js runtime, taken directly from the official `node-v<ver>-darwin-x64.tar.gz` |
| `node@20` | Node.js 20 LTS, taken directly from the official `node-v20.x-darwin-x64.tar.gz`; same-name conflict with core |
| `node@22` | Node.js 22 LTS, taken directly from the official `node-v22.x-darwin-x64.tar.gz` |
| `node@24` | Node.js 24 LTS, taken directly from the official `node-v24.x-darwin-x64.tar.gz` |
| `opencode` | AI coding agent, macOS builds (`opencode-darwin-x64/arm64.zip`) from `anomalyco/homebrew-tap` (Intel bottled, ARM direct link); depends on `bemly/tahoe/ripgrep`; shares its name with core's npm build |
| `openjdk` | OpenJDK 26 GA official macOS x64 prebuilt (`keg_only`); shares its name with core's formula |
| `openjdk@17` | Eclipse Temurin 17 x64 JDK (tracked via Adoptium API, `keg_only`); same-name conflict with core |
| `openjdk@21` | Eclipse Temurin 21 x64 JDK (tracked via Adoptium API, `keg_only`); same-name conflict with core |
| `openjdk@26` | OpenJDK 26 GA official macOS x64 prebuilt (`keg_only`, pinned to line 26); same-name conflict with core |
| `postgresql@13` | PostgreSQL 13, repackaged from EDB's official macOS x64 binaries (bin/include/lib/share only — pgAdmin skipped); `keg_only` to avoid bundled openssl/icu conflicts; add `opt/postgresql@13/bin` to `PATH` |
| `protobuf` | Protocol buffers compiler (`protoc` + headers), official macOS x86_64 prebuilt (`protoc-<ver>-osx-x86_64.zip`); same-name conflict with core |
| `ripgrep` | Fast grep replacement, official macOS x86_64/arm64 prebuilt with PCRE2; zero build dependencies; dependency of `opencode` |
| `rustup` | Official static Rust toolchain installer, same name as core; ships `rustup` plus cargo/rustc proxy shims, toolchains managed via `rustup toolchain install stable` |
| `scrcpy` | Android screen mirroring tool, upstream Intel static build (zero runtime dependencies, includes `adb` and `scrcpy-server`) |
| `sevenzip` | Official 7-Zip 26.06 Intel prebuilt (`7zz`); runtime dependency of `binwalk` and `nzbget`, build dependency of `jpeg-turbo`; same-name conflict with core |
| `sst` | SST framework, Intel-only slice of `anomalyco/homebrew-tap` (`sst-mac-x86_64.tar.gz`) |
| `starship` | Cross-shell prompt, official x86_64 prebuilt (`starship-x86_64-apple-darwin.tar.gz`) with generated shell completions; same-name conflict with core |
| `swift` | Official Swift macOS `.pkg` repackaged, exposing only `swift`/`swiftc` (no collisions with other toolchains); tracked from swift.org |
| `torpedo` | `sst/torpedo` VPC database access tool, Intel-only slice of `anomalyco/homebrew-tap` (`torpedo-mac-x86_64.tar.gz`) |
| `x86_64-unknown-linux-gnu` | GCC cross toolchain for x86_64 Linux (Intel host prebuilt, thin x86_64); runtime deps use this tap's `guile`, `python@3.14`, `fork-bdw-gc`, `fork-xz`, and `fork-zstd` |
| `xcodegen` | Generate Xcode projects from a spec file, official universal prebuilt (`xcodegen.zip` with `SettingPresets`, zero dependencies); same-name conflict with core |
| `yt-dlp` | Feature-rich audio/video downloader, upstream universal macOS binary (zero dependencies; avoids pulling a full Python stack) |
| `z3` | Theorem prover, official macOS x64 prebuilt (`z3-<ver>-x64-osx-13.3.zip`, zero dependencies); same-name conflict with core |
| `zig` | Zig toolchain, official `zig-x86_64-macos-<ver>.tar.xz` (Intel host); same-name conflict with core |

### Source-Built User Formulae (32)

Compiled once on `macos-26-intel` CI from `homebrew/core` or upstream sources and distributed as GHCR bottles.

| Package | Notes |
| --- | --- |
| `aria2` | Multi-protocol download utility (`c-ares`/`libssh2`/`sqlite`/fork-openssl@4/fork-gettext); same-name conflict with core |
| `automake` | GNU Automake build tool (runtime depends on `autoconf`); same-name conflict with core |
| `bash` | GNU Bash 5.3 (`ncurses`/fork-readline/fork-gettext); same-name conflict with core |
| `binwalk` | Firmware analysis and embedded-file extraction, built with embedded official Rust 1.91.1 rustc/cargo/rust-std resources; `7zz` backport and runtime dependency on this tap's `sevenzip`; same-name conflict with core |
| `capstone` | Disassembly framework (`fork-gettext`); bottled dependency of `qemu` |
| `curl3` | Independent HTTP/3 client with MASQUE/CONNECT-UDP (`--enable-proxy-http3`, core doesn't enable it); renamed to coexist with core's curl, ships the `curl3` command only |
| `dtc` | Device tree compiler (`libyaml`); bottled dependency of `qemu` |
| `freeling` | Language analysis suite (tokenizing, POS tagging, NER); unbundles bundled dynet/eigen in favor of `boost@1.85`, `dynet`, `icu4c@78`; same-name conflict with core |
| `git` | Distributed version control system (`fork-pcre2`/`fork-gettext` on macOS with CommonCrypto); same-name conflict with core |
| `gnupg` | GNU Privacy Guard (OpenPGP), compiled from core sources using `gnutls`, `libusb`, `fork-readline`, `fork-gettext`, and the GnuPG C library stack; same-name conflict with core |
| `graphviz` | Graph visualization software, zero-runtime-dependency build (Quartz and built-in plugins provide PDF/PNG/SVG) |
| `libimobiledevice` | iOS device communication tools (`idevice*`), compiled with `libimobiledevice-glue`, `libplist`, `libtatsu`, `libusbmuxd`, `fork-libtasn1`, `fork-openssl@4` |
| `libimobiledevice-glue` | Glue library for the `libimobiledevice` stack (`libplist`); same-name conflict with core |
| `libnghttp3` | HTTP/3 C library; bottled dependency of `curl3` |
| `libngtcp2` | QUIC protocol C library (`fork-openssl@4`); bottled dependency of `curl3` |
| `libplist` | Apple Property List library; base leaf of the `libimobiledevice` stack |
| `libslirp` | User-mode networking library (`glib`); bottled dependency of `qemu` |
| `libtatsu` | Apple TSS library for the `libimobiledevice` stack |
| `libusbmuxd` | USB multiplexor library for iOS devices |
| `make` | GNU make (installed as `gmake`), mirrored even though core has a tahoe bottle |
| `mercurial` | Distributed version control system (`hg` + `chg`), built with this tap's `python@3.11`; same-name conflict with core |
| `meson` | Fast build system, depends on this tap's `ninja` and `python@3.15` so updates never rebuild Python from source; same-name conflict with core |
| `neofetch` | System info script (archived upstream, last release 7.1.0); pinned, no update checks |
| `nghttp2` | HTTP/2 tools (`nghttp`/`h2load`/`nghttpx`) built with `--enable-app` (`c-ares`/`jemalloc`/`libev`/`libnghttp2`/`fork-openssl@3`) |
| `python@3.11` | Python 3.11 interpreter (`mpdecimal`/`sqlite`/`fork-openssl@3`/`fork-xz`); used by `mercurial`; same-name conflict with core |
| `python@3.15` | Python 3.15 interpreter (`mpdecimal`/`sqlite`/`fork-openssl@4`/`fork-xz`/`fork-zstd`); used by `meson`; same-name conflict with core |
| `qemu` | Generic machine emulator and virtualizer (68 targets, full tap dependency closure bottled on CI) |
| `socat` | SOcket CAT relay tool (`fork-openssl@3`), compiled from source |
| `vde` | Virtual distributed Ethernet (`-std=gnu17` for Clang 26), bottled dependency of `qemu` |
| `wabt` | WebAssembly Binary Toolkit (`wat2wasm`/`wasm2wat` and friends, `fork-openssl@4`; upstream macOS asset is arm64-only) |
| `wget` | Internet file retriever (`libidn2`/`libpsl`/`fork-openssl@4`/`fork-gettext`/`fork-libunistring`); same-name conflict with core |
| `wimlib` | Library and `wimlib-imagex` tools for WIM images (zero macOS runtime dependencies, built with `fork-pkgconf`) |

### Runtime Dependency Layer — Same-Name Takeovers (38 source libraries) & `fork-*` (14)

Runtime dependencies that lack `x86_64_tahoe` bottles in `homebrew/core` are either taken over under their core name (when no `homebrew/core` dependents remain on a typical setup) or kept renamed as `keg_only` `fork-*` packages:

- **Same-name dependency libraries (38 source-built formulae, totaling 70 source-built formulae with the 32 above; `boost@1.85` prebuilt is also a same-name dependency)**:
  `abseil`, `brotli`, `c-ares`, `dynet`, `eigen@3`, `glib`, `gnutls`, `guile`, `icu4c@78`, `jemalloc`, `libassuan`, `libev`, `libgcrypt`, `libgpg-error`, `libidn2`, `libksba`, `libnghttp2`, `libpng`, `libpsl`, `libssh`, `libssh2`, `libusb`, `libyaml`, `lzo`, `mpdecimal`, `ncurses`, `nettle`, `npth`, `p11-kit`, `pinentry`, `pixman`, `python@3.14`, `simdjson`, `snappy`, `spirv-tools`, `sqlite`, `svt-av1`, `vulkan-loader`
  *(Note: `vulkan-loader` depends only on `vulkan-headers`, which ships an `all` bottle in `homebrew/core`.)*
- **Renamed `keg_only` `fork-*` packages (14)** *(do not conflict with `homebrew/core`, referenced via `bemly/tahoe/fork-*`)*:
  `fork-bdw-gc`, `fork-gettext`, `fork-gmp`, `fork-json-c`, `fork-libtasn1`, `fork-libunistring`, `fork-lz4`, `fork-openssl@3`, `fork-openssl@4`, `fork-pcre2`, `fork-pkgconf`, `fork-readline`, `fork-xz`, `fork-zstd`

### Desktop Apps & Input Methods — Casks (25)

| Cask | Arch | Notes |
| --- | --- | --- |
| `afm` | arm64 | AFM pinyin input method (Apple Silicon-only exception); installs into `~/Library/Input Methods` and auto-enables input source; pinned |
| `amd` | universal | AMD lyrics downloader + `obcli` CLI; mirrored to this repo's releases; pinned |
| `antigravity` | Intel | Google Antigravity IDE, **shipped as a patched artifact**: unpacks official Intel dmg, patches `app.asar` (Chinese localization + extra model-name dictionary + in-page Gemini companion widget; disables auto-update), re-signs ad-hoc, clears quarantine on install; built reproducibly by `Widgets/antigravity-niang/build.sh`; shares token with core's unpatched cask |
| `blender-5x` | Intel | Blender 5.x Intel-optimized community build; mirrored to this repo's releases; shares `/Applications/Blender.app` with core's `blender` |
| `brewui` | universal | Official Homebrew graphical interface (`Homebrew-<ver>.zip`); mirrored from GitHub releases |
| `checkra1n` | Intel | checkm8 jailbreak app (core's cask is disabled over Gatekeeper); mirrored; pinned |
| `doubao-ime` | universal | Doubao AI input method; installs into `~/Library/Input Methods` (user-level, no sudo) and auto-enables system input source; mirrored |
| `dsh-gui` | Intel | DeepSeek Harness desktop app; version/sha tracked from upstream nightly feed; mirrored |
| `github-copilot-app` | Intel | GitHub Copilot desktop app; mirrored from official Intel dmg; version tracks core cask |
| `grok-bot` | Intel | Cursor Grok Bot desktop agent; mirrored; version tracked from Cursor download page |
| `heliport` | universal | Intel Wi-Fi client app (`itlwmx`); mirrored; pinned |
| `konsole` | dual | KDE terminal; ARM and Intel builds are versioned and mirrored independently |
| `lceda` | Intel | LCEDA Standard EDA software; mirrored; version tracked from official download page Intel(x64) row |
| `lceda-pro` | Intel | LCEDA Pro EDA software (zip wraps a dmg); mirrored; version tracked from official download page Intel(x64) row |
| `lody` | Intel | Lody desktop app for coding agent sessions; mirrored from official Intel dmg; version tracks core cask |
| `macos-tskmgr` | dual | macOS Task Manager app, per-arch downloads via `arch` stanza; mirrored; pinned |
| `mirage-wallpaper` | Intel | Mirage native live wallpaper engine (notarized); mirrored; tracked via custom checker |
| `palera1n` | universal | checkm8 jailbreak app (universal dmg); mirrored; pinned |
| `qoder` | Intel | Alibaba Qoder CN (China edition) AI coding platform; mirrored; shares token with core's international `qoder` cask |
| `qwen-ime` | universal | Qwen AI input method; installs into `~/Library/Input Methods` (user-level, no sudo) and auto-enables system input source; mirrored |
| `toshllm` | Intel | ToshLLM local LLM runner with Metal acceleration for Intel + AMD GPUs (notarized, self-updating); mirrored |
| `winstart` | universal | Metro-style app launcher; mirrored to this repo's releases; pinned |
| `wireshark` | Intel | Network protocol analyzer (official Intel dmg; Intel builds stop at 4.4.x); ships `tshark`/`editcap` shims; mirrored |
| `workbuddy` | Intel | Tencent WorkBuddy AI office workspace (Electron desktop app); mirrored; tracked via its update feed |
| `zcode` | dual | z.ai AI-assisted development environment (`arm64` + `x64` via `arch` stanza); mirrored; version tracks core cask |

## Switching sources (same-name conflict)

Homebrew forbids installing formulae or casks with the same name/token from two
different taps at the same time — they share the same `Cellar/<name>` or `Caskroom/<token>`
directory.

Except for renamed `keg_only` `fork-*` packages (14) and tap-exclusive packages (`curl3`,
`ffplay`, `ffprobe`, `ffserver`, `antigravity-cli`, `aarch64-unknown-linux-gnu`,
`x86_64-unknown-linux-gnu`, `llvm-mingw`, `cmd`, `deepseek-harness`, `frida-server`,
`mufetch`, `sst`, `torpedo`, and tap-only casks), **any package sharing a name with
`homebrew/core` requires uninstalling the other tap's build first** (`brew uninstall <name>`
/ `brew uninstall --cask <token>`):

```bash
# Switch a formula from homebrew/core to bemly/tahoe:
brew uninstall gh
brew install bemly/tahoe/gh

# Revert back to homebrew/core:
brew uninstall bemly/tahoe/gh
brew install gh
```

`python@3.15` / `meson` are version-paired and should be switched together:

```bash
brew uninstall meson
brew uninstall --ignore-dependencies python@3.15
brew install bemly/tahoe/meson
```

`antigravity` shares its token with core's unpatched `antigravity` cask (they share
`Caskroom/antigravity` and cannot coexist):

```bash
brew uninstall --cask --force antigravity
brew install --cask bemly/tahoe/antigravity
```

`blender-5x` uses a different token, but also installs into `/Applications/Blender.app`
and conflicts with core's `blender` cask. The `fork-*` packages are renamed and `keg_only`,
so they never conflict with core.

## GHCR bottles

Formula bottles are distributed from **GHCR**: `ghcr.io/v2/bemly/tahoe`
(Homebrew strips the `homebrew-` prefix from the repository name, mirroring the
structure of `ghcr.io/v2/homebrew/core`).

Bottles are built directly from upstream prebuilt packages where available.
Source-only packages (e.g. `qemu`, `python@3.15`, `meson`) are compiled once on a
`macos-26-intel` runner — users still install bottles and never compile locally.

**A GHCR bottle contains only the formula itself, not its dependencies.** All runtime
dependencies are also bottled in this tap and referenced by full name
(`bemly/tahoe/<name>`). `bottle.yml` recursively verifies runtime dependency bottle
coverage before starting any build (`allow_unbottled_core: true` exists only as a
manual escape hatch for maintainers).

| Scenario | Behavior |
| --- | --- |
| New version | `watch-updates` uploads formula changes as an artifact; `bottle.yml` applies them on `main` and publishes each formula only after its bottle succeeds |
| No bottle in GHCR yet | `main` keeps the previous bottled version; watcher updates never force a source build |
| Upstream asset unavailable / needs manual sync | `watch-updates.yml` opens an `automated-alert` issue |

## For Maintainers

### Trigger a CI bottle build

After adding or updating a formula, push its bottle to GHCR:

1. Open **Actions → Build bottle and publish to GHCR** in the GitHub repository.
2. Click **Run workflow**.
3. Enter the formula name (single, comma-separated like `gh,fastfetch`, or `all`) and run it.

The workflow trusts the tap, checks recursive runtime dependencies, installs in
topological order with `--build-bottle`, runs `brew bottle`, recreates the GHCR package
via `brew pr-upload`, then immediately commits that formula's version and `bottle do`
block to `main` before moving to the next formula.

> Note: Newly created GHCR packages are private by default (returning `401` to anonymous
> `brew install`). If the anonymous pull check warns, change the package visibility to
> Public at `https://github.com/bemly?tab=packages` → **Package settings** → **Danger Zone**.

### Workflows

Four workflows: `watch-updates` runs **daily at 04:00 UTC (12:00 UTC+8)** and also supports `workflow_dispatch`; the other three are **manually triggered via `workflow_dispatch` only**. No workflow uses `push` or `pull_request` triggers.

| Workflow | Purpose | Runner |
| --- | --- | --- |
| `watch-updates` | Batch-scans `Formula/*.rb` and `Casks/*.rb` via `updater/*.swift` across 4 upstream stream types (`customRelease`, `raw`, `github`, `brew`); mirrors updated casks to GitHub Releases, rewrites formulae, commits to `main`, and triggers one `bottle` run | `ubuntu-latest` |
| `bottle` | Recursively verifies runtime dependency bottle coverage, builds bottles in topological order, pushes to GHCR, verifies anonymous pullability, and writes `bottle do` blocks back | `macos-26-intel` |
| `patched` | Builds the patched `antigravity` cask artifact (`build.sh --upload`), writes the `.sha256` sidecar into the cask, runs `brew style` / `brew audit --strict`, and commits to `main` | `macos-26-intel` |
| `sysroots` | Builds cross-compilation sysroots (`openssl-macos-arm64`, `linux-sysroot-x64/a64`) and publishes them to GitHub Releases | `macos-26` / `ubuntu-22.04` |

Developer conventions: see [AGENTS.md](AGENTS.md).

[![](https://img.shields.io/badge/powered_by-dsh-4D6BFE?style=flat-square&logo=deepseek&logoColor=white)](https://github.com/deepseek-ai/deepseek-harness)
