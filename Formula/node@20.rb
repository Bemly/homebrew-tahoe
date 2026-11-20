class NodeAT20 < Formula
  desc "JavaScript runtime (official macOS x64 prebuilt, repackaged)"
  homepage "https://nodejs.org/"
  url "https://nodejs.org/dist/v20.20.2/node-v20.20.2-darwin-x64.tar.gz"
  version "20.20.2"
  sha256 "8be6f5e4bb128c82774f8a0b8d7a1cc1365a7977d9657cece0ca647b3fe04e61"
  license "MIT"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    prefix.install Dir["*"]
  end

  test do
    assert_match "20.20.2", shell_output("#{bin}/node --version")
  end
end
