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

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "1ce904c130b0d22c0ca94f4fae85afe30da7531c1eb0ada4e345c48d50bceaa3"
  end

  depends_on "asciidoctor" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  # arch 门槛已摘：opencode 双架构后，ARM 装 opencode 会依赖到它
  # （源码编译，Intel 上走 GHCR 瓶；摘门槛是例外，见 AGENTS 11.27）。
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
