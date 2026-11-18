class ForkMpdecimal < Formula
  desc "Library for decimal floating point arithmetic"
  homepage "https://www.bytereef.org/mpdecimal/"
  url "https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-4.0.1.tar.gz"
  sha256 "96d33abb4bb0070c7be0fed4246cd38416188325f820468214471938545b1ac8"
  license "BSD-2-Clause"
  compatibility_version 1

  livecheck do
    url "https://www.bytereef.org/mpdecimal/download.html"
    regex(/href=.*?mpdecimal[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "eb21df42dabf2f8241ab0c334d98f5d5ce7129e0d63076b4fc35766e3c4235fd"
  end

  keg_only "forked dependency of bemly/tahoe; avoid symlink conflicts with homebrew/core"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    ENV.append "LDFLAGS", "-Wl,-rpath,#{rpath}"
    ENV.append "LDXXFLAGS", "-Wl,-rpath,#{rpath}"
    system "./configure", *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <mpdecimal.h>
      #include <string.h>

      int main() {
        mpd_context_t ctx;
        mpd_t *a, *b, *result;
        char *rstring;

        mpd_defaultcontext(&ctx);

        a = mpd_new(&ctx);
        b = mpd_new(&ctx);
        result = mpd_new(&ctx);

        mpd_set_string(a, "0.1", &ctx);
        mpd_set_string(b, "0.2", &ctx);
        mpd_add(result, a, b, &ctx);
        rstring = mpd_to_sci(result, 1);

        assert(strcmp(rstring, "0.3") == 0);

        mpd_del(a);
        mpd_del(b);
        mpd_del(result);
        mpd_free(rstring);

        return 0;
      }
    C
    system ENV.cc, "test.c", "-o", "test", "-L#{lib}", "-lmpdec"
    system "./test"
  end
end
