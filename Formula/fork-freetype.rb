class ForkFreetype < Formula
  desc "Software library to render fonts"
  homepage "https://www.freetype.org/"
  url "https://downloads.sourceforge.net/project/freetype/freetype2/2.15.0/freetype-2.15.0.tar.xz"
  mirror "https://download.savannah.gnu.org/releases/freetype/freetype-2.15.0.tar.xz"
  sha256 "93cd47eb719c325107f2d3cf087d06299e944c3b48a40b55537302304dea1dd5"
  license "FTL"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/url=.*?freetype[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  keg_only "forked dependency of bemly/tahoe; avoid symlink conflicts with homebrew/core"

  depends_on "bemly/tahoe/fork-pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/fork-brotli"
  depends_on "bemly/tahoe/fork-libpng"
  depends_on macos: :tahoe

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  deny_network_access!

  def install
    # Avoid enabling macOS 15.4+ hvf feature for bottle compatibility
    ENV["ac_cv_header_hvf_Scaler_h"] = "no" if OS.mac? && MacOS.version <= :sequoia

    # This file will be installed to bindir, so we want to avoid embedding the
    # absolute path to the pkg-config shim.
    inreplace "builds/unix/freetype-config.in", "%PKG_CONFIG%", "pkg-config"

    system "./configure", "--prefix=#{prefix}",
                          "--enable-freetype-config",
                          "--with-brotli",
                          "--without-harfbuzz"
    system "make"
    system "make", "install"

    inreplace [bin/"freetype-config", lib/"pkgconfig/freetype2.pc"],
      prefix, opt_prefix
  end

  test do
    system bin/"freetype-config", "--cflags", "--libs", "--ftversion",
                                  "--exec-prefix", "--prefix"
  end
end
