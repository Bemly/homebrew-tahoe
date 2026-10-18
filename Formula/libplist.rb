class Libplist < Formula
  desc "Library for Apple Binary- and XML-Property Lists"
  homepage "https://libimobiledevice.org/"
  # 代编译模式（见 AGENTS.md 6 节 qemu 链规则）：上游只发源码，无 macOS 预编译，
  # CI 在 macos-26-intel 现编出瓶；生态扇入 10 但依赖方全是 idevice 系叶子，
  # 无枢纽依赖方，故自瓶（libtasn1/openssl@4 那种才留 core）。
  url "https://github.com/libimobiledevice/libplist/releases/download/2.8.0/libplist-2.8.0.tar.bz2"
  sha256 "b1f59f7634c58b2481325a23ff4e3bf51574a42d868cbe466d2b39b04550752a"
  license "LGPL-2.1-or-later"
  compatibility_version 2
  head "https://github.com/libimobiledevice/libplist.git", branch: "master"

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "libtool" => :build
  depends_on "pkgconf" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    ENV.deparallelize

    args = %w[
      --disable-silent-rules
      --without-cython
    ]

    system "./autogen.sh", *args, *std_configure_args if build.head?
    system "./configure", *args, *std_configure_args if build.stable?
    system "make"
    system "make", "install"
  end

  test do
    (testpath/"test.plist").write <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>Label</key>
        <string>test</string>
        <key>ProgramArguments</key>
        <array>
          <string>/bin/echo</string>
        </array>
      </dict>
      </plist>
    XML
    system bin/"plistutil", "-i", "test.plist", "-o", "test_binary.plist"
    assert_path_exists testpath/"test_binary.plist", "Failed to create converted plist!"
  end
end
