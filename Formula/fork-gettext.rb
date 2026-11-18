class ForkGettext < Formula
  desc "GNU internationalization (i18n) and localization (l10n) library"
  homepage "https://www.gnu.org/software/gettext/"
  url "https://ftpmirror.gnu.org/gettext/gettext-1.0.tar.gz"
  mirror "https://ftp.gnu.org/gnu/gettext/gettext-1.0.tar.gz"
  sha256 "85d99b79c981a404874c02e0342176cf75c7698e2b51fe41031cf6526d974f1a"
  license all_of: [
    "GPL-3.0-or-later",
    "LGPL-2.1-or-later", # libintl, libasprintf
  ]
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 tahoe: "f94e1b875991c4268ec2d3bf95bc9b321c12cff4e537c9e2f9b376732efaf767"
  end

  keg_only "forked dependency of bemly/tahoe; avoid symlink conflicts with homebrew/core"

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/fork-json-c"
  depends_on "bemly/tahoe/fork-libunistring"
  depends_on macos: :tahoe # for spit

  uses_from_macos "curl" # for spit
  uses_from_macos "libxml2"
  uses_from_macos "ncurses"

  on_linux do
    depends_on "acl"
  end

  deny_network_access!

  def install
    # Workaround for newer Clang
    ENV.append_to_cflags "-Wno-incompatible-function-pointer-types" if DevelopmentTools.clang_build_version >= 1500

    # macOS iconv implementation is slightly broken since Sonoma.
    # upstream bug report, https://savannah.gnu.org/bugs/index.php?66541
    ENV["am_cv_func_iconv_works"] = "yes" if OS.mac? && MacOS.version >= :sequoia

    args = [
      "--with-libunistring-prefix=#{formula_opt_prefix("libunistring")}",
      "--disable-silent-rules",
      "--with-included-glib",
      "--with-included-libcroco",
      "--with-emacs",
      "--with-lispdir=#{elisp}",
      "--disable-java",
      "--disable-csharp",
      # Don't use VCS systems to create these archives
      "--without-git",
      "--without-cvs",
      "--without-xz",
    ]
    args << if OS.mac?
      # Ship libintl.h. Disabled on linux as libintl.h is provided by glibc
      # https://gcc-help.gcc.gnu.narkive.com/CYebbZqg/cc1-undefined-reference-to-libintl-textdomain
      # There should never be a need to install gettext's libintl.h on
      # GNU/Linux systems using glibc. If you have it installed you've borked
      # your system somehow.
      "--with-included-gettext"
    else
      "--with-libxml2-prefix=#{formula_opt_prefix("libxml2")}"
    end

    system "./configure", *std_configure_args, *args
    system "make"
    ENV.deparallelize # install doesn't support multiple make jobs
    system "make", "install"
  end

  test do
    system bin/"gettext", "test"
    assert_match "spit: missing --model option\n", shell_output("#{bin}/spit 2>&1", 1)
  end
end
