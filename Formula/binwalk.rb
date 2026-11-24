class Binwalk < Formula
  desc "Searches a binary image for embedded files and executable code"
  homepage "https://github.com/ReFirmLabs/binwalk"
  license "MIT"
  url "https://github.com/ReFirmLabs/binwalk/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "06f595719417b70a592580258ed980237892eadc198e02363201abe6ca59e49a"

  patch do
    url "https://github.com/ReFirmLabs/binwalk/commit/b83242ffbd54997d11c7f7e304c17bf9582e38fe.patch?full_index=1"
    sha256 "3a9e9f43ee552d6c3ab3d8069524a786b95f1256969f30400c679b1cc19e026c"
    type :backport
    resolves "https://github.com/ReFirmLabs/binwalk/pull/735"
  end

  depends_on "bemly/tahoe/rust@1.91.1" => :build
  depends_on "bemly/tahoe/sevenzip"
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  uses_from_macos "bzip2"
  uses_from_macos "xz"

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    system "cargo", "install", *std_cargo_args, "--locked"
  end

  test do
    touch "binwalk.test"
    system bin/"binwalk", "binwalk.test"
  end
end
