class Graphviz < Formula
  desc "Graph visualization software from AT&T and Bell Labs"
  homepage "https://graphviz.org/"
  url "https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/16.1.2/graphviz-16.1.2.tar.xz"
  sha256 "9780938f03659e2effbbfbbaec94940108e794199b73196fa339ca911890e8c9"
  license "EPL-1.0"
  version_scheme 1
  compatibility_version 1

  livecheck do
    url "https://graphviz.org/download/source/"
    regex(/href=.*?graphviz[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 tahoe: "49819067a8a2d996e0612aab1d9fdf0af4cf887131c2da76fc3a703c2cce7ed4"
  end

  head do
    url "https://gitlab.com/graphviz/graphviz.git", branch: "main"

    depends_on "autoconf" => :build
    depends_on "bemly/tahoe/automake" => :build
  end

  depends_on "bison" => :build
  depends_on "bemly/tahoe/fork-pkgconf" => :build
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  uses_from_macos "flex" => :build
  uses_from_macos "python" => :build
  uses_from_macos "expat"

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    args = %w[
      --disable-silent-rules
      --disable-php
      --disable-swig
      --disable-tcl
      --with-quartz
      --with-included-ltdl
      --without-gdk
      --without-gtk
      --without-poppler
      --without-qt
      --without-x
      --with-rsvg=no
      --with-pangocairo=no
      --with-freetype2=no
      --with-gdk-pixbuf=no
      --with-libgd=no
      --with-gts=no
      --with-webp=no
    ]

    system "./autogen.sh" if build.head?
    system "./configure", *args, *std_configure_args
    system "make"
    system "make", "install"
  end

  def caveats
    <<~EOS
      为免用户端源码编译 core 依赖，本瓶关闭了 cairo/pango/librsvg/gd/freetype/
      webp/gts 等第三方插件，只依赖系统库；布局与 PDF/PNG/SVG 等格式由 Quartz 与
      内置插件提供，行为与官方包一致，但动态插件的扩展能力减少。
    EOS
  end

  test do
    (testpath/"sample.dot").write <<~DOT
      digraph G {
        a -> b
      }
    DOT

    system bin/"dot", "-Tpdf", "-o", "sample.pdf", "sample.dot"
  end
end
