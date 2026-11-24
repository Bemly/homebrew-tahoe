class Libyaml < Formula
  desc "YAML Parser"
  homepage "https://github.com/yaml/libyaml"
  url "https://github.com/yaml/libyaml/archive/refs/tags/0.2.5.tar.gz"
  sha256 "fa240dbf262be053f3898006d502d514936c818e422afdcf33921c63bed9bf2e"
  license "MIT"
  compatibility_version 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "6c1e9a6f09d046bf5a0f4bd0d8c3208731af01515584cb7bff7fd0f99de362b8"
    sha256 cellar: :any, tahoe: "781953be424e02dcce486617441dae38b2a65efc7b69781481b54d71fa424125"
  end

  depends_on "autoconf" => :build
  depends_on "bemly/tahoe/automake" => :build
  depends_on "libtool" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    system "./bootstrap"
    system "./configure", "--disable-dependency-tracking", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include <yaml.h>

      int main()
      {
        yaml_parser_t parser;
        yaml_parser_initialize(&parser);
        yaml_parser_delete(&parser);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-lyaml", "-o", "test"
    system "./test"
  end
end
