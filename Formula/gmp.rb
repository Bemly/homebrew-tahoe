class Gmp < Formula
  desc "GNU multiple precision arithmetic library"
  homepage "https://gmplib.org/"
  # gmplib.org blocks GitHub server IPs, so it should not be the primary URL
  url "https://ftpmirror.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz"
  mirror "https://gmplib.org/download/gmp/gmp-6.3.0.tar.xz"
  sha256 "a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898"
  license any_of: ["LGPL-3.0-or-later", "GPL-2.0-or-later"]
  depends_on arch: :x86_64
  depends_on macos: :tahoe
  compatibility_version 1
  head "https://gmplib.org/repo/gmp/", using: :hg

  livecheck do
    url "https://gmplib.org/download/gmp/"
    regex(/href=.*?gmp[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end


  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  uses_from_macos "m4" => :build

  deny_network_access!

  def install
    if build.head?
      system "./.bootstrap"
    else
      # Regenerate configure to avoid flat namespace linking
      # Reported by email: https://gmplib.org/list-archives/gmp-bugs/2023-July/thread.html
      # Remove in next version
      system "autoreconf", "-i", "-s"
    end

    # Enable --with-pic to avoid linking issues with the static library
    args = %w[--enable-cxx --with-pic]

    cpu = Hardware::CPU.arm? ? "aarch64" : Hardware.oldest_cpu
    if OS.mac?
      args << "--build=#{cpu}-apple-darwin#{OS.kernel_version.major}"
    else
      args << "--build=#{cpu}-linux-gnu"
      args << "ABI=32" if Hardware::CPU.is_32_bit?
    end

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "check"
    system "make", "install"

    # Prevent brew from trying to install metafiles that
    # are actually symlinks to files in autotools kegs
    buildpath.children.select(&:symlink?).map(&:unlink) if build.head?
  end

  test do
    (testpath/"test.c").write <<~C
      #include <gmp.h>
      #include <stdlib.h>

      int main() {
        mpz_t i, j, k;
        mpz_init_set_str (i, "1a", 16);
        mpz_init (j);
        mpz_init (k);
        mpz_sqrtrem (j, k, i);
        if (mpz_get_si (j) != 5 || mpz_get_si (k) != 1) abort();
        return 0;
      }
    C

    system ENV.cc, "test.c", "-L#{lib}", "-lgmp", "-o", "test"
    system "./test"

    # Test the static library to catch potential linking issues
    system ENV.cc, "test.c", "#{lib}/libgmp.a", "-o", "test"
    system "./test"
  end
end
