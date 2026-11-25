class Pixman < Formula
  desc "Low-level library for pixel manipulation"
  homepage "https://cairographics.org/"
  url "https://cairographics.org/releases/pixman-0.46.4.tar.gz"
  sha256 "d09c44ebc3bd5bee7021c79f922fe8fb2fb57f7320f55e97ff9914d2346a591c"
  license "MIT"
  compatibility_version 1

  livecheck do
    url "https://cairographics.org/releases/?C=M&O=D"
    regex(/href=.*?pixman[._-]v?(\d+\.\d*[02468](?:\.\d+)*)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "f2bef2a72c333756857b2238509d37820c6220b307eacbb4ecd9ae4d918d7a59"
  end

  depends_on "bemly/tahoe/meson" => :build
  depends_on "bemly/tahoe/ninja" => :build
  depends_on "bemly/tahoe/pkgconf" => :test
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    system "meson", "setup", "build", "--default-library=both", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <pixman.h>

      int main(int argc, char *argv[])
      {
        pixman_color_t white = { 0xffff, 0xffff, 0xffff, 0xffff };
        pixman_image_t *image = pixman_image_create_solid_fill(&white);
        pixman_image_unref(image);
        return 0;
      }
    C

    pkgconf_flags = shell_output("pkgconf --cflags --libs pixman-1").chomp.split
    system ENV.cc, "test.c", "-o", "test", *pkgconf_flags
    system "./test"
  end
end
