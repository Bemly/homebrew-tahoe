class AntigravityCli < Formula
  desc "Google Antigravity command-line agent (official Intel macOS binary)"
  homepage "https://antigravity.google/cli"
  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.16-5250855658717184/darwin-x64/cli_mac_x64.tar.gz"
  version "1.5.16"
  sha256 "14cd76a31e42ad461d6f8adf7631306cac37553f547aba0a0f111b0824d21c0c"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "1821b657ed0a2d46e9e580ecf1e5696a177588a2fef8ae68b411a2de8b87ec48"
    sha256 cellar: :any_skip_relocation, tahoe: "c39741314e5456fb39c4a3df253f7f7d867717273e006e70d065056bed09c21c"
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
