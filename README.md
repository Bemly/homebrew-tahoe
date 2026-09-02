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

brew install bemly/tahoe-intel/gh
brew install bemly/tahoe-intel/fastfetch
```

## Packages

| Package | Notes |
| --- | --- |
| `gh` | GitHub CLI, taken directly from `gh_<ver>_macOS_amd64.zip` |
| `fastfetch` | Neofetch-like system info tool, taken from `fastfetch-macos-amd64.tar.gz` (release tag has no `v` prefix) |

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
| New version / no bottle in GHCR yet | Manually trigger `bottle.yml`: build the bottle and overwrite the old one in GHCR |
| No update | Keep downloading from GHCR |
| Upstream asset unavailable | `watch-updates.yml` opens an issue alert |

Right after an upgrade, before the bottle is rebuilt, brew falls back to the upstream
`url` directly, and a reminder issue to rebuild the bottle is opened in the repo.

> GHCR packages are private by default; anonymous `brew install` returns 401.
> If you hit this, change the package to public in
> Repository Settings → Packages.

## Building a bottle locally (e.g. fastfetch)

After adding or updating a formula, push the bottle to GHCR so installs don't fall
back to the upstream direct link:

1. Open **Actions → Build bottle and publish to GHCR** in the GitHub repository.
2. Click **Run workflow**.
3. Pick the formula (`gh` or `fastfetch`) and run it.

The workflow will: trust the tap → install with `--build-bottle` → run `brew bottle`
→ overwrite the existing GHCR tag → `brew pr-upload` pushes to GHCR and writes the
`bottle do` block back into the formula → commit and push.

## Maintenance

Two workflows, **both manually triggered only** (no scheduled jobs):

| Workflow | Purpose | Runner |
| --- | --- | --- |
| `watch-updates` | Compares the version in **homebrew/core** with the local formula; if newer, rewrites the formula and opens a PR / issues | `ubuntu-latest` |
| `bottle` | Builds the bottle, pushes to GHCR, writes the bottle block back | `macos-26-intel` |

Developer conventions: see [AGENTS.md](AGENTS.md).
