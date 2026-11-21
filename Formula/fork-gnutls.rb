class ForkGnutls < Formula
  desc "GNU Transport Layer Security (TLS) Library"
  homepage "https://gnutls.org/"
  url "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.8/gnutls-3.8.13.tar.xz"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/gnutls/v3.8/gnutls-3.8.13.tar.xz"
  sha256 "ffed8ec1bf09c2426d4f14aae377de4753b53e537d685e604e99a8b16ca9c97e"
  license all_of: ["LGPL-2.1-or-later", "GPL-3.0-only"]
  revision 2
  compatibility_version 2

  livecheck do
    url "https://www.gnutls.org/download.html"
    regex(/href=.*?gnutls[._-]v?(\d+(?:\.\d+)+)\.t/i)
    strategy :page_match do |page, regex|
      # Find the higher version from the directory listing page URLs
      highest_version = page.scan(%r{href=.*?/gnutls/v?(\d+(?:\.\d+)+)/?["' >]}i)
                            .map { |match| match[0] }
                            .max_by { |v| Version.new(v) }
      next unless highest_version

      # Fetch the related directory listing page
      files_page = Homebrew::Livecheck::Strategy.page_content(
        "https://www.gnupg.org/ftp/gcrypt/gnutls/v#{highest_version}",
      )
      next if (files_page_content = files_page[:content]).blank?

      files_page_content.scan(regex).map { |match| match[0] }
    end
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "1a79e0bbeaefe4f266a3204477fcece220d39b9594388a5172d0ac60e0f40e7a"
  end

  keg_only "forked dependency of bemly/tahoe; avoid symlink conflicts with homebrew/core"

  depends_on "bemly/tahoe/fork-pkgconf" => :build
  depends_on "texinfo" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/fork-gmp"
  depends_on "bemly/tahoe/fork-libidn2"
  depends_on "bemly/tahoe/fork-libtasn1"
  depends_on "bemly/tahoe/fork-libunistring"
  depends_on "bemly/tahoe/fork-nettle"
  depends_on "bemly/tahoe/fork-p11-kit"
  depends_on "ca-certificates" => :no_linkage
  depends_on macos: :tahoe

  # The download page links to the directory listing pages for the "Next" and
  # "Current stable" versions. We use the "Next" version in the formula, so we
  # match versions from the tarball links on that directory listing page.

  on_macos do
    depends_on "bemly/tahoe/fork-gettext"
  end

  # Backport support for building with older clang
  patch do
    url "https://gitlab.com/gnutls/gnutls/-/commit/29c2027c963cf559817d0da37c1fc2efd0c1bd6a.diff"
    sha256 "c0bfc0164ff131c9d2e1c4d0367430f8b767b64c9c21e0f408bd634d21fb0302"
    type :backport
    resolves "https://gitlab.com/gnutls/gnutls/-/merge_requests/2106"
  end

  # Test performs a TLS handshake with expired.badssl.com
  allow_network_access! :test

  def install
    # DANE support is disabled so GnuTLS does not have an indirect dependency on OpenSSL.
    # If the feature is wanted, then can consider shipping as split `gnutls-dane` formula.
    args = %W[
      --disable-libdane
      --disable-silent-rules
      --disable-static
      --sysconfdir=#{etc}
      --with-default-trust-store-file=#{pkgetc}/cert.pem
      --disable-heartbeat-support
      --with-p11-kit
    ]

    system "./configure", *args, *std_configure_args
    system "make", "install"

    inreplace lib/"pkgconfig/gnutls.pc", prefix, opt_prefix

    # certtool shadows the macOS certtool utility
    mv bin/"certtool", bin/"gnutls-certtool"
    mv man1/"certtool.1", man1/"gnutls-certtool.1"
  end

  post_install_steps do
    symlink "{{etc}}/ca-certificates/cert.pem", "{{pkgetc}}/cert.pem", overwrite: true
  end

  def caveats
    "Guile bindings are now in the `guile-gnutls` formula."
  end

  test do
    system bin/"gnutls-cli", "--version"
    assert_match "expired certificate", shell_output("#{bin}/gnutls-cli expired.badssl.com", 1)
  end
end
