class AntigravityCli < Formula
  desc "Google Antigravity command-line agent (official Intel macOS binary)"
  homepage "https://antigravity.google/cli"
  url "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.13-5999302598852608/darwin-x64/cli_mac_x64.tar.gz"
  version "1.5.13"
  sha256 "04974195ddad0315834e053b1c93831ac66dc27acb6c335fff404882bd55fa99"

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
