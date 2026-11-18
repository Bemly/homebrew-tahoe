# 待办：缺 Intel Tahoe 瓶的 core 依赖

本清单由 2026-11-17 手动扫描生成：对全部 `Formula/*.rb` 展开**运行时**依赖闭包，
经 formulae.brew.sh API 查 `bottle.stable.files` 中是否有 `tahoe`/`x86_64_tahoe`/`all`。
`graphviz` 已单独处理（改为零运行时依赖），不在表内。

> 同名跨 tap 是 Homebrew 硬限制：不能把这些 core 公式同名搬进本仓。
> 后续要么改名 fork（改所有依赖方引用），要么接受 `allow_unbottled_core` 豁免。

共 18 个公式、91 条 pair、39 个不同的 core 依赖。

| 公式 | 缺失的 core 依赖（无 Intel Tahoe 瓶） |
| --- | --- |
| `aarch64-unknown-linux-gnu` | `bdw-gc`, `gmp`, `guile`, `libunistring`, `lz4`, `mpdecimal`, `openssl@4`, `pkgconf`, `python@3.14`, `readline`, `sqlite`, `xz` |
| `capstone` | `gettext`, `json-c`, `libunistring` |
| `curl3` | `brotli`, `libnghttp2`, `libpsl`, `libssh2`, `lz4`, `openssl@3`, `openssl@4`, `xz` |
| `dtc` | `libyaml` |
| `libimobiledevice` | `libtasn1`, `openssl@4` |
| `libngtcp2` | `openssl@3` |
| `libslirp` | `gettext`, `glib`, `json-c`, `libunistring`, `pcre2` |
| `make` | `gettext` |
| `meson` | `lz4`, `mpdecimal`, `openssl@4`, `readline`, `sqlite`, `xz` |
| `nghttp2` | `c-ares`, `jemalloc`, `libev`, `libnghttp2`, `openssl@3` |
| `opencode` | `pcre2` |
| `protobuf` | `abseil` |
| `python@3.15` | `gettext`, `lz4`, `mpdecimal`, `openssl@4`, `readline`, `sqlite`, `xz` |
| `qemu` | `gettext`, `glib`, `gmp`, `gnutls`, `jpeg-turbo`, `json-c`, `libidn2`, `libpng`, `libssh`, `libtasn1`, `libunistring`, `libusb`, `libyaml`, `lz4`, `lzo`, `ncurses`, `nettle`, `openssl@4`, `p11-kit`, `pcre2`, `pixman`, `snappy`, `xz` |
| `ripgrep` | `pcre2` |
| `socat` | `openssl@3` |
| `wabt` | `openssl@4` |
| `x86_64-unknown-linux-gnu` | `bdw-gc`, `gmp`, `guile`, `libunistring`, `lz4`, `mpdecimal`, `openssl@4`, `pkgconf`, `python@3.14`, `readline`, `sqlite`, `xz` |

## 本机反向依赖树与同名可行性（2026-11-17 实测）

判定规则：如果该 core 包的本机依赖方**全部是本 tap 公式**（没有任何 core 依赖方），
可考虑同名接管（仍需用户先卸 core 版）；只要存在 core 依赖方，就必须改名加后缀，
否则本 tap 同名包会与 core 版无条件 odie，卸 core 版又会带崩它的 core 依赖方。

共 39 个依赖：
- 可同名：8 个（`abseil`, `guile`, `jemalloc`, `libev`, `libnghttp2`, `libssh`, `libyaml`, `snappy`）
- 需加后缀：31 个

### `abseil` — 可同名

- 直系 1 个：本 tap 1 个（`bemly/tahoe/protobuf`），core 0 个
- 本机无 core 依赖方 → 可同名接管；仍需注意用户机器上已装 core 版时需先卸载。

### `bdw-gc` — 需加后缀

- 直系 3 个：本 tap 2 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 1 个（`guile`）
- 存在 core 依赖方（`guile`）→ 必须改名加后缀。

### `brotli` — 需加后缀

- 直系 2 个：本 tap 1 个（`bemly/tahoe/curl3`），core 1 个（`dotnet`）
- 存在 core 依赖方（`dotnet`）→ 必须改名加后缀。

### `c-ares` — 需加后缀

- 直系 2 个：本 tap 1 个（`bemly/tahoe/nghttp2`），core 1 个（`aria2`）
- 存在 core 依赖方（`aria2`）→ 必须改名加后缀。

### `gettext` — 需加后缀

- 直系 30 个：本 tap 5 个（`bemly/tahoe/capstone`, `bemly/tahoe/libslirp`, `bemly/tahoe/make`, `bemly/tahoe/python@3.15`, `bemly/tahoe/qemu`），core 25 个（`aria2`, `bash`, `cairo`, `fluid-synth`, `fontconfig`, `git`, `glib`, `gnupg`, `gnutls`, `harfbuzz`, `jadx`, `libassuan`, `libgcrypt`, `libgpg-error`, `libidn2`, `libksba`, `openjdk`, `openjdk@17`, `openjdk@21`, `pango`, `pinentry`, `python@3.14`, `tesseract`, `tesseract-lang`, `wget`）
- 第 2 层 7 个：`bemly/tahoe/aarch64-unknown-linux-gnu`, `mercurial`, `bemly/tahoe/meson`, `python-gdbm@3.14`, `python-tk@3.14`, `swift`, `bemly/tahoe/x86_64-unknown-linux-gnu`
- 存在 core 依赖方（`aria2`, `bash`, `cairo`, `fluid-synth`, `fontconfig`, `git`, `glib`, `gnupg` 等）→ 必须改名加后缀。

### `glib` — 需加后缀

- 直系 11 个：本 tap 2 个（`bemly/tahoe/libslirp`, `bemly/tahoe/qemu`），core 9 个（`cairo`, `harfbuzz`, `jadx`, `openjdk`, `openjdk@17`, `openjdk@21`, `pango`, `tesseract`, `tesseract-lang`）
- 存在 core 依赖方（`cairo`, `harfbuzz`, `jadx`, `openjdk`, `openjdk@17`, `openjdk@21`, `pango`, `tesseract` 等）→ 必须改名加后缀。

### `gmp` — 需加后缀

- 直系 8 个：本 tap 3 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/qemu`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 5 个（`gnupg`, `gnutls`, `guile`, `nettle`, `shellcheck`）
- 存在 core 依赖方（`gnupg`, `gnutls`, `guile`, `nettle`, `shellcheck`）→ 必须改名加后缀。

### `gnutls` — 需加后缀

- 直系 2 个：本 tap 1 个（`bemly/tahoe/qemu`），core 1 个（`gnupg`）
- 存在 core 依赖方（`gnupg`）→ 必须改名加后缀。

### `guile` — 可同名

- 直系 2 个：本 tap 2 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 0 个
- 本机无 core 依赖方 → 可同名接管；仍需注意用户机器上已装 core 版时需先卸载。

### `jemalloc` — 可同名

- 直系 1 个：本 tap 1 个（`bemly/tahoe/nghttp2`），core 0 个
- 本机无 core 依赖方 → 可同名接管；仍需注意用户机器上已装 core 版时需先卸载。

### `jpeg-turbo` — 需加后缀

- 直系 12 个：本 tap 1 个（`bemly/tahoe/qemu`），core 11 个（`jadx`, `leptonica`, `libtiff`, `little-cms2`, `openjdk`, `openjdk@17`, `openjdk@21`, `openjpeg`, `tesseract`, `tesseract-lang`, `webp`）
- 存在 core 依赖方（`jadx`, `leptonica`, `libtiff`, `little-cms2`, `openjdk`, `openjdk@17`, `openjdk@21`, `openjpeg` 等）→ 必须改名加后缀。

### `json-c` — 需加后缀

- 直系 28 个：本 tap 3 个（`bemly/tahoe/capstone`, `bemly/tahoe/libslirp`, `bemly/tahoe/qemu`），core 25 个（`aria2`, `bash`, `cairo`, `fluid-synth`, `fontconfig`, `gettext`, `git`, `glib`, `gnupg`, `gnutls`, `harfbuzz`, `jadx`, `libassuan`, `libgcrypt`, `libgpg-error`, `libidn2`, `libksba`, `openjdk`, `openjdk@17`, `openjdk@21`, `pango`, `pinentry`, `tesseract`, `tesseract-lang`, `wget`）
- 第 2 层 3 个：`bemly/tahoe/make`, `python@3.14`, `bemly/tahoe/python@3.15`
- 第 3 层 7 个：`bemly/tahoe/aarch64-unknown-linux-gnu`, `mercurial`, `bemly/tahoe/meson`, `python-gdbm@3.14`, `python-tk@3.14`, `swift`, `bemly/tahoe/x86_64-unknown-linux-gnu`
- 存在 core 依赖方（`aria2`, `bash`, `cairo`, `fluid-synth`, `fontconfig`, `gettext`, `git`, `glib` 等）→ 必须改名加后缀。

### `libev` — 可同名

- 直系 1 个：本 tap 1 个（`bemly/tahoe/nghttp2`），core 0 个
- 本机无 core 依赖方 → 可同名接管；仍需注意用户机器上已装 core 版时需先卸载。

### `libidn2` — 需加后缀

- 直系 4 个：本 tap 1 个（`bemly/tahoe/qemu`），core 3 个（`gnupg`, `gnutls`, `wget`）
- 存在 core 依赖方（`gnupg`, `gnutls`, `wget`）→ 必须改名加后缀。

### `libnghttp2` — 可同名

- 直系 2 个：本 tap 2 个（`bemly/tahoe/curl3`, `bemly/tahoe/nghttp2`），core 0 个
- 本机无 core 依赖方 → 可同名接管；仍需注意用户机器上已装 core 版时需先卸载。

### `libpng` — 需加后缀

- 直系 17 个：本 tap 1 个（`bemly/tahoe/qemu`），core 16 个（`cairo`, `fontconfig`, `freetype`, `harfbuzz`, `jadx`, `leptonica`, `libtiff`, `little-cms2`, `openjdk`, `openjdk@17`, `openjdk@21`, `openjpeg`, `pango`, `tesseract`, `tesseract-lang`, `webp`）
- 存在 core 依赖方（`cairo`, `fontconfig`, `freetype`, `harfbuzz`, `jadx`, `leptonica`, `libtiff`, `little-cms2` 等）→ 必须改名加后缀。

### `libpsl` — 需加后缀

- 直系 2 个：本 tap 1 个（`bemly/tahoe/curl3`），core 1 个（`wget`）
- 存在 core 依赖方（`wget`）→ 必须改名加后缀。

### `libssh` — 可同名

- 直系 1 个：本 tap 1 个（`bemly/tahoe/qemu`），core 0 个
- 本机无 core 依赖方 → 可同名接管；仍需注意用户机器上已装 core 版时需先卸载。

### `libssh2` — 需加后缀

- 直系 2 个：本 tap 1 个（`bemly/tahoe/curl3`），core 1 个（`aria2`）
- 存在 core 依赖方（`aria2`）→ 必须改名加后缀。

### `libtasn1` — 需加后缀

- 直系 6 个：本 tap 2 个（`bemly/tahoe/libimobiledevice`, `bemly/tahoe/qemu`），core 4 个（`gnupg`, `gnutls`, `ideviceinstaller`, `p11-kit`）
- 存在 core 依赖方（`gnupg`, `gnutls`, `ideviceinstaller`, `p11-kit`）→ 必须改名加后缀。

### `libunistring` — 需加后缀

- 直系 31 个：本 tap 5 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/capstone`, `bemly/tahoe/libslirp`, `bemly/tahoe/qemu`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 26 个（`aria2`, `bash`, `cairo`, `fluid-synth`, `fontconfig`, `gettext`, `git`, `glib`, `gnupg`, `gnutls`, `guile`, `harfbuzz`, `jadx`, `libassuan`, `libgcrypt`, `libgpg-error`, `libidn2`, `libksba`, `openjdk`, `openjdk@17`, `openjdk@21`, `pango`, `pinentry`, `tesseract`, `tesseract-lang`, `wget`）
- 第 2 层 3 个：`bemly/tahoe/make`, `python@3.14`, `bemly/tahoe/python@3.15`
- 第 3 层 5 个：`mercurial`, `bemly/tahoe/meson`, `python-gdbm@3.14`, `python-tk@3.14`, `swift`
- 存在 core 依赖方（`aria2`, `bash`, `cairo`, `fluid-synth`, `fontconfig`, `gettext`, `git`, `glib` 等）→ 必须改名加后缀。

### `libusb` — 需加后缀

- 直系 2 个：本 tap 1 个（`bemly/tahoe/qemu`），core 1 个（`gnupg`）
- 存在 core 依赖方（`gnupg`）→ 必须改名加后缀。

### `libyaml` — 可同名

- 直系 2 个：本 tap 2 个（`bemly/tahoe/dtc`, `bemly/tahoe/qemu`），core 0 个
- 本机无 core 依赖方 → 可同名接管；仍需注意用户机器上已装 core 版时需先卸载。

### `lz4` — 需加后缀

- 直系 25 个：本 tap 6 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/curl3`, `bemly/tahoe/meson`, `bemly/tahoe/python@3.15`, `bemly/tahoe/qemu`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 19 个（`ideviceinstaller`, `jadx`, `leptonica`, `libarchive`, `libtiff`, `libzip`, `little-cms2`, `mercurial`, `openjdk`, `openjdk@17`, `openjdk@21`, `openjpeg`, `python-gdbm@3.14`, `python-tk@3.14`, `python@3.14`, `swift`, `tesseract`, `tesseract-lang`, `zstd`）
- 存在 core 依赖方（`ideviceinstaller`, `jadx`, `leptonica`, `libarchive`, `libtiff`, `libzip`, `little-cms2`, `mercurial` 等）→ 必须改名加后缀。

### `lzo` — 需加后缀

- 直系 10 个：本 tap 1 个（`bemly/tahoe/qemu`），core 9 个（`cairo`, `harfbuzz`, `jadx`, `openjdk`, `openjdk@17`, `openjdk@21`, `pango`, `tesseract`, `tesseract-lang`）
- 存在 core 依赖方（`cairo`, `harfbuzz`, `jadx`, `openjdk`, `openjdk@17`, `openjdk@21`, `pango`, `tesseract` 等）→ 必须改名加后缀。

### `mpdecimal` — 需加后缀

- 直系 10 个：本 tap 4 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/meson`, `bemly/tahoe/python@3.15`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 6 个（`mercurial`, `python-gdbm@3.14`, `python-tk@3.14`, `python@3.11`, `python@3.14`, `swift`）
- 存在 core 依赖方（`mercurial`, `python-gdbm@3.14`, `python-tk@3.14`, `python@3.11`, `python@3.14`, `swift`）→ 必须改名加后缀。

### `ncurses` — 需加后缀

- 直系 2 个：本 tap 1 个（`bemly/tahoe/qemu`），core 1 个（`bash`）
- 存在 core 依赖方（`bash`）→ 必须改名加后缀。

### `nettle` — 需加后缀

- 直系 3 个：本 tap 1 个（`bemly/tahoe/qemu`），core 2 个（`gnupg`, `gnutls`）
- 存在 core 依赖方（`gnupg`, `gnutls`）→ 必须改名加后缀。

### `openssl@3` — 需加后缀

- 直系 16 个：本 tap 4 个（`bemly/tahoe/curl3`, `bemly/tahoe/libngtcp2`, `bemly/tahoe/nghttp2`, `bemly/tahoe/socat`），core 12 个（`aria2`, `dotnet`, `dotnet@8`, `ldid`, `libssh`, `mercurial`, `python-gdbm@3.14`, `python-tk@3.14`, `python@3.11`, `swift`, `tcl-tk`, `wget`）
- 第 2 层 1 个：`bemly/tahoe/qemu`
- 存在 core 依赖方（`aria2`, `dotnet`, `dotnet@8`, `ldid`, `libssh`, `mercurial`, `python-gdbm@3.14`, `python-tk@3.14` 等）→ 必须改名加后缀。

### `openssl@4` — 需加后缀

- 直系 12 个：本 tap 8 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/curl3`, `bemly/tahoe/libimobiledevice`, `bemly/tahoe/meson`, `bemly/tahoe/python@3.15`, `bemly/tahoe/qemu`, `bemly/tahoe/wabt`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 4 个（`fossil`, `ideviceinstaller`, `libssh2`, `python@3.14`）
- 第 2 层 5 个：`aria2`, `mercurial`, `python-gdbm@3.14`, `python-tk@3.14`, `swift`
- 存在 core 依赖方（`aria2`, `fossil`, `ideviceinstaller`, `libssh2`, `mercurial`, `python-gdbm@3.14`, `python-tk@3.14`, `python@3.14` 等）→ 必须改名加后缀。

### `p11-kit` — 需加后缀

- 直系 3 个：本 tap 1 个（`bemly/tahoe/qemu`），core 2 个（`gnupg`, `gnutls`）
- 存在 core 依赖方（`gnupg`, `gnutls`）→ 必须改名加后缀。

### `pcre2` — 需加后缀

- 直系 15 个：本 tap 4 个（`bemly/tahoe/libslirp`, `bemly/tahoe/opencode`, `bemly/tahoe/qemu`, `bemly/tahoe/ripgrep`），core 11 个（`cairo`, `git`, `glib`, `harfbuzz`, `jadx`, `openjdk`, `openjdk@17`, `openjdk@21`, `pango`, `tesseract`, `tesseract-lang`）
- 存在 core 依赖方（`cairo`, `git`, `glib`, `harfbuzz`, `jadx`, `openjdk`, `openjdk@17`, `openjdk@21` 等）→ 必须改名加后缀。

### `pixman` — 需加后缀

- 直系 10 个：本 tap 1 个（`bemly/tahoe/qemu`），core 9 个（`cairo`, `harfbuzz`, `jadx`, `openjdk`, `openjdk@17`, `openjdk@21`, `pango`, `tesseract`, `tesseract-lang`）
- 存在 core 依赖方（`cairo`, `harfbuzz`, `jadx`, `openjdk`, `openjdk@17`, `openjdk@21`, `pango`, `tesseract` 等）→ 必须改名加后缀。

### `pkgconf` — 需加后缀

- 直系 3 个：本 tap 2 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 1 个（`guile`）
- 存在 core 依赖方（`guile`）→ 必须改名加后缀。

### `python@3.14` — 需加后缀

- 直系 6 个：本 tap 2 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 4 个（`mercurial`, `python-gdbm@3.14`, `python-tk@3.14`, `swift`）
- 存在 core 依赖方（`mercurial`, `python-gdbm@3.14`, `python-tk@3.14`, `swift`）→ 必须改名加后缀。

### `readline` — 需加后缀

- 直系 16 个：本 tap 4 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/meson`, `bemly/tahoe/python@3.15`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 12 个（`aria2`, `bash`, `fluid-synth`, `gnupg`, `guile`, `mercurial`, `python-gdbm@3.14`, `python-tk@3.14`, `python@3.11`, `python@3.14`, `sqlite`, `swift`）
- 存在 core 依赖方（`aria2`, `bash`, `fluid-synth`, `gnupg`, `guile`, `mercurial`, `python-gdbm@3.14`, `python-tk@3.14` 等）→ 必须改名加后缀。

### `snappy` — 可同名

- 直系 1 个：本 tap 1 个（`bemly/tahoe/qemu`），core 0 个
- 本机无 core 依赖方 → 可同名接管；仍需注意用户机器上已装 core 版时需先卸载。

### `sqlite` — 需加后缀

- 直系 11 个：本 tap 4 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/meson`, `bemly/tahoe/python@3.15`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 7 个（`aria2`, `mercurial`, `python-gdbm@3.14`, `python-tk@3.14`, `python@3.11`, `python@3.14`, `swift`）
- 存在 core 依赖方（`aria2`, `mercurial`, `python-gdbm@3.14`, `python-tk@3.14`, `python@3.11`, `python@3.14`, `swift`）→ 必须改名加后缀。

### `xz` — 需加后缀

- 直系 26 个：本 tap 6 个（`bemly/tahoe/aarch64-unknown-linux-gnu`, `bemly/tahoe/curl3`, `bemly/tahoe/meson`, `bemly/tahoe/python@3.15`, `bemly/tahoe/qemu`, `bemly/tahoe/x86_64-unknown-linux-gnu`），core 20 个（`ideviceinstaller`, `jadx`, `leptonica`, `libarchive`, `libtiff`, `libzip`, `little-cms2`, `mercurial`, `openjdk`, `openjdk@17`, `openjdk@21`, `openjpeg`, `python-gdbm@3.14`, `python-tk@3.14`, `python@3.11`, `python@3.14`, `swift`, `tesseract`, `tesseract-lang`, `zstd`）
- 存在 core 依赖方（`ideviceinstaller`, `jadx`, `leptonica`, `libarchive`, `libtiff`, `libzip`, `little-cms2`, `mercurial` 等）→ 必须改名加后缀。
