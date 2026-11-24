class Nettle < Formula
  desc "Low-level cryptographic library"
  homepage "https://www.lysator.liu.se/~nisse/nettle/"
  url "https://ftpmirror.gnu.org/nettle/nettle-4.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/nettle/nettle-4.0.tar.gz"
  sha256 "3addbc00da01846b232fb3bc453538ea5468da43033f21bb345cb1e9073f5094"
  license any_of: ["GPL-2.0-or-later", "LGPL-3.0-or-later"]
  compatibility_version 2

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "3885aa0400033cdf9435d66410d85a9bf6143c9e2d62a44fc914986878299ed0"
    sha256 cellar: :any, tahoe: "b40055fb7abcac89caf5d094d0e3a9aaf2bb0fe61fa4d01dd364cdf56bb2fb5d"
  end

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/gmp"
  depends_on macos: :tahoe

  uses_from_macos "m4" => :build

  deny_network_access!

  def install
    system "./configure", *std_configure_args, "--enable-shared"
    system "make"
    system "make", "install"
    system "make", "check"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <nettle/sha1.h>
      #include <stdio.h>

      int main()
      {
        struct sha1_ctx ctx;
        uint8_t digest[SHA1_DIGEST_SIZE];
        unsigned i;

        sha1_init(&ctx);
        sha1_update(&ctx, 4, "test");
        sha1_digest(&ctx, digest);

        printf("SHA1(test)=");

        for (i = 0; i<SHA1_DIGEST_SIZE; i++)
          printf("%02x", digest[i]);

        printf("\\n");
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lnettle", "-o", "test"
    system "./test"
  end
end
