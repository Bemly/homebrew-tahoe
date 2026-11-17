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
