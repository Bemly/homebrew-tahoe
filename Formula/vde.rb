class Vde < Formula
  desc "Ethernet compliant virtual network"
  homepage "https://github.com/virtualsquare/vde-2"
  url "https://github.com/virtualsquare/vde-2/archive/refs/tags/v2.3.3.tar.gz"
  sha256 "a7d2cc4c3d0c0ffe6aff7eb0029212f2b098313029126dcd12dc542723972379"
  license all_of: ["GPL-2.0-or-later", "LGPL-2.1-or-later"]

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 tahoe: "06f4845c96f24175867c44377ac4d6b1ced705fcbe4c6ea93f4c9b7256b39eca"
  end
  depends_on arch: :x86_64
  depends_on macos: :tahoe
  head "https://github.com/virtualsquare/vde-2.git", branch: "master"


  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build

  def install
    # vde 2.3.3（2016 年）是旧式 C 代码：头文件写空参括号 `int f();`。
    # C23 起 `()` 等于 `(void)`，新版 clang（Xcode 26 runner，默认 gnu23）
    # 下 libvdehist.c 报 20 个 "too many arguments ... expected 0, have 3"
    # （本机 clang 21 已复现）。锁回 gnu17（clang 15–19 的默认标准）恢复旧语义。
    ENV.append "CFLAGS", "-std=gnu17"
    system "autoreconf", "--force", "--install", "--verbose"
    system "./configure", *std_configure_args
    system "make", "install"
  end

  test do
    system bin/"vde_switch", "-v"
  end
end
