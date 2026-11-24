class Ripgrep < Formula
  desc "Search tool like grep and The Silver Searcher"
  homepage "https://github.com/BurntSushi/ripgrep"
  version "15.2.0"
  license "Unlicense"
  compatibility_version 1

  url "https://github.com/BurntSushi/ripgrep/releases/download/#{version}/ripgrep-#{version}-x86_64-apple-darwin.tar.gz"
  sha256 "af7825fcc69a2afc7a7aea55fc9af90e26421d8f20fe59df32e233c0b8a231c1"

  on_arm do
    url "https://github.com/BurntSushi/ripgrep/releases/download/#{version}/ripgrep-#{version}-aarch64-apple-darwin.tar.gz"
    sha256 "3750b2e93f37e0c692657da574d7019a101c0084da05a790c83fd335bad973e4"
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
