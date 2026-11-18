class Wget < Formula
  desc "Internet file retriever"
  homepage "https://www.gnu.org/software/wget/"
  license "GPL-3.0-or-later"
  revision 2
  compatibility_version 1

  stable do
    url "https://ftpmirror.gnu.org/wget/wget-1.25.0.tar.gz"
    mirror "https://ftp.gnu.org/gnu/wget/wget-1.25.0.tar.gz"
    sha256 "766e48423e79359ea31e41db9e5c289675947a7fcf2efdcedb726ac9d0da3784"

    # Backport support for OpenSSL 4
    patch do
      url "https://gitlab.com/gnuwget/wget/-/commit/aaec8d52a06c46eeab570b8ef3e10760ebc66b7a.diff"
      sha256 "96aa2923ce9a12dbc2c82969705da4f72792816b087dbee19c04cd2cb2769ea8"
      type :backport
    end
  end

  head do
    url "https://git.savannah.gnu.org/git/wget.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "bemly/tahoe/fork-xz" => :build
  end

  depends_on "bemly/tahoe/fork-pkgconf" => :build

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/fork-libidn2"
  depends_on "bemly/tahoe/fork-libpsl"
  depends_on "bemly/tahoe/fork-openssl@4"
  depends_on macos: :tahoe

  on_macos do
    depends_on "bemly/tahoe/fork-gettext"
    depends_on "bemly/tahoe/fork-libunistring"
  end

  on_linux do
    depends_on "util-linux"
    depends_on "zlib-ng-compat"
  end

  # Test downloads from the network
  allow_network_access! :test

  def install
    system "./bootstrap", "--skip-po" if build.head?
    system "./configure", "--sysconfdir=#{etc}",
                          "--with-ssl=openssl",
                          "--with-libssl-prefix=#{formula_opt_prefix("bemly/tahoe/fork-openssl@4")}",
                          "--disable-pcre",
                          "--disable-pcre2",
                          "--with-libpsl",
                          "--without-included-regex",
                          *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"wget", "-O", File::NULL, "https://google.com"

    # Verify PSL support is built in via libpsl
    assert_match "+psl", shell_output("#{bin}/wget --version")
  end
end
