class ForkBdwGc < Formula
  desc "Garbage collector for C and C++"
  homepage "https://www.hboehm.info/gc/"
  url "https://github.com/bdwgc/bdwgc/releases/download/v8.2.12/gc-8.2.12.tar.gz"
  sha256 "42e5194ad06ab6ffb806c83eb99c03462b495d979cda782f3c72c08af833cd4e"
  license all_of: [
    "Boehm-GC",
    "HPND-sell-variant", # include/gc_allocator.h
  ]
  compatibility_version 1

  head "https://github.com/bdwgc/bdwgc.git", branch: "master"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "e41aba5e0f9c8ac1d09f585ecd99ae6063107b63dccb8d000fe3e5d5b90b7924"
  end

  keg_only "forked dependency of bemly/tahoe; avoid symlink conflicts with homebrew/core"

  depends_on "bemly/tahoe/cmake" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    args = %w[
      -Denable_cplusplus=ON
      -Denable_large_config=ON
      -Dwithout_libatomic_ops=OFF
      -Dwith_libatomic_ops=OFF
    ]

    system "cmake", "-S", ".", "-B", "build",
                    "-Dbuild_tests=ON",
                    "-DBUILD_SHARED_LIBS=ON",
                    "-DCMAKE_INSTALL_RPATH=#{rpath}",
                    *args, *std_cmake_args,
                    "-DBUILD_TESTING=ON" # Pass this *after* `std_cmake_args`
    system "cmake", "--build", "build"
    system "ctest", "--test-dir", "build",
                    "--parallel", ENV.make_jobs,
                    "--rerun-failed",
                    "--output-on-failure",
                    "--repeat", "until-pass:3"
    system "cmake", "--install", "build"

    system "cmake", "-S", ".", "-B", "build-static", "-DBUILD_SHARED_LIBS=OFF", *args, *std_cmake_args
    system "cmake", "--build", "build-static"
    lib.install buildpath.glob("build-static/*.a")
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <stdio.h>
      #include "gc.h"

      int main(void)
      {
        int i;

        GC_INIT();
        for (i = 0; i < 10000000; ++i)
        {
          int **p = (int **) GC_MALLOC(sizeof(int *));
          int *q = (int *) GC_MALLOC_ATOMIC(sizeof(int));
          assert(*p == 0);
          *p = (int *) GC_REALLOC(q, 2 * sizeof(int));
        }
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lgc", "-o", "test"
    system "./test"
  end
end
