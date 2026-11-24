class Simdjson < Formula
  desc "SIMD-accelerated C++ JSON parser"
  homepage "https://simdjson.org"
  url "https://github.com/simdjson/simdjson/archive/refs/tags/v5.2.0.tar.gz"
  sha256 "499176afd4b32fbe6f65551ef573b880407280072e1c19e22df0b45da58cdf64"
  license "Apache-2.0"
  compatibility_version 3

  head "https://github.com/simdjson/simdjson.git", branch: "master"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "369c448fb3212f09a7788f0496d50a6268a584df7500ec78ba772dfd3d2be81a"
  end

  depends_on "bemly/tahoe/cmake" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    system "cmake", "-S", ".", "-B", "build",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DSIMDJSON_BUILD_STATIC_LIB=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"test.json").write({ name: "Homebrew", isNull: nil }.to_json)
    (testpath/"test.cpp").write <<~CPP
      #include <iostream>
      #include <simdjson.h>
      int main(void) {
        simdjson::dom::parser parser;
        simdjson::dom::element json = parser.load("test.json");
        std::cout << json["name"] << std::endl;
      }
    CPP

    system ENV.cxx, "test.cpp", "-std=c++11",
           "-I#{include}", "-L#{lib}", "-lsimdjson", "-o", "test"
    assert_equal "\"Homebrew\"\n", shell_output("./test")
  end
end
