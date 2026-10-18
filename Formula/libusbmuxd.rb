class Libusbmuxd < Formula
  desc "USB multiplexor library for iOS devices"
  homepage "https://www.libimobiledevice.org/"
  # 代编译模式：上游只发源码，CI 现编出瓶；生态扇入 2（ios-webkit-debug-proxy/
  # libimobiledevice，全是 idevice 系叶子），故自瓶。
  # 依赖本 tap 全名叶子（glue/libplist）。
  # revision 行与 core 同步：上游发新版时若 core 掉 revision，此行手工删。
  url "https://github.com/libimobiledevice/libusbmuxd/releases/download/2.1.1/libusbmuxd-2.1.1.tar.bz2"
  sha256 "5546f1aba1c3d1812c2b47d976312d00547d1044b84b6a461323c621f396efce"
  license all_of: ["GPL-2.0-or-later", "LGPL-2.1-or-later"]
  revision 1
  compatibility_version 1

  head do
    url "https://github.com/libimobiledevice/libusbmuxd.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on "pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libimobiledevice-glue"
  depends_on "bemly/tahoe/libplist"
  depends_on macos: :tahoe

  allow_network_access! :test

  def install
    configure = build.head? ? "./autogen.sh" : "./configure"
    system configure, "--disable-silent-rules", *std_configure_args
    system "make", "install"
  end

  test do
    source = free_port
    dest = free_port

    PTY.spawn(bin/"iproxy", "-s", "localhost", "#{source}:#{dest}") do |r, w, pid|
      assert_match "Creating listening port #{source} for device port #{dest}", r.readline
      assert_match "waiting for connection", r.readline
      TCPSocket.new("localhost", source).close
      assert_match "New connection for #{source}->#{dest}", r.readline
    ensure
      r.close
      w.close
      Process.wait(pid)
    end
  end
end
