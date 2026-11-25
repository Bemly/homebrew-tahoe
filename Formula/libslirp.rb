class Libslirp < Formula
  desc "General purpose TCP-IP emulator"
  homepage "https://gitlab.freedesktop.org/slirp/libslirp"
  url "https://gitlab.freedesktop.org/slirp/libslirp/-/archive/v4.9.7/libslirp-v4.9.7.tar.gz"
  sha256 "d2567fa06a6357c7755d61c67293b2c0bf069b3f2173bde6b76cf768529a1938"
  license "BSD-3-Clause"

  compatibility_version 1

  livecheck do
    url :stable
    regex(/^v(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "2df308b3a9753d8ec7f0dfa18302f83fbcbc7b06db6bb720e5cda214800edfba"
    sha256 cellar: :any, tahoe: "9770eafd77950e0f0118327525b497815303b3635b034a6165d99d6b8d4df111"
  end

  depends_on "bemly/tahoe/meson" => :build
  depends_on "bemly/tahoe/ninja" => :build
  depends_on "bemly/tahoe/pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/glib"
  depends_on macos: :tahoe

  def install
    system "meson", "setup", "build", "-Ddefault_library=both", *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <stdio.h>
      #include <string.h>
      #include <stddef.h>
      #include <slirp/libslirp.h>
      int main() {
        SlirpConfig cfg;
        memset(&cfg, 0, sizeof(cfg));
        cfg.version = 1;
        cfg.in_enabled = true;
        cfg.vhostname = "testServer";
        Slirp* ctx = slirp_new(&cfg, NULL, NULL);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lslirp", "-o", "test"
    system "./test"
  end
end
