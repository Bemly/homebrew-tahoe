class ForkWebp < Formula
  desc "Image format providing lossless and lossy compression for web images"
  homepage "https://developers.google.com/speed/webp/"
  url "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.6.0.tar.gz"
  sha256 "e4ab7009bf0629fd11982d4c2aa83964cf244cffba7347ecd39019a9e38c4564"
  license "BSD-3-Clause"
  compatibility_version 1

  head "https://chromium.googlesource.com/webm/libwebp.git", branch: "main"

  livecheck do
    url "https://developers.google.com/speed/webp/docs/compiling"
    regex(/libwebp[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  keg_only "forked dependency of bemly/tahoe; avoid symlink conflicts with homebrew/core"

  depends_on "cmake" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/fork-giflib"
  depends_on "bemly/tahoe/fork-jpeg-turbo"
  depends_on "bemly/tahoe/fork-libpng"
  depends_on macos: :tahoe

  deny_network_access!

  def install
    args = %W[
      -DCMAKE_INSTALL_RPATH=#{rpath}
      -DCMAKE_DISABLE_FIND_PACKAGE_TIFF=ON
    ]
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, "-DBUILD_SHARED_LIBS=ON", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    system "cmake", "-S", ".", "-B", "static", *std_cmake_args, "-DBUILD_SHARED_LIBS=OFF", *args
    system "cmake", "--build", "static"
    lib.install buildpath.glob("static/*.a")

    # Avoid rebuilding dependents that hard-code the prefix.
    inreplace (lib/"pkgconfig").glob("*.pc"), prefix, opt_prefix
  end

  test do
    system bin/"cwebp", test_fixtures("test.png"), "-o", "webp_test.png"
    system bin/"dwebp", "webp_test.png", "-o", "webp_test.webp"
    assert_path_exists testpath/"webp_test.webp"
  end
end
