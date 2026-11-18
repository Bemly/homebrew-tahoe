class Automake < Formula
  desc "Tool for generating GNU Standards-compliant Makefiles"
  homepage "https://www.gnu.org/software/automake/"
  url "https://ftpmirror.gnu.org/automake/automake-1.20.tar.xz"
  mirror "https://ftp.gnu.org/gnu/automake/automake-1.20.tar.xz"
  sha256 "f6f34dad4cbe395715762b0710f7c511e39bd5cf777e6b95818ccbecf7714248"
  license "GPL-3.0-or-later"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "cae4f1caf3cf59d59f937e83072211aebe4c07cac6125a573e0fe9d9804c15d2"
  end

  depends_on arch: :x86_64
  depends_on "autoconf"
  depends_on macos: :tahoe

  deny_network_access!

  def install
    ENV["PERL"] = "/usr/bin/perl" if OS.mac?

    # We specify `HOMEBREW_PREFIX` so that aclocal is compiled with the
    # correct system value for acdir (`HOMEBREW_PREFIX/share/aclocal`)
    # We also patch `configure` so that the normal installation prefix
    # is used when we call `make install`
    inreplace "configure", "${datadir}", "${datarootdir}"
    system "./configure", "--sysconfdir=#{etc}",
                          "--localstatedir=#{var}",
                          "--datarootdir=#{share}",
                          "--datadir=#{HOMEBREW_PREFIX}/share",
                          *std_configure_args
    system "make", "install"

    # Use dirlist to add common search dirs for aclocal
    (share/"aclocal/dirlist").write <<~EOS
      /usr/share/aclocal
    EOS
  end

  test do
    # Check that the compiled system value for acdir does not use automake's versioned path
    assert_equal "#{HOMEBREW_PREFIX}/share/aclocal", shell_output("#{bin}/aclocal --print-ac-dir").chomp

    (testpath/"test.c").write <<~C
      int main() { return 0; }
    C
    (testpath/"configure.ac").write <<~M4
      AC_INIT(test, 1.0)
      AM_INIT_AUTOMAKE
      AC_PROG_CC
      AC_CONFIG_FILES(Makefile)
      AC_OUTPUT
    M4
    (testpath/"Makefile.am").write <<~MAKE
      bin_PROGRAMS = test
      test_SOURCES = test.c
    MAKE
    system bin/"aclocal"
    system bin/"automake", "--add-missing", "--foreign"
    system "autoconf"
    system "./configure"
    system "make"
    system "./test"
  end
end
