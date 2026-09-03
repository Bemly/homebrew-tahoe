class Ripgrep < Formula
  desc "Search tool like grep and The Silver Searcher"
  homepage "https://github.com/BurntSushi/ripgrep"
  url "https://github.com/BurntSushi/ripgrep/archive/refs/tags/15.2.0.tar.gz"
  sha256 "7605249d3eb0d5f170e3414498e3344e26b1e7a147aec518b57090b80036a562"
  license "Unlicense"
  compatibility_version 1

  head "https://github.com/BurntSushi/ripgrep.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on "asciidoctor" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe
  depends_on "pcre2"

  # downloads crates during install
  allow_network_access! :build

  def install
    system "cargo", "install", *std_cargo_args(features: "pcre2")

    generate_completions_from_executable(bin/"rg", "--generate", shell_parameter_format: "complete-")
    (man1/"rg.1").write Utils.safe_popen_read(bin/"rg", "--generate", "man")
  end

  test do
    (testpath/"Hello.txt").write("Hello World!")
    system bin/"rg", "Hello World!", testpath
  end
end
