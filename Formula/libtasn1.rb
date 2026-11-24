class Libtasn1 < Formula
  desc "ASN.1 structure parser library"
  homepage "https://www.gnu.org/software/libtasn1/"
  url "https://ftpmirror.gnu.org/libtasn1/libtasn1-4.21.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/libtasn1/libtasn1-4.21.0.tar.gz"
  sha256 "1d8a444a223cc5464240777346e125de51d8e6abf0b8bac742ac84609167dc87"
  license "LGPL-2.1-or-later"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "73b2b2e7297a7eca77df67ab92c61c7c13c2613d21cc415c7d29c1c94baae7e8"
    sha256 cellar: :any, tahoe: "362cac70002e1520e8d46b1cd88144e0b1830426e0eb9403e26678aa4da3dd9f"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    system "./configure", "--prefix=#{prefix}", "--disable-dependency-tracking",
                          "--disable-silent-rules"
    system "make", "check"
    system "make", "install"
  end

  test do
    (testpath/"pkix.asn").write <<~EOS
      PKIX1 { }
      DEFINITIONS IMPLICIT TAGS ::=
      BEGIN
      Dss-Sig-Value ::= SEQUENCE {
           r       INTEGER,
           s       INTEGER
      }
      END
    EOS

    (testpath/"assign.asn1").write <<~EOS
      dp PKIX1.Dss-Sig-Value
      r 42
      s 47
    EOS

    system bin/"asn1Coding", "pkix.asn", "assign.asn1"
    assert_match "Decoding: SUCCESS", shell_output("#{bin}/asn1Decoding pkix.asn assign.out PKIX1.Dss-Sig-Value 2>&1")
  end
end
