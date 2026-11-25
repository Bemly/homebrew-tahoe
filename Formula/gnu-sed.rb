class GnuSed < Formula
  desc "GNU implementation of the stream editor"
  homepage "https://www.gnu.org/software/sed/"
  url "https://ftpmirror.gnu.org/sed/sed-4.10.tar.xz"
  mirror "https://ftp.gnu.org/gnu/sed/sed-4.10.tar.xz"
  sha256 "b8e72182b2ec96a3574e2998c47b7aaa64cc20ce000d8e9ac313cc07cecf28c7"
  license "GPL-3.0-or-later"
  compatibility_version 1

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-dependency-tracking", "--program-prefix=g"
    system "make", "install"
    (libexec/"gnubin").install_symlink bin/"gsed" => "sed"
    (libexec/"gnuman/man1").install_symlink man1/"gsed.1" => "sed.1"
    (libexec/"gnubin").install_symlink "../gnuman" => "man"
  end

  test do
    assert_match "4.10", shell_output("#{bin}/gsed --version")
  end
end
