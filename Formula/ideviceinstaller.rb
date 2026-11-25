class Ideviceinstaller < Formula
  desc "Tool for managing apps on iOS devices"
  homepage "https://libimobiledevice.org/"
  url "https://github.com/libimobiledevice/ideviceinstaller/releases/download/1.2.0/ideviceinstaller-1.2.0.tar.bz2"
  sha256 "26115288e50d003bbb7d23c05441c54ea69b255974303bfd44fef6943e042f94"
  license "GPL-2.0-or-later"
  revision 1
  head "https://github.com/libimobiledevice/ideviceinstaller.git", branch: "master"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "84f52f1ae00da3c33fd00f49108641c7973fbcf8b00690d321908d26929f1a8e"
    sha256 cellar: :any, tahoe: "aed157a27dd57ed89781612d5cfa1fb8b40f86577681f995c81f5f79706d472b"
  end

  depends_on "autoconf" => :build
  depends_on "bemly/tahoe/automake" => :build
  depends_on "libtool" => :build
  depends_on "bemly/tahoe/pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libimobiledevice"
  depends_on "bemly/tahoe/libplist"
  depends_on "bemly/tahoe/libzip"
  depends_on macos: :tahoe

  deny_network_access!

  def install
    configure = build.head? ? "./autogen.sh" : "./configure"
    system configure, *std_configure_args
    system "make", "install"
  end

  test do
    assert_match "Manage apps on iOS devices", shell_output("#{bin}/ideviceinstaller --help")
  end
end
