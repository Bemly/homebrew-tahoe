class AntigravityCli < Formula
  desc "Google Antigravity command-line agent (official Intel macOS binary)"
  homepage "https://antigravity.google/cli"
  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.18-6386224290725888/darwin-x64/cli_mac_x64.tar.gz"
  version "1.5.18"
  sha256 "113e058df8c3e488c90f64ebb1dbdf7763ca01af7027ecfd73ae189f3c530366"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "0010b96c98b136880eff05ff3897f5d199d277d2a921a9a30630c8fe5ac1ab67"
    sha256 cellar: :any_skip_relocation, tahoe: "e093fecf7155f4602353ecc46c90126861973019ca23d579b5605451b0d34b91"
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
