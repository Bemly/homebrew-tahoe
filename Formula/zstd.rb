class Zstd < Formula
  desc "Zstandard is a real-time compression algorithm"
  homepage "https://facebook.github.io/zstd/"
  url "https://github.com/meta/zstd/archive/refs/tags/v1.6.0.tar.gz"
  mirror "http://fresh-center.net/linux/misc/zstd-1.6.0.tar.gz"
  mirror "http://fresh-center.net/linux/misc/legacy/zstd-1.6.0.tar.gz"
  sha256 "289bb207935e5b4f241239f9832e665fa6b9636c3f87f479e125371e13842b8e"
  license all_of: [
    { any_of: ["BSD-3-Clause", "GPL-2.0-only"] },
    "BSD-2-Clause", # programs/zstdgrep, lib/libzstd.pc.in
    "MIT", # lib/dictBuilder/divsufsort.c
  ]
  compatibility_version 1

  head "https://github.com/facebook/zstd.git", branch: "dev"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "54d3dbdb956c0bf28c52c02834affc8f15f81b23f2215ddc337bc79e9da459d9"
    sha256 cellar: :any, tahoe: "67490135d0e9731e5d6a7e7e17898f4afadeeb4bae39ec7dad652c8c2caddb4c"
  end


  depends_on "bemly/tahoe/cmake" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/lz4"
  depends_on "bemly/tahoe/xz"
  depends_on macos: :tahoe

  # The upstream repository contains old, one-off tags (5.5.5, 6.6.6) that are
  # higher than current versions, so we check the "latest" release instead.

  on_linux do
    depends_on "zlib-ng-compat"
  end

  deny_network_access!

  def install
    # Legacy support is the default after
    # https://github.com/facebook/zstd/commit/db104f6e839cbef94df4df8268b5fecb58471274
    # Set it to `ON` to be explicit about the configuration.
    system "cmake", "-S", "build/cmake", "-B", "builddir",
                    "-DBUILD_SHARED_LIBS=ON", # set CMake libzstd target to shared
                    "-DZSTD_PROGRAMS_LINK_SHARED=ON", # link `zstd` to `libzstd`
                    "-DZSTD_BUILD_CONTRIB=ON",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    "-DZSTD_LEGACY_SUPPORT=ON",
                    "-DZSTD_ZLIB_SUPPORT=ON",
                    "-DZSTD_LZMA_SUPPORT=ON",
                    "-DZSTD_LZ4_SUPPORT=ON",
                    "-DCMAKE_CXX_STANDARD=11",
                    *std_cmake_args
    system "cmake", "--build", "builddir"
    system "cmake", "--install", "builddir"

    # Prevent dependents from relying on fragile Cellar paths.
    # https://github.com/ocaml/ocaml/issues/12431
    inreplace lib/"pkgconfig/libzstd.pc", prefix, opt_prefix
  end

  test do
    [bin/"zstd", bin/"pzstd", "xz", "lz4", "gzip"].each do |prog|
      data = "Hello, #{prog}"
      assert_equal data, pipe_output("#{bin}/zstd -d", pipe_output(prog, data))
      if prog.to_s.end_with?("zstd")
        # `pzstd` can only decompress zstd-compressed data.
        assert_equal data, pipe_output("#{bin}/pzstd -d", pipe_output(prog, data))
      else
        assert_equal data, pipe_output("#{prog} -d", pipe_output("#{bin}/zstd --format=#{prog}", data))
      end
    end
  end
end
