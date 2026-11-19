class Z3 < Formula
  desc "High-performance theorem prover"
  homepage "https://github.com/Z3Prover/z3"
  # 文件名里的 osx-13.3 会让 brew 扫成 "13.3"，必须显式声明真实版本
  url "https://github.com/Z3Prover/z3/releases/download/z3-5.3.3/z3-5.3.3-x64-osx-13.3.zip"
  version "5.3.3"
  sha256 "ace69787d5a21762154b103abe68178188f38e02362fb0f82d346621af90f8e7"
  license "MIT"
  compatibility_version 5

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "cd985ef0656eefb991391d50ccb4eabe339d953f5a0a6af233d3456aee2a50f6"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    bin.install "bin/z3"
    lib.install Dir["bin/libz3*"]
    include.install Dir["include/*"]
  end

  test do
    assert_match "Z3 version 5.3.3", shell_output("#{bin}/z3 -version")
  end
end
