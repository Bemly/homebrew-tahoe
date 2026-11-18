class ForkLibunistring < Formula
  desc "C string library for manipulating Unicode strings"
  homepage "https://www.gnu.org/software/libunistring/"
  url "https://ftpmirror.gnu.org/libunistring/libunistring-1.5.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libunistring/libunistring-1.5.tar.gz"
  mirror "http://ftp.gnu.org/gnu/libunistring/libunistring-1.5.tar.gz"
  sha256 "5b0ecd46cbf225375f20ab4056197e66a7ac590e2684c069af407ae3383c9d81"
  license any_of: ["GPL-2.0-or-later", "LGPL-3.0-or-later"]
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "e5eb1377332fbc3d408f550183108967b1ff2ee98a3cf323db41dbdf081c8610"
  end

  keg_only "forked dependency of bemly/tahoe; avoid symlink conflicts with homebrew/core"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    # macOS iconv implementation is slightly broken since Sonoma.
    # This is also why we skip `make check`.
    # https://github.com/coreutils/gnulib/commit/bab130878fe57086921fa7024d328341758ed453
    # https://savannah.gnu.org/bugs/?65686
    use_iconv_workaround = OS.mac? && MacOS.version >= :sonoma
    ENV["am_cv_func_iconv_works"] = "yes" if use_iconv_workaround
    system "./configure", "--disable-silent-rules", *std_configure_args
    system "make"
    system "make", "check" unless use_iconv_workaround
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <uniname.h>
      #include <unistdio.h>
      #include <unistr.h>
      #include <stdlib.h>
      int main (void) {
        uint32_t s[2] = {};
        uint8_t buff[12] = {};
        if (u32_uctomb (s, unicode_name_character ("BEER MUG"), sizeof s) != 1) abort();
        if (u8_sprintf (buff, "%llU", s) != 4) abort();
        printf ("%s\\n", buff);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-I#{include}", "-L#{lib}", "-lunistring",
                   "-o", "test"
    assert_equal "🍺", shell_output("./test").chomp
  end
end
