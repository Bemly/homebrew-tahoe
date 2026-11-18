class Starship < Formula
  desc "Cross-shell prompt for astronauts"
  homepage "https://starship.rs/"
  url "https://github.com/starship/starship/archive/refs/tags/v1.27.0.tar.gz"
  sha256 "f1887ffa88a7ba437d2932501794047e28d03387996f7d1c364631c053cffc44"
  license "ISC"
  head "https://github.com/starship/starship.git", branch: "main"

  depends_on "bemly/tahoe/fork-pkgconf" => :build
  depends_on "cmake" => :build
  depends_on "rust" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  on_linux do
    depends_on "dbus"
    depends_on "zlib-ng-compat"
  end

  deny_network_access!

  def fetch
    system "cargo", "fetch", *std_cargo_fetch_args
  end

  def install
    system "cargo", "install", *std_cargo_args

    generate_completions_from_executable(bin/"starship", "completions")
  end

  test do
    ENV["STARSHIP_CONFIG"] = ""
    assert_equal "[1;32m❯[0m ", shell_output("#{bin}/starship module character")
  end
end
