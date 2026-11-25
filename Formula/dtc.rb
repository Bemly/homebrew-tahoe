class Dtc < Formula
  desc "Device tree compiler"
  homepage "https://git.kernel.org/pub/scm/utils/dtc/dtc.git"
  url "https://mirrors.edge.kernel.org/pub/software/utils/dtc/dtc-1.8.1.tar.xz"
  sha256 "23526015a6f1550e0541a53fe7acea1b5a11e3697cdf3a3bdc076abc38f6045d"
  license any_of: ["GPL-2.0-or-later", "BSD-2-Clause"]

  compatibility_version 1

  head "https://git.kernel.org/pub/scm/utils/dtc/dtc.git", branch: "master"

  livecheck do
    url "https://mirrors.edge.kernel.org/pub/software/utils/dtc/"
    regex(/href=.*?dtc[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "ebc30d1e000b945eed601df4e828b9f7ee7dc71383bfe57d0e0901e06eb4041c"
    sha256 cellar: :any, tahoe: "61d17f180894c6ef75316a8bfb2eb5f7b19b82f294e9ba2970ccfe6187450c37"
  end
  depends_on "bemly/tahoe/meson" => :build
  depends_on "bemly/tahoe/ninja" => :build
  depends_on "bemly/tahoe/pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libyaml"
  depends_on macos: :tahoe

  depends_on "bemly/tahoe/bison" => :build
  uses_from_macos "flex" => :build

  def install
    args = %w[
      -Dpython=disabled
      -Dtests=false
      -Dvalgrind=disabled
      -Dwerror=false
      -Dyaml=enabled
    ]

    system "meson", "setup", "build", *args, *std_meson_args
    system "meson", "compile", "-C", "build", "--verbose"
    system "meson", "install", "-C", "build"
  end

  test do
    (testpath/"test.dts").write <<~EOS
      /dts-v1/;
      / {
      };
    EOS
    system bin/"dtc", "test.dts"
  end
end
