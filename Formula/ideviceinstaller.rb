class Ideviceinstaller < Formula
  desc "Tool for managing apps on iOS devices"
  homepage "https://libimobiledevice.org/"
  url "https://github.com/libimobiledevice/ideviceinstaller/releases/download/1.2.0/ideviceinstaller-1.2.0.tar.bz2"
  sha256 "26115288e50d003bbb7d23c05441c54ea69b255974303bfd44fef6943e042f94"
  license "GPL-2.0-or-later"
  revision 1
  head "https://github.com/libimobiledevice/ideviceinstaller.git", branch: "master"

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
