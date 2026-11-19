class Protobuf < Formula
  desc "Protocol buffers (Google's data interchange format)"
  homepage "https://protobuf.dev/"
  url "https://github.com/protocolbuffers/protobuf/releases/download/v36.2/protoc-36.2-osx-x86_64.zip"
  sha256 "228cc7add4616cc14ca5e80dee83209d44449a7aee95a914ae748fa374efb078"
  license "BSD-3-Clause"
  compatibility_version 5

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "f95c424a5982b689f79445292cbb8bb7d01ae8bed6aa15769415ccb69cbf7290"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    bin.install "bin/protoc"
    include.install Dir["include/*"]
  end

  test do
    assert_match "libprotoc 36.2", shell_output("#{bin}/protoc --version")
  end
end
