class BoostAT185 < Formula
  desc "Collection of portable C++ source libraries (prebuilt macOS x86 binaries)"
  homepage "https://www.boost.org/"
  url "https://github.com/MarkusJx/prebuilt-boost/releases/download/1.85.0/boost-1.85.0-macos-13-clang-static%2Bshared-x86.tar.gz"
  sha256 "3dc046775e2e8114e58ae11672f5473bdf99a724afe9c0aa252959efa9ef16ce"
  license "BSL-1.0"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "804e5c8f9ce631c34b0488f7351ef4244bbf031aeafb54fe3e31f15b25427ca7"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # brew 会自动下降进唯一顶层 boost 目录，兼容两种 CWD
    root = Dir["**/boost"].first || "."
    prefix.install Dir[File.join(root, "*")]
  end

  test do
    assert_path_exists include/"boost/version.hpp"
  end
end
