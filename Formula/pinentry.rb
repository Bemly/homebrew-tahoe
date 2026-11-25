class Pinentry < Formula
  desc "Passphrase entry dialog utilizing the Assuan protocol"
  homepage "https://www.gnupg.org/related_software/pinentry/"
  url "https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-1.3.3.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/pinentry/pinentry-1.3.3.tar.bz2"
  sha256 "c2970f16d6afb66ecddfca767d743936c86239bff936eed7fd7597a678414b63"
  license "GPL-2.0-or-later"
  compatibility_version 1

  livecheck do
    url "https://gnupg.org/ftp/gcrypt/pinentry/"
    regex(/href=.*?pinentry[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "685323179f122086c99c8a6402902a68f1877a885af569f987a7f24e8eedd8f0"
    sha256 cellar: :any, tahoe: "1e8c2cc1f0f09a780f5565cd8c6596d2d9399c0d3da8adb7747317e5bec7bf48"
  end

  depends_on "bemly/tahoe/pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libassuan"
  depends_on "bemly/tahoe/libgpg-error"
  depends_on macos: :tahoe

  uses_from_macos "ncurses"

  on_linux do
    depends_on "glib"
    depends_on "libsecret"
  end

  deny_network_access!

  def install
    # Fix compile with newer Clang
    ENV.append_to_cflags "-Wno-implicit-function-declaration" if DevelopmentTools.clang_build_version >= 1403

    args = %w[
      --disable-silent-rules
      --disable-pinentry-fltk
      --disable-pinentry-gnome3
      --disable-pinentry-gtk2
      --disable-pinentry-qt
      --disable-pinentry-qt5
      --disable-pinentry-tqt
      --enable-pinentry-tty
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"pinentry", "--version"
    system bin/"pinentry-tty", "--version"
  end
end
