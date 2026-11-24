class RustAT1911 < Formula
  desc "Pinned Rust toolchain for building Binwalk 3.1.0"
  homepage "https://www.rust-lang.org/"
  license any_of: ["Apache-2.0", "MIT"]
  url "https://static.rust-lang.org/dist/2025-11-10/cargo-1.91.1-x86_64-apple-darwin.tar.xz",
      using: :nounzip
  sha256 "806bfe86fc4809ec1f5a9b0b0d48cb2de3e0e44a1c46faf47fe041d68f4f1966"

  resource "rustc" do
    url "https://static.rust-lang.org/dist/2025-11-10/rustc-1.91.1-x86_64-apple-darwin.tar.xz",
        using: :nounzip
    sha256 "bfd9626778ab8b89bc3fbf5ebb1cadd89dc95aa03341619ce7f1bff232682d2d"
  end

  resource "rust-std" do
    url "https://static.rust-lang.org/dist/2025-11-10/rust-std-1.91.1-x86_64-apple-darwin.tar.xz",
        using: :nounzip
    sha256 "0b796716e7606a92e86da3c8953253e8088e816f16461b77fa537d21cc08f3f7"
  end

  keg_only "pinned build dependency for bemly/tahoe/binwalk"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    bin.install Dir["cargo/bin/*"]
    share.install Dir["cargo/share/*"]

    resource("rustc").stage do
      bin.install Dir["rustc/bin/*"]
      lib.install Dir["rustc/lib/*"]
      doc.install "LICENSE-APACHE", "LICENSE-MIT", "COPYRIGHT"
    end

    resource("rust-std").stage do
      (lib/"rustlib").install Dir["rust-std-*/lib/rustlib/*"]
    end

    chmod 0555, bin/"rustc", bin/"cargo"
    odie "Rust 工具链版本自检失败" unless Utils.safe_popen_read(bin/"rustc", "--version").include?("1.91.1")
  end

  test do
    assert_match "rustc 1.91.1", shell_output("#{bin}/rustc --version")
    assert_match "cargo 1.91.1", shell_output("#{bin}/cargo --version")
  end
end
