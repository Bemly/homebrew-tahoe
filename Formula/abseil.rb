class Abseil < Formula
  desc "C++ Common Libraries"
  homepage "https://abseil.io"
  url "https://github.com/abseil/abseil-cpp/archive/refs/tags/20260817.0.tar.gz"
  sha256 "f7e05179df39c45434cad433f5783840bb3788ef322976f9138bc6b72b3a107d"
  license "Apache-2.0"
  compatibility_version 3
  head "https://github.com/abseil/abseil-cpp.git", branch: "master"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "272d1a2db9a28df9758b2aa43eab83fe848e7dc80d1852c6b3721434400098b9"
    sha256 cellar: :any, tahoe: "3df068ff226e8f0ef12337029d293afee101a79c11428e0278b63f59eb59368e"
  end

  depends_on "bemly/tahoe/cmake" => [:build, :test]
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    ENV.runtime_cpu_detection

    system "cmake", "-S", ".", "-B", "build",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    "-DCMAKE_CXX_STANDARD=17",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DABSL_PROPAGATE_CXX_STD=ON",
                    "-DABSL_ENABLE_INSTALL=ON",
                    *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  test do
    (testpath/"hello_world.cc").write <<~CPP
      #include <iostream>
      #include <string>
      #include <vector>
      #include "absl/strings/str_join.h"

      int main() {
        std::vector<std::string> v = {"foo","bar","baz"};
        std::string s = absl::StrJoin(v, "-");

        std::cout << "Joined string: " << s << "\\n";
      }
    CPP
    (testpath/"CMakeLists.txt").write <<~CMAKE
      cmake_minimum_required(VERSION 3.16)

      project(my_project)

      # Abseil requires C++14
      set(CMAKE_CXX_STANDARD 14)

      find_package(absl REQUIRED)

      add_executable(hello_world hello_world.cc)

      # Declare dependency on the absl::strings library
      target_link_libraries(hello_world absl::strings)
    CMAKE
    system "cmake", testpath
    system "cmake", "--build", testpath, "--target", "hello_world"
    assert_equal "Joined string: foo-bar-baz\n", shell_output("#{testpath}/hello_world")
  end
end
