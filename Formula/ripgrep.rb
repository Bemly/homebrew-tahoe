class Ripgrep < Formula
  desc "Search tool like grep and The Silver Searcher"
  homepage "https://github.com/BurntSushi/ripgrep"
  version "16.0.0"
  license "Unlicense"
  compatibility_version 1

  url "https://github.com/BurntSushi/ripgrep/releases/download/#{version}/ripgrep-#{version}-x86_64-apple-darwin.tar.gz"
  sha256 "aa9183b0e0bfac03c5818895ad18b75001c402d230063898abfe5a58cd413caa"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "1129d82e41c8936c92ef63d8c4620bcc23b517ce2d6f8f58ca4b5e5e84aad81b"
    sha256 cellar: :any_skip_relocation, tahoe: "7caa262a768376b649af68ed7290a2f2a3f5b8444d4b879eb553b3157b276d72"
  end

  on_arm do
    url "https://github.com/BurntSushi/ripgrep/releases/download/#{version}/ripgrep-#{version}-aarch64-apple-darwin.tar.gz"
    sha256 "5a145656d5067144001bfce6648767fd3254599aa736f1ffdb7fb907760b8ca1"
  end

  head "https://github.com/BurntSushi/ripgrep.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on macos: :tahoe

  def install
    bin.install "rg"
    man1.install "doc/rg.1"
    doc.install "README.md", "COPYING", "UNLICENSE", "LICENSE-MIT"
    generate_completions_from_executable(bin/"rg", "--generate", shell_parameter_format: "complete-")
  end

  test do
    (testpath/"Hello.txt").write("Hello World!")
    system bin/"rg", "Hello World!", testpath
    assert_match "features:+pcre2", shell_output("#{bin}/rg --version")
  end
end
