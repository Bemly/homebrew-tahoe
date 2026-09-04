# bemly/tahoe-intel

A third-party Homebrew tap that provides directly installable software for
**Intel (x86_64) Macs running macOS 26 (Tahoe)**.

## Why

Starting with macOS 26, Homebrew no longer builds `x86_64` bottles. In practice the
number of `x86_64_tahoe` bottles in the `homebrew/core` tap is 0, so software like
`gh` and `node` can only be compiled from source on Intel Macs.

This tap pulls the upstream **official macOS amd64 prebuilt packages** (no recompilation),
packages them as Homebrew bottles, and distributes them through **GHCR**:
`ghcr.io/v2/bemly/tahoe-intel`.

## Requirements

- CPU: **Intel (x86_64)** — do NOT use on Apple Silicon (use `homebrew/core` instead).
- OS: **macOS 26 (Tahoe)** or later.

Each formula enforces this with `depends_on arch: :x86_64` and
`depends_on macos: :tahoe`; installation is rejected outright if the requirements
are not met.

## Installation

```bash
brew tap bemly/tahoe-intel

# If you previously installed the homebrew/core build, uninstall it first:
# formulae with the same name across taps cannot coexist — brew refuses to install.
brew uninstall gh
brew uninstall fastfetch
brew uninstall opencode # core ships an npm-based opencode under the same name

brew install bemly/tahoe-intel/gh
brew install bemly/tahoe-intel/fastfetch
brew install bemly/tahoe-intel/opencode # pulls bemly/tahoe-intel/ripgrep as a dependency

# workbuddy is a desktop app, delivered as a cask (installed into /Applications,
# visible in Launchpad/Spotlight)
brew install --cask bemly/tahoe-intel/workbuddy
# doubao-ime is an input method, delivered as a cask (auto-runs the official
# installer into /Library/Input Methods, requires sudo password)
brew install --cask bemly/tahoe-intel/doubao-ime
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
| `deepseek-harness` | DeepSeek agent harness, npm package `@deepseek-ai/dsh` (exposes the `dsh` command only, `dsh web` serves the browser UI); depends on this tap's node bottle; no update checks |
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
| `curl3` | Independent HTTP/3 client with MASQUE/CONNECT-UDP (`--enable-proxy-http3`, core doesn't enable it); renamed to coexist with core's curl |
| `libnghttp3` | HTTP/3 C library, bottled dependency of `curl3` |
| `libngtcp2` | QUIC implementation, bottled dependency of `curl3` |
| `nghttp2` | H2 clients (`nghttp`/`h2load`/`nghttpx`) with `--enable-app`; H3 flag deferred to Phase 4 |
| `socat` | SOcket CAT relay tool, compiled from source |
| `make` | GNU make (installed as `gmake`), mirrored even though core has a tahoe bottle |
| `graphviz` | Graph visualization software, compiled from source |
| `protobuf` | Full build from source: libprotobuf + `protoc` + test suite |
| `caddy` | Extensible server platform, Intel static build from upstream (`caddy_<ver>_mac_amd64.tar.gz`); H2/H3 baseline service |
| `h2spec` | HTTP/2 conformance tester for Phase 2 H2 tests |
| `hyperfine` | Command-line benchmarking tool for Phase 4 repeated benchmarks |
| `iperf3` | Static build (no `openssl@4` dependency) for Phase 4 bare-metal throughput baselines |
| `ninja` | Small build system, upstream universal binary (Intel slice) |
| `rustup-init` | Official static Rust toolchain installer; coexists with core's source-built `rustup` |
| `wireshark` | Network protocol analyzer, cask from the official Intel dmg (Intel builds stop at 4.4.x); ships `tshark`/`editcap` shims |

## Switching sources (same-name conflict)

Our `gh` / `fastfetch` share their Cellar path with `homebrew/core`'s builds, so they
cannot be linked at the same time. To switch:

```bash
# Use this tap's build
brew unlink gh && brew link --overwrite bemly/tahoe-intel/gh
brew unlink fastfetch && brew link --overwrite bemly/tahoe-intel/fastfetch

# Use the core build
brew unlink bemly/tahoe-intel/gh && brew link gh
brew unlink bemly/tahoe-intel/fastfetch && brew link fastfetch
```

## GHCR bottles

Packages are distributed from **GHCR**: `ghcr.io/v2/bemly/tahoe-intel`
(Homebrew strips the `homebrew-` prefix from the repository name, mirroring the
structure of `ghcr.io/v2/homebrew/core`).

Bottles are built directly from the upstream prebuilt packages — **no recompilation**.
The bottle tag is determined by the build machine's architecture and OS; to produce
`x86_64_tahoe` the bottling job runs on a `macos-26-intel` runner.

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

Two workflows, **both manually triggered only** (no scheduled jobs):

| Workflow | Purpose | Runner |
| --- | --- | --- |
| `watch-updates` | Batch-scans every formula against **homebrew/core** versions (Swift checkers, one file per package in `updater/`); rewrites formulas, commits to `main`, and automatically triggers one bottling run | `ubuntu-latest` |
| `bottle` | Builds the bottle, pushes to GHCR, writes the bottle block back | `macos-26-intel` |

Developer conventions: see [AGENTS.md](AGENTS.md).
