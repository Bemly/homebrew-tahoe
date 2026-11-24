class Pcre2 < Formula
  desc "Perl compatible regular expressions library with a new API"
  homepage "https://www.pcre.org/"
  url "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.49/pcre2-10.49.tar.bz2"
  sha256 "53c156e1ba416a20da8e65395daa132da0d80e76910424caca3fcdae7831d384"
  license "BSD-3-Clause"
  compatibility_version 1

  livecheck do
    url :stable
    regex(/^pcre2[._-]v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "0479550757944ccc40b2fb53e19fb406b115e6307524df113fe01b1bfb3858ad"
    sha256 cellar: :any, tahoe: "8568cb27211fd436fa8962f0e9792e93c1a8d2fd659d9c6c9d41a3c5dd1becce"
  end

  head do
    url "https://github.com/PCRE2Project/pcre2.git", branch: "main"

    depends_on "autoconf" => :build
    depends_on "bemly/tahoe/automake" => :build
    depends_on "libtool" => :build
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  uses_from_macos "bzip2"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  deny_network_access!

  def install
    args = %w[
      --enable-pcre2-16
      --enable-pcre2-32
      --enable-pcre2grep-libz
      --enable-pcre2grep-libbz2
      --enable-jit
    ]

    args << "--enable-pcre2test-libedit" if OS.mac?

    system "./autogen.sh" if build.head?

    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  test do
    system bin/"pcre2grep", "regular expression", prefix/"README"
  end
end
