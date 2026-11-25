class Libgcrypt < Formula
  desc "Cryptographic library based on the code from GnuPG"
  homepage "https://gnupg.org/related_software/libgcrypt/"
  url "https://gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-1.12.4.tar.bz2"
  sha256 "d77f68f48879510e79a2f65977ccc68981781ea0923e5bdffac2a193ea3d660e"
  license all_of: ["LGPL-2.1-or-later", "GPL-2.0-or-later"]
  compatibility_version 1

  livecheck do
    url "https://gnupg.org/ftp/gcrypt/libgcrypt/"
    regex(/href=.*?libgcrypt[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "229a4ddd4fa42dbb13dfc7833cd0ea92a477555f724e664c62b03712ebe1fbff"
    sha256 cellar: :any, tahoe: "00e57c1f47119dce4f6698c02365924c67f38c0fbf68cae09777b3b4667befb9"
  end

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libgpg-error"
  depends_on macos: :tahoe

  deny_network_access!

  def install
    system "./configure", "--disable-asm",
                          "--disable-silent-rules",
                          "--enable-static",
                          "--with-libgpg-error-prefix=#{formula_opt_prefix("bemly/tahoe/libgpg-error")}",
                          *std_configure_args

    # The jitter entropy collector must be built without optimisations
    ENV.O0 { system "make", "-C", "random", "rndjent.o", "rndjent.lo" }

    # Parallel builds work, but only when run as separate steps
    system "make"
    system "make", "check"
    system "make", "install"

    # avoid triggering mandatory rebuilds of software that hard-codes this path
    inreplace bin/"libgcrypt-config", prefix, opt_prefix
  end

  test do
    touch "testing"
    output = shell_output("#{bin}/hmac256 \"testing\" testing")
    assert_match "0e824ce7c056c82ba63cc40cffa60d3195b5bb5feccc999a47724cc19211aef6", output
  end
end
