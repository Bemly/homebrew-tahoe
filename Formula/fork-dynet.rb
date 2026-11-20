class ForkDynet < Formula
  desc "Dynamic Neural Network Toolkit"
  homepage "https://github.com/clab/dynet"
  url "https://github.com/clab/dynet/archive/refs/tags/2.1.2.tar.gz"
  sha256 "014505dc3da2001db54f4b8f3a7a6e7a1bb9f33a18b6081b2a4044e082dab9c8"
  license "Apache-2.0"
  revision 1
  keg_only "forked dependency of bemly/tahoe; avoid symlink conflicts with core"

  deprecate! date: "2026-02-02", because: :unmaintained

  disable! date: "2027-02-02", because: :unmaintained

  depends_on "cmake" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/fork-eigen@3"
  depends_on macos: :tahoe

  # Last release on 2020-10-21 and does not work with latest Eigen;
  # cannot use Eigen >= 5 due to EIGEN_EMPTY_STRUCT_CTOR removal.

  on_linux do
    on_arm do
      depends_on "llvm" => :build

      fails_with :gcc do
        cause "https://github.com/clab/dynet/issues/266"
      end
    end
  end

  def install
    args = %W[
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
      -DEIGEN3_INCLUDE_DIR=#{formula_opt_include("bemly/tahoe/fork-eigen@3")}/eigen3
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    pkgshare.install "examples"
  end

  test do
    cp pkgshare/"examples/xor/train_xor.cc", testpath

    system ENV.cxx, "-std=c++11", "train_xor.cc", "-I#{include}",
                    "-L#{lib}", "-ldynet", "-o", "train_xor"
    assert_match "memory allocation done", shell_output("./train_xor 2>&1")
  end
end
