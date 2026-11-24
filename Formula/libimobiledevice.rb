class Libimobiledevice < Formula
  desc "Library to communicate with iOS devices natively"
  homepage "https://www.libimobiledevice.org/"
  # 代编译模式：上游只发源码，CI 现编出瓶；主软件，依赖方是 ideviceinstaller/
  # ifuse 等叶子。依赖全部自瓶化：glue/plist/tatsu/usbmuxd 走本 tap 全名，
  # libtasn1 与 openssl@4 走本源 fork-* 自瓶，避免回落到 core 源码编译。
  # revision 行与 core 同步：上游发新版时若 core 掉 revision，此行手工删。
  url "https://github.com/libimobiledevice/libimobiledevice/releases/download/1.4.0/libimobiledevice-1.4.0.tar.bz2"
  sha256 "23cc0077e221c7d991bd0eb02150a0d49199bcca1ddf059edccee9ffd914939d"
  license "LGPL-2.1-or-later"
  revision 2
  compatibility_version 1
  head "https://github.com/libimobiledevice/libimobiledevice.git", branch: "master"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "3090259ef48af0c65640be24c7b410dc13d6005703366bca5ecf4c4622119df6"
    sha256 cellar: :any, tahoe: "ef129d85c06dcc0b9c095ae57f045f90011818987495f2e8f92112548526071b"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on "autoconf" => :build
  depends_on "bemly/tahoe/automake" => :build
  depends_on "libtool" => :build
  depends_on "bemly/tahoe/fork-pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libimobiledevice-glue"
  depends_on "bemly/tahoe/libplist"
  depends_on "bemly/tahoe/libtatsu"
  depends_on "bemly/tahoe/libusbmuxd"
  depends_on "bemly/tahoe/libtasn1"
  depends_on macos: :tahoe
  depends_on "bemly/tahoe/fork-openssl@4"

  on_linux do
    depends_on "bemly/tahoe/fork-readline"
  end

  deny_network_access!

  def install
    # As long as libplist builds without Cython bindings,
    # so should libimobiledevice as well.
    args = %w[
      --disable-silent-rules
      --without-cython
      --enable-debug
    ]

    configure = build.head? ? "./autogen.sh" : "./configure"
    system configure, *args, *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"idevicedate", "--help"
  end
end
