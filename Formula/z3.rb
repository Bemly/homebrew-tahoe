class Z3 < Formula
  desc "High-performance theorem prover"
  homepage "https://github.com/Z3Prover/z3"
  url "https://github.com/Z3Prover/z3/releases/download/z3-5.3.3/z3-5.3.3-x64-osx-13.3.zip"
  sha256 "ace69787d5a21762154b103abe68178188f38e02362fb0f82d346621af90f8e7"
  license "MIT"
  compatibility_version 5

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
