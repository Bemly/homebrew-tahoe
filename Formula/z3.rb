class Z3 < Formula
  desc "High-performance theorem prover"
  homepage "https://github.com/Z3Prover/z3"
  url "https://github.com/Z3Prover/z3/archive/refs/tags/z3-5.3.2.tar.gz"
  sha256 "df91b87822f5f8b6710af1f2419ba98758cd647dee3a8f0d070f128b47024dbe"
  license "MIT"
  compatibility_version 5
  head "https://github.com/Z3Prover/z3.git", branch: "master"

  livecheck do
    url :stable
    regex(/z3[._-]v?(\d+(?:\.\d+)+)/i)
    strategy :github_latest
  end


  # 刻意不声明 cmake（同 llvm.rb：树里已有 python 拖入的裸 cmake，再挂全名必
  # 触发同进程 flock 自锁，见 11.51）；cmake 由 bottle.yml 制瓶前预装本 tap 瓶走 PATH。
  # Has Python bindings but are supplementary to the main library
  # which does not need Python.
  depends_on "python@3.14" => [:build, :test]

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # The following macOS conditional should be the inverse of LLVM's Z3 conditional
  on_ventura :or_older do
    fails_with :clang do
      cause "Requires C++20 std::format, https://developer.apple.com/xcode/cpp/#c++20"
    end
  end

  fails_with :gcc do
    version "12"
    cause "Requires C++20 std::format, https://gcc.gnu.org/gcc-13/changes.html#libstdcxx"
  end

  deny_network_access!

  def install
    # cmake 刻意不声明（见文件头注释）：这里显式把本 tap cmake 瓶的 bin 塞进构建 PATH。
    # superenv 构建隔离了 /usr/local/bin，未声明的依赖 brew 不会自动注入（11.51）；
    # Formula[] 引用不产生依赖边，不进锁数组。bottle.yml 会预装好该瓶。
    ENV.prepend_path "PATH", formula_opt_bin("bemly/tahoe/cmake")
    args = %W[
      -DZ3_LINK_TIME_OPTIMIZATION=ON
      -DZ3_INCLUDE_GIT_DESCRIBE=OFF
      -DZ3_INCLUDE_GIT_HASH=OFF
      -DZ3_INSTALL_PYTHON_BINDINGS=ON
      -DZ3_BUILD_EXECUTABLE=ON
      -DZ3_BUILD_TEST_EXECUTABLES=OFF
      -DZ3_BUILD_PYTHON_BINDINGS=ON
      -DZ3_BUILD_DOTNET_BINDINGS=OFF
      -DZ3_BUILD_JAVA_BINDINGS=OFF
      -DZ3_USE_LIB_GMP=OFF
      # 不用 Formula#python3 helper（2026-09-02 才进 brew，runner 镜像是 8 月版没有它，
      # NameError 实锤）：下面两行就是该 helper 对 python@3.14 的展开结果。
      -DPYTHON_EXECUTABLE=#{formula_opt_bin("python@3.14")}/python3.14
      -DCMAKE_INSTALL_PYTHON_PKG_DIR=#{Language::Python.site_packages("python3.14")}
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    system "make", "-C", "contrib/qprofdiff"
    bin.install "contrib/qprofdiff/qprofdiff"

    pkgshare.install "examples"
  end

  test do
    system ENV.cc, pkgshare/"examples/c/test_capi.c", "-I#{include}",
                   "-L#{lib}", "-lz3", "-o", testpath/"test"
    system "./test"
    assert_equal version.to_s,
shell_output("#{formula_opt_bin("python@3.14")}/python3.14 -c 'import z3; print(z3.get_version_string())'").strip
  end
end
