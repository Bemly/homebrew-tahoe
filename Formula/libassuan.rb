class Libassuan < Formula
  desc "Assuan IPC Library"
  homepage "https://www.gnupg.org/related_software/libassuan/"
  url "https://gnupg.org/ftp/gcrypt/libassuan/libassuan-3.0.2.tar.bz2"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/libassuan/libassuan-3.0.2.tar.bz2"
  sha256 "d2931cdad266e633510f9970e1a2f346055e351bb19f9b78912475b8074c36f6"
  license all_of: [
    "LGPL-2.1-or-later",
    "GPL-3.0-or-later", # assuan.info
    "FSFULLR", # libassuan-config, libassuan.m4
  ]
  compatibility_version 1

  livecheck do
    url "https://gnupg.org/ftp/gcrypt/libassuan/"
    regex(/href=.*?libassuan[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "a0ef05940e6b96e85c0e726e43d513d5ed8edc132d3e9f28b3457597d919e222"
    sha256 cellar: :any, tahoe: "03e86b5594b786f4cce458abc9e790b03c5768d72cd1f53c6a45827d14ba66bc"
  end

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libgpg-error"
  depends_on macos: :tahoe

  deny_network_access!

  def install
    system "./configure", "--disable-silent-rules",
                          "--enable-static",
                          *std_configure_args
    system "make", "install"

    # avoid triggering mandatory rebuilds of software that hard-codes this path
    inreplace bin/"libassuan-config", prefix, opt_prefix
  end

  test do
    system bin/"libassuan-config", "--version"
  end
end
