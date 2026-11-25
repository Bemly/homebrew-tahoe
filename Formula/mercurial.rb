class Mercurial < Formula
  desc "Scalable distributed version control system"
  homepage "https://mercurial-scm.org/"
  url "https://www.mercurial-scm.org/release/mercurial-7.2.4.tar.gz"
  mirror "https://files.pythonhosted.org/packages/source/m/mercurial/mercurial-7.2.4.tar.gz"
  sha256 "85839e0f39e6cb893a88932aa36ef661759f3c5c5de4551ad26bd9df53cb71a2"
  license "GPL-2.0-or-later"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "ae5f016991f1f13856e4aa17eb5c0d3ad5292d59d98f6efe9a3da96c15e773a5"
    sha256 tahoe: "3e8b8a35793883a9a289da145c0e094338ae3e7edb5479c7cc2c7ccbd5254003"
  end

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
