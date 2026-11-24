class AntigravityCli < Formula
  desc "Google Antigravity command-line agent (official Intel macOS binary)"
  homepage "https://antigravity.google/cli"
  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.15-5514532022517760/darwin-x64/cli_mac_x64.tar.gz"
  version "1.5.15"
  sha256 "91fee043a384b76cee5d5f1568b946ab2f25bf38c938f0bd7c4b27fefa0c4e43"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "1c64001188017a774a3c19754f417e61986656a2f68cb70d5647aa89c1444af7"
    sha256 cellar: :any_skip_relocation, tahoe: "0af8d06b8da7b84ac1bbc4e08bec95ae9a3dbf7832514c5f82053a3d5acc96d7"
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
