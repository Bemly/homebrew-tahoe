class GnuSed < Formula
  desc "GNU implementation of the stream editor"
  homepage "https://www.gnu.org/software/sed/"
  url "https://ftpmirror.gnu.org/sed/sed-4.10.tar.xz"
  mirror "https://ftp.gnu.org/gnu/sed/sed-4.10.tar.xz"
  sha256 "b8e72182b2ec96a3574e2998c47b7aaa64cc20ce000d8e9ac313cc07cecf28c7"
  license "GPL-3.0-or-later"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "c39827c09501c2de1e101e42a8d6dc7ed2b29f132b6f8edaf4b602227cb15874"
    sha256 tahoe: "56f4518c98f6fad8c0447f0735b30b0e387801b584e22fc4723183fbdfa3a959"
  end

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
