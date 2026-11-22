class AntigravityCli < Formula
  desc "Google Antigravity command-line agent (official Intel macOS binary)"
  homepage "https://antigravity.google/cli"
  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.14-5302690847260672/darwin-x64/cli_mac_x64.tar.gz"
  version "1.5.14"
  sha256 "c142141141cbaa93f4e46904b76341e349f3f2b78445f877f39468dfe60dda1e"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "144ab0a78a68775ccee602dcbdaf5c6ba0d9839de83f8e97ffa4d7b2e72ec326"
  end


  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    bin.install "antigravity" => "agy"
    chmod 0555, bin/"agy"
  end

  test do
    assert_match "1.5.13", shell_output("#{bin}/agy --version")
  end
end
