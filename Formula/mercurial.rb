# No head build supported; if you need head builds of Mercurial, do so outside
# of Homebrew.
class Mercurial < Formula
  desc "Scalable distributed version control system"
  homepage "https://mercurial-scm.org/"
  url "https://www.mercurial-scm.org/release/mercurial-7.2.4.tar.gz"
  sha256 "85839e0f39e6cb893a88932aa36ef661759f3c5c5de4551ad26bd9df53cb71a2"
  license "GPL-2.0-or-later"
  revision 1
  compatibility_version 1

  livecheck do
    url "https://www.mercurial-scm.org/release/"
    regex(/href=.*?mercurial[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/python@3.15"
  depends_on macos: :tahoe

  # Backport to support Python 3.15 with OpenSSL 4
  patch do
    url "https://foss.heptapod.net/mercurial/mercurial-devel/-/commit/5f775798ca43e215b6b190a88733ad8751beb90c.diff"
    sha256 "41fc8b871057ea4c0649e907a8a5c29506273b350e9adb2b08840caad6136ca9"
    type :backport
  end

  allow_network_access! :build

  def install
    system formula_opt_bin("bemly/tahoe/python@3.15")/"python3.15", "-m", "pip", "install",
*std_pip_args(build_isolation: true), "."

    # Install chg (see https://www.mercurial-scm.org/wiki/CHg)
    system "make", "-C", "contrib/chg", "install", "PREFIX=#{prefix}", "HGPATH=#{bin}/hg", "HG=#{bin}/hg"

    # Configure a nicer default pager
    (buildpath/"hgrc").write <<~INI
      [pager]
      pager = less -FRX
    INI

    (etc/"mercurial").install "hgrc"

    # Install man pages, which come pre-built in source releases
    man1.install "doc/hg.1"
    man5.install "doc/hgignore.5", "doc/hgrc.5"

    # Move the bash completion script
    bash_completion.install share/"bash-completion/completions/hg"
  end

  test do
    touch "foobar"
    system bin/"hg", "init"
    system bin/"hg", "add", "foobar"
    system bin/"hg", "--config", "ui.username=brew", "commit", "-m", "initial commit"
    assert_equal "foobar\n", shell_output("#{bin}/hg locate")
    # Check for chg
    assert_match "initial commit", shell_output("#{bin}/chg log")
  end
end
