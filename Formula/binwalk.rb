class Binwalk < Formula
  desc "Searches a binary image for embedded files and executable code"
  homepage "https://github.com/ReFirmLabs/binwalk"
  license "MIT"
  url "https://github.com/ReFirmLabs/binwalk/archive/refs/tags/v3.1.0.tar.gz"
  sha256 "06f595719417b70a592580258ed980237892eadc198e02363201abe6ca59e49a"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "90d9814e674c0cbd5585c3b3e79f5b693d3ef32a51b931355c84a84731abd045"
    sha256 cellar: :any_skip_relocation, tahoe: "014845ee1a026a8d19501a40e7453748fb762040f763ec4c81c9997c3d3a555e"
  end

  resource "rustc" do
    url "https://static.rust-lang.org/dist/2025-11-10/rustc-1.91.1-x86_64-apple-darwin.tar.xz"
    sha256 "bfd9626778ab8b89bc3fbf5ebb1cadd89dc95aa03341619ce7f1bff232682d2d"
  end

  resource "cargo" do
    url "https://static.rust-lang.org/dist/2025-11-10/cargo-1.91.1-x86_64-apple-darwin.tar.xz"
    sha256 "806bfe86fc4809ec1f5a9b0b0d48cb2de3e0e44a1c46faf47fe041d68f4f1966"
  end

  resource "rust-std" do
    url "https://static.rust-lang.org/dist/2025-11-10/rust-std-1.91.1-x86_64-apple-darwin.tar.xz"
    sha256 "0b796716e7606a92e86da3c8953253e8088e816f16461b77fa537d21cc08f3f7"
  end

  patch do
    url "https://github.com/ReFirmLabs/binwalk/commit/b83242ffbd54997d11c7f7e304c17bf9582e38fe.patch?full_index=1"
    sha256 "3a9e9f43ee552d6c3ab3d8069524a786b95f1256969f30400c679b1cc19e026c"
    type :backport
    resolves "https://github.com/ReFirmLabs/binwalk/pull/735"
  end

  depends_on "bemly/tahoe/sevenzip"
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  uses_from_macos "bzip2"
  uses_from_macos "xz"

  deny_network_access!

  def prepare_rust
    toolchain = buildpath/"rust-1.91.1"
    sysroot = toolchain/"lib/rustlib/x86_64-apple-darwin/lib"
    return toolchain if (toolchain/"bin/rustc").file? && sysroot.directory?

    resource("cargo").stage do
      cargo = Pathname(Dir["**/bin/cargo"].fetch(0))
      (toolchain/"bin").install cargo
    end

    resource("rustc").stage do
      rustc = Pathname(Dir["**/bin/rustc"].fetch(0))
      rustc_root = rustc.dirname.parent
      (toolchain/"bin").install Dir[rustc_root/"bin/*"]
      (toolchain/"lib").install Dir[rustc_root/"lib/*"]
    end

    resource("rust-std").stage do
      stdlib = Pathname(Dir["**/lib/rustlib/x86_64-apple-darwin/lib"].fetch(0))
      (toolchain/"lib/rustlib/x86_64-apple-darwin").install Dir[stdlib.dirname/"*"]
    end

    chmod 0555, toolchain/"bin/rustc"
    chmod 0555, toolchain/"bin/cargo"
    odie "Rust 1.91.1 标准库缺失" unless sysroot.directory?
    toolchain
  end

  def fetch
    rust = prepare_rust
    ENV["RUSTC"] = (rust/"bin/rustc").to_s
    ENV.prepend_path "PATH", rust/"bin"
    system rust/"bin/cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    rust = prepare_rust
    ENV["RUSTC"] = (rust/"bin/rustc").to_s
    ENV.prepend_path "PATH", rust/"bin"
    system "cargo", "install", *std_cargo_args
  end

  test do
    touch "binwalk.test"
    system bin/"binwalk", "binwalk.test"
  end
end
