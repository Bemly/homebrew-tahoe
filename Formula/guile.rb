class Guile < Formula
  desc "GNU Ubiquitous Intelligent Language for Extensions"
  homepage "https://www.gnu.org/software/guile/"
  url "https://ftpmirror.gnu.org/guile/guile-3.0.11.tar.xz"
  mirror "https://ftp.gnu.org/gnu/guile/guile-3.0.11.tar.xz"
  sha256 "818c79d236657a7fa96fb364137cc7b41b3bdee0d65c6174ca03769559579460"
  license "LGPL-3.0-or-later"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "6c4c8c62e7f7ac3b1fe3068ac5f89c41281cb1a4ca299f66aea890ec80956d49"
    sha256 tahoe: "6260450b9a9ab85c2d8a00012721de44537aefcb3aa80236bb2a38a1aabd5991"
  end

  head do
    url "https://git.savannah.gnu.org/git/guile.git", branch: "main"

    depends_on "autoconf" => :build
    depends_on "bemly/tahoe/automake" => :build
    depends_on "bemly/tahoe/fork-gettext" => :build
    uses_from_macos "flex" => :build

    on_system :linux, macos: :ventura_or_newer do
      depends_on "texinfo" => :build
    end
  end

  depends_on "bemly/tahoe/gnu-sed" => :build
  depends_on "bemly/tahoe/bdw-gc"
  depends_on "bemly/tahoe/gmp"
  depends_on "libtool"
  depends_on "bemly/tahoe/libunistring"
  depends_on "bemly/tahoe/fork-pkgconf" # guile-config is a wrapper around pkg-config.
  depends_on "bemly/tahoe/fork-readline"
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  uses_from_macos "gperf"
  uses_from_macos "libffi"
  uses_from_macos "libxcrypt"

  deny_network_access!

  def install
    ENV.prepend_path "PATH", Formula["bemly/tahoe/gnu-sed"].opt_libexec/"gnubin"
    # So we can find libraries with (dlopen).
    ENV.append "LDFLAGS", "-Wl,-rpath,#{HOMEBREW_PREFIX}/lib"

    # Avoid superenv shim
    inreplace "meta/guile-config.in", "@PKG_CONFIG@", formula_opt_bin("bemly/tahoe/fork-pkgconf")/"pkg-config"

    system "./autogen.sh" unless build.stable?

    system "./configure", "--disable-nls",
                          "--with-libreadline-prefix=#{formula_opt_prefix("bemly/tahoe/fork-readline")}",
                          "--with-libgmp-prefix=#{formula_opt_prefix("bemly/tahoe/gmp")}",
                          *std_configure_args
    system "make", "install"

    # A really messed up workaround required on macOS --mkhl
    Pathname.glob("#{lib}/*.dylib") do |dylib|
      lib.install_symlink dylib.basename => "#{dylib.basename(".dylib")}.so"
    end

    # This is either a solid argument for guile including options for
    # --with-xyz-prefix= for libffi and bdw-gc or a solid argument for
    # Homebrew automatically removing Cellar paths from .pc files in favour
    # of opt_prefix usage everywhere.
    inreplace lib/"pkgconfig/guile-3.0.pc" do |s|
      s.gsub! Formula["bemly/tahoe/bdw-gc"].prefix.realpath, formula_opt_prefix("bemly/tahoe/bdw-gc")
      s.gsub! Formula["libffi"].prefix.realpath, formula_opt_prefix("libffi") unless OS.mac?
    end

    (share/"gdb/auto-load").install Dir["#{lib}/*-gdb.scm"]
  end

  post_install_steps do
    mkdir_p "{{HOMEBREW_PREFIX}}/lib/guile/3.0/site-ccache"
    mkdir_p "{{HOMEBREW_PREFIX}}/lib/guile/3.0/extensions"
    mkdir_p "{{HOMEBREW_PREFIX}}/share/guile/site/3.0"
  end

  def caveats
    <<~EOS
      Guile libraries can now be installed here:
          Source files: #{HOMEBREW_PREFIX}/share/guile/site/3.0
        Compiled files: #{HOMEBREW_PREFIX}/lib/guile/3.0/site-ccache
            Extensions: #{HOMEBREW_PREFIX}/lib/guile/3.0/extensions

      Add the following to your .bashrc or equivalent:
        export GUILE_LOAD_PATH="#{HOMEBREW_PREFIX}/share/guile/site/3.0"
        export GUILE_LOAD_COMPILED_PATH="#{HOMEBREW_PREFIX}/lib/guile/3.0/site-ccache"
        export GUILE_SYSTEM_EXTENSIONS_PATH="#{HOMEBREW_PREFIX}/lib/guile/3.0/extensions"
    EOS
  end

  test do
    hello = testpath/"hello.scm"
    hello.write <<~SCHEME
      (display "Hello World")
      (newline)
    SCHEME

    ENV["GUILE_AUTO_COMPILE"] = "0"

    system bin/"guile", hello
  end
end
