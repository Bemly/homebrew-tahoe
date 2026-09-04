class Curl3 < Formula
  desc "Independent HTTP/3 client with MASQUE/CONNECT-UDP interop (Intel x86_64)"
  homepage "https://curl.se"
  # 与 homebrew/core 的 curl 同源（同 tarball、同 configure 参数），改名 curl3
  # 是为了不替换 core 的 curl：core curl 被大量公式依赖，同名跨 tap 不能共存，
  # 改名后 Cellar/curl3 独立存在，双方互不干扰。
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

  head do
    url "https://github.com/curl/curl.git", branch: "master"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  # 字符串写法而非 :provided_by_macos 符号：后者会触发
  # FormulaAudit/ProvidedByMacos（那是 brew 本仓内部名单，第三方 tap 加不进去）。
  keg_only "it is provided by macOS"

  depends_on "pkgconf" => [:build, :test]
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
    inreplace "scripts/wcurl", 'CMD="curl "', "CMD=\"#{opt_bin}/curl \""

    system "autoreconf", "--force", "--install", "--verbose" if build.head?

    # HTTP/3 与代理 H3（MASQUE/CONNECT-UDP）互操作就靠下面三行；
    # 其中 --enable-proxy-http3 是实验性编译开关（curl 官方 EXPERIMENTAL.md，
    # 缺了它就没有 --proxy-http3/CONNECT-UDP），core 默认没开，这是本公式
    # 相对 core 改动最大的地方；其余参数与 core 一致。
    args = %W[
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
      --with-zsh-functions-dir=#{zsh_completion}
      --with-fish-functions-dir=#{fish_completion}
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
  end

  def caveats
    <<~EOS
      curl3 与系统 curl / core curl 共存，不会自动 link（keg-only）。
      直接用全路径调用 H3 客户端：
        #{opt_bin}/curl --http3-only -v https://cloudflare-quic.com
      或一次性 link（会遮蔽 /usr/bin/curl проез PATH 顺序，互操作测试时这正是想要的）：
        brew link --force #{full_name}
    EOS
  end

  test do
    # Fetch the curl tarball and see that the checksum matches.
    # This requires a network connection, but so does Homebrew in general.
    filename = testpath/"test.tar.gz"
    system bin/"curl", "-L", stable.url, "-o", filename
    filename.verify_checksum stable.checksum

    # Verify QUIC and HTTP3 support（注意：沙箱/代理环境可能禁 UDP，
    # H3 直连失败不代表没编进去——存在性由下面的 --help all + HTTP3 特性断言，
    # 连通性这条尽力而试，失败只告警，CI 干净网络下会真跑）。
    begin
      system bin/"curl", "-m", "20", "--verbose", "--http3-only", "--head", "https://cloudflare-quic.com"
    rescue
      opoo "H3 直连失败（沙箱可能禁 UDP），跳过连通性用例，存在性见下断言"
    end

    # MASQUE/CONNECT-UDP 代理开关必须编进去（--enable-proxy-http3 的存在性证明；
    # 新版裸 --help 只打分类列表，必须查 --help all）
    assert_match "proxy-http3", shell_output("#{bin}/curl --help all")

    # Check dependencies linked correctly
    curl_features = shell_output("#{bin}/curl-config --features").split("\n")
    %w[brotli GSS-API HTTP2 HTTP3 IDN libz PSL SSL zstd].each do |feature|
      assert_includes curl_features, feature
    end
    curl_protocols = shell_output("#{bin}/curl-config --protocols").split("\n")
    %w[LDAPS SCP SFTP].each do |protocol|
      assert_includes curl_protocols, protocol
    end

    system libexec/"mk-ca-bundle.pl", "test.pem"
    assert_path_exists testpath/"test.pem"
    assert_path_exists testpath/"certdata.txt"

    ENV["PKG_CONFIG_PATH"] = lib/"pkgconfig"
    ENV.append_path "PKG_CONFIG_PATH", Formula["zlib-ng-compat"].lib/"pkgconfig" unless OS.mac?
    system "pkgconf", "--cflags", "libcurl"
  end
end
