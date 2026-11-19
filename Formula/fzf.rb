class Fzf < Formula
  desc "Command-line fuzzy finder"
  homepage "https://github.com/junegunn/fzf"
  url "https://github.com/junegunn/fzf/releases/download/v0.75.0/fzf-0.75.0-darwin_amd64.tar.gz"
  sha256 "8fa67fa874468b8e73ecad2df82cc110026f45d10605128aaac6b191262d2844"
  license "MIT"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    bin.install "fzf"
  end

  test do
    assert_match "0.75.0", shell_output("#{bin}/fzf --version")
  end
end
