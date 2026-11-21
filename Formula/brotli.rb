class Brotli < Formula
  desc "Generic-purpose lossless compression algorithm by Google"
  homepage "https://github.com/google/brotli"
  url "https://github.com/google/brotli/archive/refs/tags/v1.2.1.tar.gz"
  mirror "http://fresh-center.net/linux/misc/brotli-1.2.1.tar.gz"
  mirror "http://fresh-center.net/linux/misc/legacy/brotli-1.2.1.tar.gz"
  sha256 "98d35d11a78dc453aebb7d10c3748f3f73ff78c8267c0dc697b8631f67bf7e8f"
  license "MIT"
  compatibility_version 1

  head "https://github.com/google/brotli.git", branch: "master"

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    ENV.prepend_path "PATH", Formula["bemly/tahoe/cmake"].opt_bin
    system "cmake", "-S", ".", "-B", "build", "-DCMAKE_INSTALL_RPATH=#{rpath}", *std_cmake_args
    system "cmake", "--build", "build", "--verbose"
    system "ctest", "--test-dir", "build", "--verbose"
    system "cmake", "--install", "build"
    system "cmake", "-S", ".", "-B", "build-static", "-DBUILD_SHARED_LIBS=OFF", *std_cmake_args
    system "cmake", "--build", "build-static"
    lib.install buildpath.glob("build-static/*.a")
  end

  test do
    (testpath/"file.txt").write("Hello, World!")
    system bin/"brotli", "file.txt", "file.txt.br"
    system bin/"brotli", "file.txt.br", "--output=out.txt", "--decompress"
    assert_equal (testpath/"file.txt").read, (testpath/"out.txt").read
  end
end
