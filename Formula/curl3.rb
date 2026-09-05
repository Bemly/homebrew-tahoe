class Curl3 < Formula
  desc "Independent HTTP/3 client with MASQUE/CONNECT-UDP interop (Intel x86_64)"
  homepage "https://curl.se"
  # 与 homebrew/core 的 curl 同源（同 tarball），但做了两处实质改动：
  # 1. 独家 --enable-proxy-http3（MASQUE/CONNECT-UDP 实验开关，core 没开）；
  # 2. 纯客户端形态：--disable-shared 静态链接 libcurl，二进制自包含，
  #    开发件（include/curl-config/pkgconfig/man3）一律不装——macOS SDK 自带
  #    curl 头文件，link 出来会被 audit 判 shadowing（11.32），而互操作测试
  #    只要个能跑的客户端，不需要 lib 开发件。
  # 改名 curl3 则是为了不替换 core 的 curl：core curl 被大量公式依赖，
  # 同名跨 tap 不能共存，改名后 Cellar/curl3 独立存在，双方互不干扰。
  # 镜像只留点分段格式的 fresh-center 两行：core 的 GitHub 镜像 tag 用下划线
  # （curl-8_22_0），watcher 的版本子串替换够不着，会留旧版本，故不保留；
  # audit --strict 要求至少一个镜像，见 11.28。
  url "https://curl.se/download/curl-8.22.0.tar.bz2"
  mirror "http://fresh-center.net/linux/www/curl-8.22.0.tar.bz2"
  mirror "http://fresh-center.net/linux/www/legacy/curl-8.22.0.tar.bz2"
  sha256 "5d956a6a22b3c279f50c421ee5d3c9e9d660cb6f115dcf881b579e952130549c"
  license "curl"
  compatibility_version 1

  livecheck do
    url "https://curl.se/download/"
    regex(/href=.*?curl[._-]v?(.*?)\.t/i)
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 cellar: :any, tahoe: "8d53ed4599c79037e537aee06271db3741792cf4b09b4dd3c5dd60ee6aa3f31b"
  end

  head do
    url "https://github.com/curl/curl.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  # 不 keg-only、正常 link：装出来的主二进制已改名 curl3（见 install），
  # 不会遮蔽系统 /usr/bin/curl；开发件已裁掉（见类注释），link 出来的全是
  # curl3 专属文件，无 shadowing。

  depends_on "pkgconf" => :build
  depends_on arch: :x86_64
  depends_on "bemly/tahoe-intel/libnghttp3"
  depends_on "bemly/tahoe-intel/libngtcp2"
  depends_on "brotli"
  depends_on "libnghttp2"
  depends_on "libpsl"
  depends_on "libssh2"
  depends_on macos: :tahoe
  depends_on "openssl@3"
  depends_on "zstd"

  uses_from_macos "krb5"
  uses_from_macos "openldap"

  on_system :linux, macos: :monterey_or_older do
    depends_on "libidn2"
  end

  on_linux do
    depends_on "zlib-ng-compat"
  end

  def install
    # core 用 stable.mirrors 校验 tag 的逻辑已删（镜像行已摘，见上）。
    # Use our `curl` formula with `wcurl`
    inreplace "scripts/wcurl", 'CMD="curl "', "CMD=\"#{opt_bin}/curl3 \""

    system "autoreconf", "--force", "--install", "--verbose" if build.head?

    # HTTP/3 与代理 H3（MASQUE/CONNECT-UDP）互操作就靠下面三行；
    # 其中 --enable-proxy-http3 是实验性编译开关（curl 官方 EXPERIMENTAL.md，
    # 缺了它就没有 --proxy-http3/CONNECT-UDP），core 默认没开，这是本公式
    # 相对 core 改动最大的地方；其余参数与 core 一致。
    args = %W[
      --disable-shared
      --disable-silent-rules
      --enable-proxy-http3
      --with-ssl=#{formula_opt_prefix("openssl@3")}
      --without-ca-bundle
      --without-ca-path
      --with-ca-fallback
      --with-default-ssl-backend=openssl
      --with-libssh2
      --with-nghttp3
      --with-ngtcp2
      --with-libpsl
    ]

    args += if OS.mac?
      %w[
        --with-apple-sectrust
        --with-gssapi
      ]
    else
      ["--with-gssapi=#{formula_opt_prefix("krb5")}"]
    end

    args += if OS.mac? && MacOS.version >= :ventura
      %w[
        --with-apple-idn
        --without-libidn2
      ]
    else
      %w[
        --without-apple-idn
        --with-libidn2
      ]
    end

    system "./configure", *args, *std_configure_args
    system "make", "install"
    system "make", "install", "-C", "scripts"
    libexec.install "scripts/mk-ca-bundle.pl"

    # 公式叫 curl3，用户敲的就该是 curl3：主二进制与 man 页改名，
    # 系统 /usr/bin/curl 原样不动（11.32）。
    mv bin/"curl", bin/"curl3"
    mv man1/"curl.1", man1/"curl3.1" if (man1/"curl.1").exist?

    # 纯客户端：开发件全部裁掉（--disable-shared 下二进制已静态链接 libcurl，
    # 这些文件只是摆设；留着反而触发系统头 shadowing，见类注释）。
    rm_r include
    rm bin/"curl-config" if (bin/"curl-config").exist?
    rm_r lib/"pkgconfig" if (lib/"pkgconfig").exist?
    rm_r share/"man/man3" if (share/"man/man3").exist?
  end

  def caveats
    <<~EOS
      curl3 已安装为独立命令（H3/MASQUE 互操作客户端），与系统 curl 共存：
        curl3 --http3-only -v https://cloudflare-quic.com
        curl3 --proxy-http3 --proxy https://127.0.0.1:8443 https://example.com
      系统 /usr/bin/curl 未被触碰；`curl` 仍是系统版，`curl3` 才是本 tap 的 H3 版。
    EOS
  end

  test do
    # Fetch the curl tarball and see that the checksum matches.
    # This requires a network connection, but so does Homebrew in general.
    filename = testpath/"test.tar.gz"
    system bin/"curl3", "-L", stable.url, "-o", filename
    filename.verify_checksum stable.checksum

    # Verify QUIC and HTTP3 support（注意：沙箱/代理环境可能禁 UDP，
    # H3 直连失败不代表没编进去——存在性由下面的 --help all + HTTP3 特性断言，
    # 连通性这条尽力而试，失败只告警，CI 干净网络下会真跑）。
    begin
      system bin/"curl3", "-m", "20", "--verbose", "--http3-only", "--head", "https://cloudflare-quic.com"
    rescue
      opoo "H3 直连失败（沙箱可能禁 UDP），跳过连通性用例，存在性见下断言"
    end

    # MASQUE/CONNECT-UDP 代理开关必须编进去（--enable-proxy-http3 的存在性证明；
    # 新版裸 --help 只打分类列表，必须查 --help all）
    assert_match "proxy-http3", shell_output("#{bin}/curl3 --help all")

    # H3 协议栈必须静态链进二进制（纯客户端无 curl-config，拿 --version 断言；
    # 输出首行自带 nghttp2/ngtcp2/nghttp3 版本串）。
    version_line = shell_output("#{bin}/curl3 --version").lines.first.to_s
    %w[nghttp2 ngtcp2 nghttp3].each do |lib|
      assert_includes version_line, lib
    end
  end
end
