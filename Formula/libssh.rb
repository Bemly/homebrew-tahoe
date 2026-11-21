class Libssh < Formula
  desc "C library SSHv1/SSHv2 client and server protocols"
  homepage "https://www.libssh.org/"
  url "https://www.libssh.org/files/0.12/libssh-0.12.2.tar.xz"
  sha256 "49560f677d96e3706a904ac2de1116e25f3680937d51e5c92198fcba4a1c1e9f"
  license "LGPL-2.1-or-later"
  revision 1
  compatibility_version 1

  head "https://git.libssh.org/projects/libssh.git", branch: "master"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "ab438b96d39a92978641ca2b4436f1662e585c56557bf6f9289d952e0e753bbf"
  end

  depends_on "cmake" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/fork-openssl@4"
  depends_on macos: :tahoe

  on_linux do
    depends_on "zlib-ng-compat"
  end

  deny_network_access!

  def install
    args = %w[
      -DBUILD_STATIC_LIB=ON
      -DWITH_SYMBOL_VERSIONING=OFF
    ]

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    lib.install "build/src/libssh.a"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <libssh/libssh.h>
      #include <stdlib.h>

      int main() {
        ssh_session my_ssh_session = ssh_new();
        if (my_ssh_session == NULL)
          exit(-1);
        ssh_free(my_ssh_session);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-o", "test", "-I#{include}", "-L#{lib}", "-lssh"
    system "./test"
  end
end
