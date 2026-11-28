class AntigravityCli < Formula
  desc "Google Antigravity command-line agent (official Intel macOS binary)"
  homepage "https://antigravity.google/cli"
  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.19-4821414830800896/darwin-x64/cli_mac_x64.tar.gz"
  version "1.5.19"
  sha256 "a8507272963d5a93f18bede59f6ba1efc29f6978a193a4ee5c9ad39a247b993e"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "1e890fdc9aea20769c3d778ace788b0a662dbc09fb41e73f0d064d2e8e7d8e29"
    sha256 cellar: :any_skip_relocation, tahoe: "3ec14e2a05ec0411e29d2deace438db486eafc3d35faefe1d9ed2ad3964c6a6d"
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
