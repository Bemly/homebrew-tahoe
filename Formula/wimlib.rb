class Wimlib < Formula
  desc "Library to create, extract, and modify Windows Imaging files"
  homepage "https://wimlib.net/"
  url "https://wimlib.net/downloads/wimlib-1.14.5.tar.gz"
  sha256 "84221a3abd5b91228f15f8e6065c335a336237b5738197b75bf419eea561a194"
  license "GPL-3.0-or-later"
  revision 2
  livecheck do
    url "https://wimlib.net/downloads/"
    regex(/href=.*?wimlib[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "b8180fb529da4b62e97c56e062f41e9eef96cee373de1057c1987a63928ab4fc"
    sha256 cellar: :any, tahoe: "046f1a260b85c1343c19181c30bc8c9d3b17816d7108b000b81a4780dcbca252"
  end

  depends_on "bemly/tahoe/pkgconf" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  on_linux do
    depends_on "libfuse"
    depends_on "ntfs-3g"
  end

  deny_network_access!

  def install
    args = %w[--disable-silent-rules]
    args += %w[--without-fuse --without-ntfs-3g] if OS.mac?

    system "./configure", *args, *std_configure_args
    system "make", "install"
  end

  test do
    # make a directory containing a dummy 1M file
    mkdir("foo")
    size = if OS.mac?
      "1m"
    else
      "1M"
    end
    system "dd", "if=/dev/random", "of=foo/bar", "bs=#{size}", "count=1"
    # capture an image
    ENV.append "WIMLIB_IMAGEX_USE_UTF8", "1"
    system bin/"wimcapture", "foo", "bar.wim"
    assert_path_exists testpath/"bar.wim"

    # get info on the image
    system bin/"wiminfo", "bar.wim"
  end
end
