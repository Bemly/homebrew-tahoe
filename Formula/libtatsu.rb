class Libtatsu < Formula
  desc "Library handling the communication with Apple's Tatsu Signing Server (TSS)"
  homepage "https://libimobiledevice.org/"
  # 代编译模式：上游只发源码，CI 现编出瓶；生态扇入 1（仅 libimobiledevice），故自瓶。
  # 依赖本 tap 全名叶子（libplist）；curl 走 uses_from_macos（CI 用系统 curl，
  # 本机验证需先挪开 /usr/local/lib/libcurl.a——curl3 的静态库，无配套 .dylib，
  # -lcurl 被迫静态链接缺 ICU 符号，见 AGENTS.md §11.2）。
  # revision 行与 core 同步：上游发新版时若 core 掉 revision，此行手工删。
  url "https://github.com/libimobiledevice/libtatsu/releases/download/1.1.1/libtatsu-1.1.1.tar.bz2"
  sha256 "18f471f131c1d55ccc02fa09565d870030c6ce92f737b89fe1b3849941ebb303"
  license "LGPL-2.1-or-later"
  revision 1
  head "https://github.com/libimobiledevice/libtatsu.git", branch: "master"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "d77b8e2187ebc7a6bdeb4589aae1a1492a8baee91372d40e3546ea89bf2368a1"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on "autoconf" => :build
  depends_on "bemly/tahoe/automake" => :build
  depends_on "libtool" => :build
  depends_on "bemly/tahoe/fork-pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libplist"
  depends_on macos: :tahoe

  uses_from_macos "curl"

  def install
    configure = build.head? ? "./autogen.sh" : "./configure"
    system configure, "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "libtatsu/tss.h"

      int main(int argc, char* argv[]) {
        tss_set_debug_level(0);
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-ltatsu", "-o", "test"
    system "./test"
  end
end
