class Openjdk < Formula
  desc "Development kit for the Java programming language"
  homepage "https://openjdk.org/"
  url "https://download.java.net/java/GA/jdk26.0.2.1/3b8e6c7ec6274148a7aa15e7e7dfb53c/1/GPL/openjdk-26.0.2.1_macos-x64_bin.tar.gz"
  sha256 "5ec3817530ffa1c38f15a55609a2767335bbd0c59ea8ce41aad68d3cd620c0ae"
  license "GPL-2.0-only" => { with: "Classpath-exception-2.0" }
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "a406eed8ad4114d58a070877de5e6f618a477d253601103d9b9780b0c8060b4e"
  end

  keg_only "bottled by bemly/tahoe; avoid auto-link conflicts with core"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # brew 会自动下降进唯一的 .jdk 顶层目录，故两种 CWD 都要兼容
    home = Dir["**/Contents/Home"].fetch(0)
    prefix.install Dir[File.join(home, "*")]
  end

  test do
    assert_match "26.0.2", shell_output("#{bin}/java -version 2>&1")
  end
end
