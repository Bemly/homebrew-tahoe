class BoostAT185 < Formula
  desc "Collection of portable C++ source libraries (prebuilt macOS x86 binaries)"
  homepage "https://www.boost.org/"
  url "https://github.com/MarkusJx/prebuilt-boost/releases/download/1.85.0/boost-1.85.0-macos-13-clang-static%2Bshared-x86.tar.gz"
  sha256 "3dc046775e2e8114e58ae11672f5473bdf99a724afe9c0aa252959efa9ef16ce"
  license "BSL-1.0"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "e5d3083e8db01a7905d663c8fb0cf135b797c8330cafc0d4238490d6823790bd"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # brew 会自动下降进唯一顶层 boost 目录；以 include/ 存在与否判定 CWD
    root = File.directory?("include") ? "." : Dir["*/include"].map { |p| File.dirname(p) }.first
    include.install Dir[File.join(root, "include", "*")]
    lib.install Dir[File.join(root, "lib", "*")]
    # 第三方预编译 dylib 用 @rpath 但没有 LC_RPATH，补上并 ad-hoc 重签
    Dir[lib/"*.dylib"].each do |f|
      MachO::Tools.add_rpath(f, "@loader_path")
      system "codesign", "--force", "--sign", "-", f
    end
  end

  test do
    assert_path_exists include/"boost/version.hpp"
  end
end
