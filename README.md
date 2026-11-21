# bemly/tahoe

A third-party Homebrew tap that provides directly installable software for
**Intel (x86_64) Macs running macOS 26 (Tahoe)**.

## Why

Starting with macOS 26, Homebrew no longer builds `x86_64` bottles. In practice the
number of `x86_64_tahoe` bottles in the `homebrew/core` tap is 0, so software like
`gh` and `node` can only be compiled from source on Intel Macs.

This tap prioritizes upstream **official macOS amd64 prebuilt packages** (no recompilation);
for source-only software and unbottled runtime dependencies (`fork-*` / same-name takeovers),
it compiles them once on a `macos-26-intel` CI runner and distributes all bottles via **GHCR**
(`ghcr.io/v2/bemly/tahoe`) so users never compile locally. Desktop apps and input methods are
delivered as **casks** mirrored to this repository's GitHub Releases.

## Requirements

- CPU: **Intel (x86_64)** — do NOT use on Apple Silicon (use `homebrew/core` instead).
- OS: **macOS 26 (Tahoe)** or later.

Each formula enforces this with `depends_on arch: :x86_64` and
`depends_on macos: :tahoe`; installation is rejected outright if the requirements
are not met.

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

| Package | Notes |
| --- | --- |
| `gh` | GitHub CLI, taken directly from `gh_<ver>_macOS_amd64.zip` |
| `fastfetch` | Neofetch-like system info tool, taken from `fastfetch-macos-amd64.tar.gz` (release tag has no `v` prefix) |
| `workbuddy` | Tencent WorkBuddy AI office workspace (Electron desktop app), cask, installed into `/Applications`; not in brew core — version comes from its auto-update feed |
| `doubao-ime` | Doubao AI input method, cask, installed into `~/Library/Input Methods` (user level, no sudo) and auto-enabled by writing the system input source; not in brew core — version comes from its download API |
| `node` | Node.js runtime, taken directly from the official `node-v<ver>-darwin-x64.tar.gz` |
| `node@24` | Node.js 24 LTS, taken directly from the official `node-v<ver>-darwin-x64.tar.gz` |
| `node@22` | Node.js 22 LTS, taken directly from the official `node-v<ver>-darwin-x64.tar.gz` |
| `opencode` | AI coding agent, mac builds (`opencode-darwin-x64/arm64.zip`) from `anomalyco/homebrew-tap`'s GoReleaser formula (Intel bottled, ARM via direct link); shares its name with core's npm build — uninstall one before installing the other |
| `sst` | SST framework, Intel-only slice of `anomalyco/homebrew-tap`'s GoReleaser formula (`sst-mac-x86_64.tar.gz`) |
| `torpedo` | sst/torpedo VPC database access tool, Intel-only slice of `anomalyco/homebrew-tap`'s GoReleaser formula (`torpedo-mac-x86_64.tar.gz`) |
| `ripgrep` | Search tool like grep, bottled dependency of `opencode` (from homebrew/core sources) |
| `mufetch` | System info tool, from the release `mufetch_darwin_x86_64.tar.gz` |
| `cmd` | Terminal AI coding agent, npm package `command-code` (exposes the `cmd` command only); depends on this tap's node bottle; no update checks |
| `zcode` | z.ai AI-assisted development environment, cask from the upstream CDN (both x64 and arm64); version follows homebrew/core's cask |
| `deepseek-harness` | DeepSeek agent harness, npm package `@deepseek-ai/dsh` (exposes the `dsh` command only, `dsh web` serves the browser UI); depends on this tap's node bottle; version tracks the npm `latest` tag |
| `ffmpeg` | FFmpeg itself, Intel x86_64 static build from evermeet (`ffmpeg-<ver>.zip`); version follows homebrew/core's ffmpeg |
| `ffprobe` | FFmpeg stream analyzer, Intel static build from evermeet, versioned with this tap's ffmpeg; no core counterpart |
| `ffplay` | FFmpeg media player, Intel static build from evermeet, versioned with this tap's ffmpeg; no core counterpart |
| `ffserver` | Legacy FFmpeg streaming server (last static build 3.4.2, removed upstream in 4.0); no update checks |
| `fish` | User-friendly shell, unix tree from the official `fish-<ver>.app.zip` (Intel slice of the universal binary); version follows homebrew/core's fish |
| `docker-buildx` | Docker CLI plugin, official `buildx-v<ver>.darwin-amd64` bare binary; version follows homebrew/core's docker-buildx |
| `checkra1n` | checkm8 jailbreak app, Intel x86_64 build (core's cask is disabled over Gatekeeper); pinned, no update checks |
| `palera1n` | checkm8 jailbreak app, universal dmg covering Intel and Apple Silicon with a single download; pinned, no update checks |
| `macos-tskmgr` | Task manager app, per-arch downloads via the `arch` stanza; pinned, no update checks |
| `brewui` | Official Homebrew graphical interface, cask from its GitHub release (`Homebrew-<ver>.zip`); version tracked via the release redirect |
| `winstart` | Metro-style app launcher, cask mirrored to this repo's releases (no public upstream link); pinned, no update checks |
| `docker-compose` | Docker Compose plugin, official `docker-compose-darwin-x86_64` bare binary; version follows homebrew/core's docker-compose |
| `go` | Go toolchain, official `go<ver>.darwin-amd64.tar.gz` (self-contained, zero dependencies); version follows homebrew/core's go |
| `heliport` | Intel Wi-Fi client app, cask from its GitHub release; pinned, no update checks |
| `konsole` | KDE terminal, dual-arch builds mirrored to this repo's releases; version is the CI build number, checked manually each month |
| `qemu` | Generic machine emulator and virtualizer, compiled from source on Intel (core has no Intel bottles) |
| `capstone` | Disassembly framework, bottled dependency of `qemu` |
| `dtc` | Device tree compiler, bottled dependency of `qemu` |
| `libslirp` | User-mode networking library, bottled dependency of `qemu` |
| `vde` | Virtual distributed Ethernet, bottled dependency of `qemu` |
| `neofetch` | System info script (archived upstream, last release); no update checks |
| `curl3` | Independent HTTP/3 client with MASQUE/CONNECT-UDP (`--enable-proxy-http3`, core doesn't enable it); renamed to coexist with core's curl, ships the `curl3` command (system `curl` untouched), client-only static build with no dev files |
| `libnghttp3` | HTTP/3 C library, bottled dependency of `curl3` |
| `libngtcp2` | QUIC implementation, bottled dependency of `curl3` |
| `nghttp2` | H2 clients (`nghttp`/`h2load`/`nghttpx`) with `--enable-app`; H3 flag deferred to Phase 4 |
| `socat` | SOcket CAT relay tool, compiled from source |
| `make` | GNU make (installed as `gmake`), mirrored even though core has a tahoe bottle |
| `graphviz` | Graph visualization software, compiled from source |
| `protobuf` | Protocol buffers compiler (`protoc` + headers), official macOS x86_64 prebuilt (`protoc-<ver>-osx-x86_64.zip`); same-name conflict with core |
| `caddy` | Extensible server platform, Intel static build from upstream (`caddy_<ver>_mac_amd64.tar.gz`); H2/H3 baseline service |
| `h2spec` | HTTP/2 conformance tester for Phase 2 H2 tests |
| `hyperfine` | Command-line benchmarking tool for Phase 4 repeated benchmarks |
| `iperf3` | Static build (no `openssl@4` dependency) for Phase 4 bare-metal throughput baselines |
| `ninja` | Small build system, upstream universal binary (Intel slice) |
| `rustup` | Official static Rust toolchain installer, same name as core (uninstall core's first); ships `rustup` plus core's cargo/rustc proxy shims, toolchains managed via `rustup toolchain install stable` |
| `wireshark` | Network protocol analyzer, cask from the official Intel dmg (Intel builds stop at 4.4.x); ships `tshark`/`editcap` shims |
| `git-lfs` | Git extension for versioning large files, upstream Intel build with full man pages (`git-lfs-darwin-amd64-v<ver>.zip`); run `git lfs install` once after install |
| `github-copilot-app` | GitHub Copilot desktop app, cask mirrored from the official Intel dmg (`GitHub-Copilot-darwin-x64.dmg`); version tracked from the core cask, installed into `/Applications` |
| `frida-server` | Frida dynamic instrumentation server, upstream bare binary from `frida/frida` releases (Intel only); run with `sudo`, listens on `127.0.0.1:27042` |
| `afm` | AFM pinyin input method, Apple Silicon only (first exception to the Intel-only rule); user-level install into `~/Library/Input Methods` with automatic input-source enablement; pinned, no update checks |
| `amd` | AMD lyrics downloader (universal Intel + Apple Silicon, built locally and mirrored); ships the app plus the `obcli` command; pinned, no update checks |
| `blender-5x` | Blender 5.x Intel-optimized community build (x86_64 only); mirrored to this repo's releases, version tracked from upstream releases |
| `dsh-gui` | DeepSeek Harness desktop app (Intel only); version/sha come from upstream nightly feed, versioned dmg mirrored to this repo's releases; checked like other packages |
| `cmake` | Cross-platform build tool, upstream universal macOS package (Intel slice); core has no Intel bottle, installs in seconds instead of compiling |
| `grok-bot` | Cursor Grok Bot desktop agent (Intel only); mirrored to this repo's releases, version tracked from Cursor's download page |
| `scrcpy` | Android screen mirroring tool, upstream Intel static build (zero dependencies); core has no Intel bottle and its dependency tree builds from source |
| `yt-dlp` | Feature-rich audio/video downloader, upstream universal macOS binary (zero dependencies); core has no Intel bottle and pulls a Python stack |
| `libplist` / `libimobiledevice-glue` / `libtatsu` / `libusbmuxd` / `libimobiledevice` | iOS device communication stack, compiled from source on Intel (core has no Intel bottles); dependencies use this tap's bottled `fork-libtasn1` and `fork-openssl@4` |
| `wabt` | WebAssembly Binary Toolkit (`wat2wasm`/`wasm2wat` and friends), compiled from source on Intel (upstream's macOS asset is arm64-only and core has no Intel Tahoe bottle); cmake build dependency taken from this tap |
| `x86_64-unknown-linux-gnu` | GCC cross toolchain for x86_64 Linux (Intel host prebuilt, thin x86_64); runtime deps use this tap's bottled `fork-bdw-gc`, `fork-python@3.14`, `fork-zstd`, and `guile`; version tracked via GitHub releases with `.sha256` sidecar |
| `mirage-wallpaper` | Mirage native live wallpaper engine, compatible with Wallpaper Engine (Intel-only cask, thin x86_64, notarized); upstream per-arch builds mirrored to this repo's releases, version tracked via custom checker |
| `llvm` | Next-gen compiler infrastructure, upstream 19.1.7 Intel macOS prebuilt pinned (later versions are ARM64-only; building 23.x from source exceeds the 6h CI limit); thin x86_64, zero dependencies, keg-only like core; point bindgen at it via `LIBCLANG_PATH` |
| `z3` | Theorem prover, official macOS x64 prebuilt (`z3-<ver>-x64-osx-13.3.zip`, zero dependencies); same-name conflict with core |
| `toshllm` | ToshLLM local LLM runner with Metal acceleration for Intel AMD GPUs (Intel-only cask, thin x86_64, notarized, self-updating); upstream dmg mirrored to this repo's releases, version tracked from upstream releases |
| `lceda-pro` | LCEDA Pro electronic design automation software (Intel x64 only, thin x86_64, notarized); cask mirrored to this repo's releases (zip wraps a dmg, unpacked automatically), version tracked from the official download page's Intel(x64) row |
| `lceda` | LCEDA Standard electronic design automation software (Intel x64 only, thin x86_64, notarized); cask mirrored to this repo's releases, version tracked from the official download page's Intel(x64) row |
| `chisel` | Fast TCP/UDP tunnel over HTTP(S), official Intel bare binary (`chisel_<ver>_darwin_amd64.gz`, zero dependencies); version tracked from GitHub releases; shares its name with core's unrelated LLDB command set — uninstall one before installing the other |
| `exiftool` | Read/write/edit image metadata, pure Perl with zero compilation; official `Image-ExifTool-<ver>.tar.gz` bottled for Intel Tahoe, version tracked from homebrew/core; core's optional Brotli/LZMA Perl modules are omitted; shares its name with core's formula — uninstall one before installing the other |
| `python@3.15` | Python 3.15 interpreter, compiled once on Intel (core has no Intel Tahoe bottle); shares its name with core's formula — uninstall core's first; this tap's meson depends on it so meson updates no longer rebuild Python from source |
| `meson` | Fast build system, shares its name with core's formula — uninstall core's first; depends on this tap's `ninja` and `python@3.15`, bottled for Intel Tahoe so it no longer pulls core's source-built Python |
| `lody` | Lody desktop app for sharing coding agent sessions across desktop and mobile; cask mirrored from the official Intel dmg (`Lody-<ver>-x64.dmg`), version tracked from the core cask |
| `qoder` | Qoder CN (China edition) agentic coding platform by Alibaba; cask mirrored from the official Intel dmg (`Qoder-CN-mac-x64.dmg`), version tracked from the qoder.cn changelog; shares its token with core's international `qoder` cask — uninstall one before installing the other |
| `fork-*` (39) | Dependency layer: runtime deps with no Intel Tahoe bottle in core are either taken over under the same name or renamed to `fork-*` when core still has dependents. All 39 (e.g. `fork-glib`, `fork-gnutls`, `fork-openssl@3`/`@4`, `fork-python@3.14`, `fork-xz`, `fork-zstd`, `fork-dynet`, `fork-eigen@3`) are `keg_only`, built from source, and referenced by full name `bemly/tahoe/fork-*` (list in AGENTS.md 6.3) |
| `openjdk` / `openjdk@26` | OpenJDK 26 GA official macOS x64 prebuilt (`keg_only`); shares its name with core's formula — uninstall core's first |
| `openjdk@17` / `openjdk@21` | Eclipse Temurin x64 JDKs (versioned via the Adoptium API, `keg_only`); same-name conflict with core |
| `git` | Git itself, built from core sources on Intel (depends on fork-pcre2/gettext/openssl@4); same-name conflict with core |
| `bash` | GNU Bash 5.3, built from core sources on Intel (fork-ncurses/readline); same-name conflict with core |
| `wget` / `aria2` | Download tools, built from core sources on Intel (fork-libidn2/libpsl/openssl@4 and friends); same-name conflict with core |
| `automake` / `abseil` / `svt-av1` / `python@3.11` | Build/runtime dependencies built from core sources on Intel (automake, abseil, SVT-AV1, Python 3.11); same-name conflict with core |
| `guile` / `jemalloc` / `libev` / `libnghttp2` / `libssh` / `libyaml` / `simdjson` / `snappy` | Same-name dependency takeovers (keep the core name, uninstall core's build first), built from source and bottled; `libnghttp2` is also the curl3/nghttp2 dependency |
| `fzf` | Command-line fuzzy finder, upstream `fzf-<ver>-darwin_amd64.tar.gz` single binary; version tracked from GitHub releases |
| `zig` | Zig toolchain, official `zig-x86_64-macos-<ver>.tar.xz` (Intel host); same-name conflict with core |
| `swift` | Official Swift 6.4.2 macOS pkg repackaged, exposing only `swift`/`swiftc` (no collisions with other toolchains); version tracked from swift.org |
| `llvm-mingw` | LLVM/Clang-based mingw-w64 cross toolchain (Intel host → Windows), version tracked from GitHub releases |
| `aarch64-unknown-linux-gnu` | GCC cross toolchain targeting aarch64 Linux (Intel host prebuilt); companion to `x86_64-unknown-linux-gnu` |
| `qwen-ime` | Qwen input method, cask taking the Mac dmg from the upstream download API and mirroring it to this repo's releases |
| `antigravity-cli` | Google Antigravity CLI (installed as `agy`), repackaged from the official Intel macOS flat binary; version tracked from the official auto-updater manifest |
| `dotnet` | .NET SDK 11, repackaged from the official macOS x64 tarball (whole tree into the prefix plus a `dotnet` shim); version tracked from Microsoft's release-metadata API; same-name conflict with core |
| `node@20` | Node.js 20 LTS, taken directly from the official `node-v20.x-darwin-x64.tar.gz`; same-name conflict with core |
| `postgresql@13` | PostgreSQL 13, repackaged from EDB's official macOS x64 binaries (only bin/include/lib/share — pgAdmin and the other apps are skipped); `keg_only` because the bundled openssl/icu would clash with core, so add `/usr/local/opt/postgresql@13/bin` to PATH to use its commands; same-name conflict with core |
| `freeling` | Suite of language analyzers (tokenizing, POS tagging, named entities and friends), taken over under the same name and built from core sources; the bundled dynet/eigen copies are unbundled in favour of this tap's `fork-dynet`/`fork-eigen@3`/`boost@1.85`/`icu4c@78`; same-name conflict with core |
| `icu4c@78` | ICU 78 Unicode / globalization libraries, taken over under the same name and built from source (`keg_only`); dependency of `freeling` |
| `boost@1.85` | Boost C++ libraries 1.85, from the third-party prebuilt-boost macOS x86 `static+shared` package (prebuilt dylibs get an `@rpath` added and are re-signed ad-hoc); dependency of `freeling`; same-name conflict with core |
| `wimlib` | Library plus the `wimlib-imagex` tools to create, extract and modify Windows Imaging (WIM) files, built from core sources on Intel (autotools, built with `fork-pkgconf`); no runtime dependencies on macOS |
| `antigravity` | Google Antigravity agent IDE, **shipped as a patched artifact**: the official Intel dmg is unpacked, `app.asar` is rewritten statically (Chinese localization + an extra model-name dictionary (Gemini→哈基米, element codenames→periodic-table characters, Claude→克劳德…) + an in-page Gemini companion widget showing quota and reset time, with your own images importable as the character; in-app auto-update disabled so the patch cannot be overwritten) and the app is re-signed ad-hoc, then the dmg is mirrored to this repo's releases. Built reproducibly by `Widgets/antigravity-niang/build.sh`; version tracked from the core cask plus this release's `.sha256` sidecar. the cask clears brew's quarantine flag after install so it opens without a Gatekeeper prompt (ad-hoc re-sign, no notarization); shares its token with core's unpatched `antigravity` cask — uninstall one before installing the other |

## Switching sources (same-name conflict)

Homebrew forbids installing formulae or casks with the same name/token from two
different taps at the same time — they share the same `Cellar/<name>` or `Caskroom/<token>`
directory.

Except for renamed `keg_only` `fork-*` packages (39) and tap-exclusive packages (`curl3`,
`ffplay`, `ffprobe`, `ffserver`, `antigravity-cli`, `aarch64-unknown-linux-gnu`,
`x86_64-unknown-linux-gnu`, `llvm-mingw`, `cmd`, `deepseek-harness`, `mufetch`, `sst`,
`torpedo`, and tap-only casks), **any package sharing a name with `homebrew/core` requires
uninstalling the other tap's build first** (`brew uninstall <name>` / `brew uninstall --cask <token>`):

```bash
# Switch linked kegs if both are already present in Cellar:
brew unlink gh && brew link --overwrite bemly/tahoe/gh
brew unlink fastfetch && brew link --overwrite bemly/tahoe/fastfetch

# Revert to core:
brew unlink bemly/tahoe/gh && brew link gh
brew unlink bemly/tahoe/fastfetch && brew link fastfetch
```

`python@3.15` / `meson` are version-paired and must be switched by uninstalling:

```bash
brew uninstall meson
brew uninstall --ignore-dependencies python@3.15
brew install bemly/tahoe/meson
```

Other same-name formulae (`node`, `node@20`/`22`/`24`, `go`, `cmake`, `git`, `bash`,
`wget`, `aria2`, `automake`, `abseil`, `svt-av1`, `python@3.11`, `openjdk*`, `guile`,
`jemalloc`, `libev`, `libnghttp2`, `libssh`, `libyaml`, `simdjson`, `snappy`, `zig`,
`swift`, `fzf`, `protobuf`, `z3`, `wimlib`, `ripgrep`, `dotnet`, `freeling`, `boost@1.85`,
`icu4c@78`, `postgresql@13`, `chisel`, `exiftool`, `opencode`, etc.) and same-token casks
(`zcode`, `lody`, `qoder`, `github-copilot-app`, `wireshark`, `checkra1n`, `palera1n`,
`antigravity`; `blender-5x` also shares `/Applications/Blender.app` with core's `blender`)
must likewise be uninstalled before switching taps.
The `fork-*` packages are renamed and do not conflict with core.

The `antigravity` cask is a special case: core has a cask of the same token for the same
app, but core's is the unpatched official build while this tap's is the localized/patched
artifact. They share `Caskroom/antigravity` and cannot coexist either — run
`brew uninstall --cask --force antigravity` before installing this tap's build.

## GHCR bottles

Packages are distributed from **GHCR**: `ghcr.io/v2/bemly/tahoe`
(Homebrew strips the `homebrew-` prefix from the repository name, mirroring the
structure of `ghcr.io/v2/homebrew/core`).

Bottles are built directly from the upstream prebuilt packages where available.
Source-only packages (e.g. `qemu`, `python@3.15`, `meson`) are compiled once on the
same Intel runner — users still install bottles and never compile locally.
The bottle tag is determined by the build machine's architecture and OS; to produce
`x86_64_tahoe` the bottling job runs on a `macos-26-intel` runner.

**A GHCR bottle contains only the formula itself, not its dependencies.** If a
formula needs dependencies, those dependencies must be bottled in this tap too and
referenced by full name (`bemly/tahoe/<name>`), never left to `homebrew/core`: core
ships no Intel Tahoe bottles, so a bare dependency falls back to a local source build
(this is why upgrading `graphviz` once triggered `libpng`/`librsvg`/`rust` builds).
`bottle.yml` now recursively expands every formula's **runtime** dependency closure
before building (build dependencies only compile on CI and don't affect users): tap
dependencies without a bottle (and not being built in the same run) fail the job,
and core dependencies without a `tahoe`/`x86_64_tahoe`/`all` bottle are listed and
fail too. For legacy hub dependencies you can explicitly check `allow_unbottled_core`
when triggering the workflow, but that reintroduces local source compilation and
should only be a temporary escape hatch. `graphviz` avoids the problem by shipping
a zero-runtime-dependency build (third-party renderer plugins disabled; Quartz and
built-in plugins still provide PDF/PNG/SVG).

| Scenario | Action |
| --- | --- |
| New version | `watch-updates` rewrites the formula and auto-triggers `bottle.yml` (manual triggering also works) |
| No bottle in GHCR yet (newly added package) | Manually trigger `bottle.yml` to build and push |
| No update | Keep downloading from GHCR |
| Upstream asset unavailable | `watch-updates.yml` opens an issue alert |

In the short window after an upgrade lands but before the new bottle is on GHCR,
brew falls back to the upstream `url` directly.

> GHCR packages are private by default; anonymous `brew install` returns 401.
> If you hit this, change the package to public in
> Repository Settings → Packages.

## Trigger a CI bottle build (e.g. fastfetch)

After adding or updating a formula, push the bottle to GHCR so installs don't fall
back to the upstream direct link:

1. Open **Actions → Build bottle and publish to GHCR** in the GitHub repository.
2. Click **Run workflow**.
3. Enter the formula name (single, comma-separated like `gh,fastfetch`, or `all`) and run it.

The workflow will: trust the tap → install with `--build-bottle` → run `brew bottle`
→ overwrite the existing GHCR tag → `brew pr-upload` pushes to GHCR and writes the
`bottle do` block back into the formula → commit and push.

## Maintenance

Four workflows, **all manually triggered via `workflow_dispatch` only** (no scheduled jobs):

| Workflow | Purpose | Runner |
| --- | --- | --- |
| `watch-updates` | Batch-scans all `Formula/*.rb` and `Casks/*.rb` via `updater/*.swift` across 5 upstream streams (brew formula/cask, GitHub releases, raw taps, custom feeds); mirrors updated casks to GitHub Releases, rewrites formulas, commits to `main`, and triggers one `bottle` run | `ubuntu-latest` |
| `bottle` | Recursively verifies runtime dependency bottle coverage, builds bottles in topological order, pushes to GHCR, and writes `bottle do` blocks back | `macos-26-intel` |
| `patched` | Builds the patched `antigravity` cask artifact (`build.sh --upload`), fills the `.sha256` sidecar into the cask, runs `brew style` / `brew audit --strict`, and commits to `main` | `macos-26-intel` |
| `sysroots` | Builds cross-compilation sysroots (`openssl-macos-arm64`, `linux-sysroot-x64/a64`) and publishes them to GitHub Releases | `macos-26` / `ubuntu-22.04` |

Developer conventions: see [AGENTS.md](AGENTS.md).

[![](https://img.shields.io/badge/powered_by-dsh-4D6BFE?style=flat-square&logo=deepseek&logoColor=white)](https://github.com/deepseek-ai/deepseek-harness)
