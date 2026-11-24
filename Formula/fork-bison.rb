class ForkBison < Formula
  desc "Parser generator"
  homepage "https://www.gnu.org/software/bison/"
  url "https://ftpmirror.gnu.org/bison/bison-3.8.2.tar.xz"
  mirror "https://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz"
  mirror "http://ftp.gnu.org/gnu/bison/bison-3.8.2.tar.xz"
  sha256 "9bba0214ccf7f1079c5d59210045227bcf619519840ebfa80cd3849cff5a5bf2"
  license "GPL-3.0-or-later"
  version_scheme 1
  compatibility_version 1

  keg_only "forked dependency of bemly/tahoe; avoid symlink conflicts with homebrew/core"

  uses_from_macos "m4"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    system "./configure", "--disable-dependency-tracking",
                          "--enable-relocatable",
                          "--prefix=/output",
                          "M4=m4"
    system "make", "install", "DESTDIR=#{buildpath}"
    prefix.install Dir["#{buildpath}/output/*"]
  end

  test do
    assert_match "3.8.2", shell_output("#{bin}/bison --version")
  end
end
