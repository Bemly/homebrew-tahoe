class Libpsl < Formula
  desc "C library for the Public Suffix List"
  homepage "https://rockdaboot.github.io/libpsl"
  url "https://github.com/rockdaboot/libpsl/releases/download/0.23.3/libpsl-0.23.3.tar.gz"
  mirror "http://distfiles.macports.org/libpsl/libpsl-0.23.3.tar.gz"
  mirror "http://ftp2.osuosl.org/pub/blfs/conglomeration/libpsl/libpsl-0.23.3.tar.gz"
  sha256 "93941f85a1e7bd593fa94f299233cb5dfc91cd144fd9a78a6ceb75001c5b03be"
  license "MIT"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "c3ed5a885c0e35e34f83d5b6357e8350bbd2fd27e04bda452f46e6c91f9244cd"
  end

  depends_on "bemly/tahoe/fork-pkgconf" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  on_system :linux, macos: :monterey_or_older do
    depends_on "bemly/tahoe/libidn2"
    depends_on "bemly/tahoe/libunistring"
  end

  deny_network_access!

  def install
    runtime = (OS.linux? || MacOS.version <= :monterey) ? "libidn2" : "libicucore"
    args = %W[
      --disable-silent-rules
      --enable-builtin
      --enable-runtime=#{runtime}
    ]
    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <assert.h>
      #include <stdio.h>
      #include <string.h>

      #include <libpsl.h>

      int main(void)
      {
          const psl_ctx_t *psl = psl_builtin();

          const char *domain = ".eu";
          assert(psl_is_public_suffix(psl, domain));

          const char *host = "www.example.com";
          const char *expected_domain = "example.com";
          const char *actual_domain = psl_registrable_domain(psl, host);
          assert(strcmp(actual_domain, expected_domain) == 0);

          return 0;
      }
    C
    system ENV.cc, "-o", "test", "test.c", "-I#{include}", "-L#{lib}", "-lpsl"
    system "./test"
  end
end
