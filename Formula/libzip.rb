class Libzip < Formula
  desc "C library for reading, creating, and modifying zip archives"
  homepage "https://libzip.org/"
  url "https://libzip.org/download/libzip-1.12.1.tar.xz"
  sha256 "c40062022a1963c80573d48f6070792297cecd7c6bffe3aefcac0d8b9bee8913"
  license "BSD-3-Clause"
  compatibility_version 1

  livecheck do
    url "https://libzip.org/download/"
    regex(/href=.*?libzip[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "21f3282ce206810566d555ea6c37161a0a07fe8c39b1cb21c1fd3f53f5851963"
    sha256 cellar: :any, tahoe: "2c3033bcaff96dfecd294c8a1fe4e6550bd583410f5109db722d3cf4cb09f90d"
  end

  depends_on "bemly/tahoe/cmake" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/xz"
  depends_on macos: :tahoe
  depends_on "bemly/tahoe/zstd"

  uses_from_macos "zip" => :test
  uses_from_macos "bzip2"

  on_linux do
    depends_on "bemly/tahoe/openssl@4"
    depends_on "zlib-ng-compat"
  end

  def install
    args = %w[
      -DENABLE_GNUTLS=OFF
      -DENABLE_MBEDTLS=OFF
      -DBUILD_REGRESS=OFF
      -DBUILD_EXAMPLES=OFF
    ]
    args << "-DENABLE_OPENSSL=OFF" if OS.mac?

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    touch "file1"
    system "zip", "file1.zip", "file1"
    touch "file2"
    system "zip", "file2.zip", "file1", "file2"
    assert_match(/\+.*file2/, shell_output("#{bin}/zipcmp -v file1.zip file2.zip", 1))
  end
end
