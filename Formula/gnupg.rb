class Gnupg < Formula
  desc "GNU Privacy Guard (OpenPGP)"
  homepage "https://gnupg.org/"
  url "https://gnupg.org/ftp/gcrypt/gnupg/gnupg-2.5.24.tar.bz2"
  sha256 "bf149d01a2b9fcc0e4589b8ae8697d3d5c557ea48ed95a3fa55dd3b1187e6039"
  license "GPL-3.0-or-later"
  revision 1
  compatibility_version 1

  # GnuPG usually indicates stable releases with an even-numbered minor but
  # can declare an odd-numbered minor stable. e.g. 2.5 was stable since 2.5.16,
  # see https://lists.gnupg.org/pipermail/gnupg-announce/2025q4/000500.html.
  # The livecheck scrapes the version from the templated homepage which is
  # manually updated by upstream when a new release series is stable, e.g.
  # https://dev.gnupg.org/rD18a889b403c7a5934d5080be140a4d79e1c83332
  livecheck do
    url :homepage
    regex(/The current version of GnuPG is v?(\d+(?:\.\d+)+)\. /i)
  end

  depends_on "bemly/tahoe/fork-pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/fork-gnutls"
  depends_on "bemly/tahoe/fork-libusb"
  depends_on "bemly/tahoe/fork-readline"
  depends_on "bemly/tahoe/libassuan"
  depends_on "bemly/tahoe/libgcrypt"
  depends_on "bemly/tahoe/libgpg-error"
  depends_on "bemly/tahoe/libksba"
  depends_on "bemly/tahoe/npth"
  depends_on "bemly/tahoe/pinentry"
  depends_on macos: :tahoe

  uses_from_macos "bzip2"
  uses_from_macos "openldap"
  uses_from_macos "sqlite"

  on_macos do
    depends_on "bemly/tahoe/fork-gettext"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  # Fix import of unprotected ECDH secret keys, a regression in 2.5.23
  patch do
    url "https://github.com/gpg/gnupg/commit/42386bcf8861f04c1bdec5cbb139a03da83d8ef9.patch?full_index=1"
    sha256 "93817449be3f93dcade3d79960e33e72959f54f95ff6108f22176bef28111f2b"
    type :backport
    resolves "https://dev.gnupg.org/T8469"
  end

  patch do
    url "https://github.com/gpg/gnupg/commit/5523cec6913bcbd1a374d183899a6f298d2c0e32.patch?full_index=1"
    sha256 "0a0acd2f7f25723f3f84ec5c4ecf03b786d73ca61c48487d4d00c0559be89d66"
    type :backport
    resolves "https://dev.gnupg.org/T8469"
  end

  deny_network_access!

  def install
    libusb = Formula["bemly/tahoe/fork-libusb"]
    ENV.append "CPPFLAGS", "-I#{libusb.opt_include}/libusb-#{libusb.version.major_minor}"

    # gpgscm otherwise hard-codes /tmp on Unix.
    inreplace "tests/gpgscm/tests.scm", "(get-temp-path)", '(getenv "TMPDIR")'

    mkdir "build" do
      system "../configure", "--disable-silent-rules",
                             "--enable-all-tests",
                             "--sysconfdir=#{etc}",
                             "--with-pinentry-pgm=#{formula_opt_bin("bemly/tahoe/pinentry")}/pinentry",
                             "--with-readline=#{formula_opt_prefix("bemly/tahoe/fork-readline")}",
                             *std_configure_args
      system "make"
      system "make", "check"
      system "make", "install"
    end

    # Configure scdaemon as recommended by upstream developers
    # https://dev.gnupg.org/T5415#145864
    if OS.mac?
      # write to buildpath then install to ensure existing files are not clobbered
      (buildpath/"scdaemon.conf").write <<~CONF
        disable-ccid
      CONF
      pkgetc.install "scdaemon.conf"
    end
  end

  post_install_steps do
    mkdir_p "run", base: :var
    terminate_process "gpg-agent", must_succeed: false
  end

  test do
    (testpath/"batch.gpg").write <<~GPG
      Key-Type: RSA
      Key-Length: 2048
      Subkey-Type: RSA
      Subkey-Length: 2048
      Name-Real: Testing
      Name-Email: testing@foo.bar
      Expire-Date: 1d
      %no-protection
      %commit
    GPG

    begin
      system bin/"gpg", "--batch", "--gen-key", "batch.gpg"
      (testpath/"test.txt").write "Hello World!"
      system bin/"gpg", "--detach-sign", "test.txt"
      system bin/"gpg", "--verify", "test.txt.sig"
    ensure
      system bin/"gpgconf", "--kill", "gpg-agent"
    end
  end
end
