class Qemu < Formula
  desc "Generic machine emulator and virtualizer"
  homepage "https://www.qemu.org/"
  url "https://download.qemu.org/qemu-11.1.3.tar.xz"
  sha256 "5a8289c7940dc77d3873c81a6c29ba3afe1446fc9d36e77fa1658cdbecb84b22"
  license "GPL-2.0-only"

  compatibility_version 1

  head "https://gitlab.com/qemu-project/qemu.git", branch: "master"

  livecheck do
    url "https://www.qemu.org/download/"
    regex(/href=.*?qemu[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 tahoe: "07b11df404f7f13c3eee776741781fc57a431bd1e71860e4e952f39536bcf602"
  end

  depends_on "bison" => :build # >= 3.0
  depends_on "libtool" => :build
  depends_on "bemly/tahoe/meson" => :build
  depends_on "bemly/tahoe/ninja" => :build
  depends_on "bemly/tahoe/fork-pkgconf" => :build
  depends_on "bemly/tahoe/python@3.15" => :build # keep aligned with meson
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/capstone"
  depends_on "bemly/tahoe/dtc"
  depends_on "bemly/tahoe/libslirp"
  depends_on "bemly/tahoe/vde"
  depends_on "bemly/tahoe/glib"
  depends_on "bemly/tahoe/gnutls"
  depends_on "bemly/tahoe/jpeg-turbo"
  depends_on "bemly/tahoe/libpng"
  depends_on "bemly/tahoe/libssh"
  depends_on "bemly/tahoe/libusb"
  depends_on "bemly/tahoe/lzo"
  depends_on macos: :tahoe
  depends_on "bemly/tahoe/ncurses"
  depends_on "bemly/tahoe/pixman"
  depends_on "bemly/tahoe/snappy"
  depends_on "bemly/tahoe/fork-zstd"

  uses_from_macos "flex" => :build
  uses_from_macos "bzip2"

  on_linux do
    depends_on "attr"
    depends_on "cairo"
    depends_on "elfutils"
    depends_on "gdk-pixbuf"
    depends_on "gtk+3"
    depends_on "keyutils"
    depends_on "libcap-ng"
    depends_on "libepoxy"
    depends_on "libx11"
    depends_on "libxkbcommon"
    depends_on "mesa"
    depends_on "systemd"
    depends_on "zlib-ng-compat"
  end

  def install
    setuptools_site = Dir[formula_opt_lib("python-setuptools")/"python3*/site-packages"].first
    ENV.prepend_path "PYTHONPATH", setuptools_site if setuptools_site
    spice_stage = buildpath/".spice-protocol"
    cp_r formula_opt_prefix("spice-protocol").realpath, spice_stage
    chmod 0644, spice_stage/"share/pkgconfig/spice-protocol.pc"
    inreplace spice_stage/"share/pkgconfig/spice-protocol.pc",
              /^prefix=.*$/,
              "prefix=#{spice_stage}"
    ENV.prepend_path "PKG_CONFIG_PATH", spice_stage/"share/pkgconfig"
    ENV["LIBTOOL"] = "glibtool"

    # Remove wheels unless explicitly permitted. Currently this:
    # * removes `meson` so that brew `meson` is always used
    # * keeps `pycotap` and `qemu_qmp` which are pure-python "none-any" wheels (allowed in homebrew/core)
    rm(Dir["python/wheels/*"] - Dir["python/wheels/{pycotap,qemu_qmp}-*-none-any.whl"])

    # Python 3.15 no longer bundles `wheel` and setuptools builds wheels without it
    inreplace "pythondeps.toml", /^"wheel" = .*\n/, ""

    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-bsd-user
      --disable-download
      --disable-guest-agent
      --enable-slirp
      --enable-capstone
      --enable-curses
      --enable-fdt=system
      --enable-libssh
      --enable-vde
      --enable-virtfs
      --enable-zstd
      --extra-cflags=-DNCURSES_WIDECHAR=1
      --disable-sdl
    ]

    # Sharing Samba directories in QEMU requires the samba.org smbd which is
    # incompatible with the macOS-provided version. This will lead to
    # silent runtime failures, so we set it to a Homebrew path in order to
    # obtain sensible runtime errors. This will also be compatible with
    # Samba installations from external taps.
    args << "--smbd=#{HOMEBREW_PREFIX}/sbin/samba-dot-org-smbd"
    args << "--python=#{formula_opt_bin("bemly/tahoe/python@3.15")/"python3.15"}"

    # The arm64 HVF backend needs the macOS 15 SDK for its EL2 sysregs and vGIC
    args << "--disable-hvf" if OS.mac? && Hardware::CPU.arm? && MacOS.version <= :sonoma

    args += if OS.mac?
      ["--disable-gtk", "--enable-cocoa"]
    else
      ["--enable-gtk"]
    end

    system "./configure", *args
    system "make", "V=1", "install"
  end

  test do
    archs = %w[
      aarch64 alpha arm avr hppa i386 loongarch64 m68k microblaze mips
      mips64 mips64el mipsel or1k ppc ppc64 riscv32 riscv64 rx
      s390x sh4 sh4eb sparc sparc64 tricore x86_64 xtensa xtensaeb
    ]
    archs.each do |guest_arch|
      assert_match version.to_s, shell_output("#{bin}/qemu-system-#{guest_arch} --version")
    end

    system bin/"qemu-img", "create", "-f", "qcow2", "test.qcow2", "1440k"
    assert_match "file format: qcow2", shell_output("#{bin}/qemu-img info test.qcow2")

    system bin/"qemu-img", "convert", "-O", "raw", "test.qcow2", "test.img"
    assert_match "file format: raw", shell_output("#{bin}/qemu-img info test.img")

    # On macOS, verify that we haven't clobbered the signature on the qemu-system-x86_64 binary
    if OS.mac?
      output = shell_output("codesign --verify --verbose #{bin}/qemu-system-x86_64 2>&1")
      assert_match "valid on disk", output
      assert_match "satisfies its Designated Requirement", output
    end
  end
end
