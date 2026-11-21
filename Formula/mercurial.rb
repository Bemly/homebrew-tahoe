class Mercurial < Formula
  desc "Scalable distributed version control system"
  homepage "https://mercurial-scm.org/"
  url "https://www.mercurial-scm.org/release/mercurial-7.2.4.tar.gz"
  mirror "https://files.pythonhosted.org/packages/source/m/mercurial/mercurial-7.2.4.tar.gz"
  sha256 "85839e0f39e6cb893a88932aa36ef661759f3c5c5de4551ad26bd9df53cb71a2"
  license "GPL-2.0-or-later"
  compatibility_version 1

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/python@3.11"
  depends_on macos: :tahoe

  allow_network_access! :build

  def install
    python = formula_opt_bin("bemly/tahoe/python@3.11")/"python3.11"
    system python, "-m", "pip", "install", *std_pip_args(build_isolation: true), "."

    system "make", "-C", "contrib/chg", "install", "PREFIX=#{prefix}", "HGPATH=#{bin}/hg", "HG=#{bin}/hg"

    (buildpath/"hgrc").write <<~INI
      [pager]
      pager = less -FRX
    INI

    (etc/"mercurial").install "hgrc"

    man1.install "doc/hg.1"
    man5.install "doc/hgignore.5", "doc/hgrc.5"

    bash_completion.install share/"bash-completion/completions/hg"
  end

  test do
    touch "foobar"
    system bin/"hg", "init"
    system bin/"hg", "add", "foobar"
    system bin/"hg", "--config", "ui.username=brew", "commit", "-m", "initial commit"
    assert_equal "foobar\n", shell_output("#{bin}/hg locate")
    assert_match "initial commit", shell_output("#{bin}/chg log")
  end
end
