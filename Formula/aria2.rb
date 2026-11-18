class Aria2 < Formula
  desc "Download with resuming and segmented downloading"
  homepage "https://aria2.github.io/"
  url "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0.tar.xz"
  sha256 "60a420ad7085eb616cb6e2bdf0a7206d68ff3d37fb5a956dc44242eb2f79b66b"
  license "GPL-2.0-or-later"
  revision 3

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 tahoe: "522218dd8b171a92eaee011972a2e8100ffc86fc134cdae48009d2521e700acc"
  end
  depends_on "bemly/tahoe/fork-pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/fork-c-ares"
  depends_on "bemly/tahoe/fork-libssh2"
  depends_on "bemly/tahoe/fork-openssl@4"
  depends_on "bemly/tahoe/fork-sqlite"
  depends_on macos: :tahoe

  uses_from_macos "libxml2"

  on_macos do
    depends_on "bemly/tahoe/fork-gettext"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Apply open PR to support OpenSSL 4
  patch do
    url "https://github.com/aria2/aria2/commit/11b1905b1df26c7e074387b3df2c44f814355863.patch?full_index=1"
    sha256 "97c7784eeba35e24bfc309d15b1dc6dfab1655dcd67fc2d03be439d06ad371cf"
    type :unofficial
    resolves "https://github.com/aria2/aria2/pull/2403"
  end

  # Test downloads a file from the network
  allow_network_access! :test

  def install
    ENV.append "LIBS", "-framework Security" if OS.mac?

    args = %w[
      --disable-silent-rules
      --with-libssh2
      --without-gnutls
      --without-libgmp
      --without-libnettle
      --without-libgcrypt
      --without-appletls
      --with-openssl
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"

    bash_completion.install "doc/bash_completion/aria2c"
  end

  test do
    system bin/"aria2c", "https://brew.sh/"
    assert_path_exists testpath/"index.html", "Failed to create index.html!"
  end
end
