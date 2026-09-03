class Xz < Formula
  desc "General-purpose data compression with high compression ratio"
  homepage "https://tukaani.org/xz/"
  url "https://github.com/tukaani-project/xz/releases/download/v5.8.3/xz-5.8.3.tar.gz"
  mirror "https://downloads.sourceforge.net/project/lzmautils/xz-5.8.3.tar.gz"
  mirror "http://downloads.sourceforge.net/project/lzmautils/xz-5.8.3.tar.gz"
  sha256 "3d3a1b973af218114f4f889bbaa2f4c037deaae0c8e815eec381c3d546b974a0"
  license all_of: [
    "0BSD",
    "GPL-2.0-or-later",
  ]
  depends_on arch: :x86_64
  depends_on macos: :tahoe
  version_scheme 1
  compatibility_version 1


  deny_network_access!

  def install
    system "./configure", "--disable-silent-rules", "--disable-nls", *std_configure_args
    system "make", "check"
    system "make", "install"
  end

  test do
    path = testpath/"data.txt"
    original_contents = "." * 1000
    path.write original_contents

    # compress: data.txt -> data.txt.xz
    system bin/"xz", path
    refute_path_exists path

    # decompress: data.txt.xz -> data.txt
    system bin/"xz", "-d", "#{path}.xz"
    assert_equal original_contents, path.read
  end
end
