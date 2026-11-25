class LibgpgError < Formula
  desc "Common error values for all GnuPG components"
  homepage "https://www.gnupg.org/related_software/libgpg-error/"
  url "https://gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-1.61.tar.bz2"
  sha256 "7a85413f2bc354f4f8aa832b718af122e48965e9e0eb9012ee659c13c6385c93"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  livecheck do
    url "https://gnupg.org/ftp/gcrypt/libgpg-error/"
    regex(/href=.*?libgpg-error[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "d5e7b659f1978867d4a28af606db16690442e8117b92f0857817d75cbdb249ab"
    sha256 tahoe: "3e6bf6b81274691f5ba707d51cb33b44117630dfc321073bd2ceb9fdfedc45d7"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  on_macos do
    depends_on "bemly/tahoe/gettext"
  end

  deny_network_access!

  def install
    # NOTE: gpg-error-config is deprecated upstream, so we should remove this at some point.
    # https://dev.gnupg.org/T5683
    system "./configure", *std_configure_args,
                          "--disable-silent-rules",
                          "--enable-install-gpg-error-config",
                          "--enable-static"
    system "make", "install"

    # avoid triggering mandatory rebuilds of software that hard-codes this path
    inreplace [bin/"gpg-error-config", lib/"pkgconfig/gpg-error.pc"], prefix, opt_prefix
  end

  test do
    system bin/"gpgrt-config", "--libs"
  end
end
