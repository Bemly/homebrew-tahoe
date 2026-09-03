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
| `doubao-ime` | Doubao AI input method, cask, auto-installs into `/Library/Input Methods` via the official installer script (needs sudo); not in brew core — version comes from its download API |
| `node` | Node.js runtime, taken directly from the official `node-v<ver>-darwin-x64.tar.gz` |
| `node@24` | Node.js 24 LTS, taken directly from the official `node-v<ver>-darwin-x64.tar.gz` |
| `node@22` | Node.js 22 LTS, taken directly from the official `node-v<ver>-darwin-x64.tar.gz` |
| `opencode` | AI coding agent, Intel-only slice of `anomalyco/homebrew-tap`'s GoReleaser formula (`opencode-darwin-x64.zip`); shares its name with core's npm build — uninstall one before installing the other |
| `sst` | SST framework, Intel-only slice of `anomalyco/homebrew-tap`'s GoReleaser formula (`sst-mac-x86_64.tar.gz`) |
| `torpedo` | sst/torpedo VPC database access tool, Intel-only slice of `anomalyco/homebrew-tap`'s GoReleaser formula (`torpedo-mac-x86_64.tar.gz`) |
| `ripgrep` | Search tool like grep, bottled dependency of `opencode` (from homebrew/core sources) |

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
