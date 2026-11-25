class Libnghttp2 < Formula
  desc "HTTP/2 C Library"
  homepage "https://nghttp2.org/"
  url "https://github.com/nghttp2/nghttp2/releases/download/v1.71.0/nghttp2-1.71.0.tar.gz"
  mirror "http://fresh-center.net/linux/www/nghttp2-1.71.0.tar.gz"
  mirror "http://fresh-center.net/linux/www/legacy/nghttp2-1.71.0.tar.gz"
  sha256 "0cdd35ecec77919b4b7b245f87fe8d2216e3d62da854eb0838c594ff058042fc"
  license "MIT"
  compatibility_version 1

  livecheck do
    formula "nghttp2"
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "4eb398ffb6cc2d0a73308f05d7ec34d5cf3fb464ebc7237f132a0f6321efe0c8"
  end

  head do
    url "https://github.com/nghttp2/nghttp2.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "bemly/tahoe/automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "bemly/tahoe/pkgconf" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe
  # this legacy mirror is for user to install from the source when https not working for them
  # see discussions in here, https://github.com/Homebrew/homebrew-core/pull/133078#discussion_r1221941917

  # These used to live in `nghttp2`.
  link_overwrite "include/nghttp2"
  link_overwrite "lib/libnghttp2.a"
  link_overwrite "lib/libnghttp2.dylib"
  link_overwrite "lib/libnghttp2.14.dylib"
  link_overwrite "lib/libnghttp2.so"
  link_overwrite "lib/libnghttp2.so.14"
  link_overwrite "lib/pkgconfig/libnghttp2.pc"

  deny_network_access!

  def install
    system "autoreconf", "--force", "--install", "--verbose" if build.head?
    system "./configure", "--enable-lib-only", *std_configure_args
    system "make", "-C", "lib"
    system "make", "-C", "lib", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <nghttp2/nghttp2.h>
      #include <stdio.h>

      int main() {
        nghttp2_info *info = nghttp2_version(0);
        printf("%s", info->version_str);
        return 0;
      }
    C

    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lnghttp2", "-o", "test"
    assert_equal version.to_s, shell_output("./test")
  end
end
