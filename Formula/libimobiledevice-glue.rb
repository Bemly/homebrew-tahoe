class LibimobiledeviceGlue < Formula
  desc "Library with common system API code for libimobiledevice projects"
  homepage "https://libimobiledevice.org/"
  # 代编译模式：上游只发源码，CI 现编出瓶；生态扇入 3（libimobiledevice/
  # libirecovery/libusbmuxd，全是 idevice 系），无枢纽依赖方，故自瓶。
  # 依赖本 tap 全名叶子（libplist），枢纽留 core 裸名（本包无枢纽依赖）。
  url "https://github.com/libimobiledevice/libimobiledevice-glue/releases/download/1.3.3/libimobiledevice-glue-1.3.3.tar.bz2"
  sha256 "920ce01382a32695f49b23292b4979a03f0afd16c58e8755d8b7f41804acc1a9"
  license "LGPL-2.1-or-later"
  compatibility_version 1
  head "https://github.com/libimobiledevice/libimobiledevice-glue.git", branch: "master"

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libplist"
  depends_on macos: :tahoe

  def install
    configure = build.head? ? "./autogen.sh" : "./configure"
    system configure, "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    (testpath/"test.c").write <<~C
      #include "libimobiledevice-glue/utils.h"

      int main(int argc, char* argv[]) {
        char *uuid = generate_uuid();
        return 0;
      }
    C
    system ENV.cc, "test.c", "-L#{lib}", "-limobiledevice-glue-1.0", "-o", "test"
    system "./test"
  end
end
