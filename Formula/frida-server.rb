class FridaServer < Formula
  desc "Frida dynamic instrumentation server (Intel x86_64 build for macOS Tahoe)"
  homepage "https://frida.re"
  # frida-server 是 frida/frida 发布的裸二进制（macOS 侧只有 .xz 格式，无
  # checksums 清单——sha 由检查器下载实算）。xz 内是单文件、无顶层目录。
  url "https://github.com/frida/frida/releases/download/17.27.5/frida-server-17.27.5-macos-x86_64.xz"
  sha256 "c60b54667ce0fa0691d469b1c6794ceec0aa00e68a2d388d44a9a8e63b0d1724"
  # 根 COPYING 是 wxWindows Library Licence 3.1（= LGPL-2.1 + 静态链接例外）。
  license "LGPL-2.1-only" => { with: "WxWindows-exception-3.1" }

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "17e8b5bfb63173e8236decdc4bf90d70c7bd15d5c015f602b34a1b1304374a64"
    sha256 cellar: :any_skip_relocation, tahoe: "56012c1018aba9c464bbc312ef9f35dc804e31d6d2343091ba4d686198f15c96"
  end

  # brew 解 .xz 的 UnpackStrategy::Xz 硬依赖 xz 公式（unpack_strategy/xz.rb
  # 的 dependencies）：不声明则源码安装时报"需先装 xz"。声明成 build 依赖后
  # CI/源码装自动补齐，用户走 GHCR 瓶时 build 依赖被跳过（瓶是 tar.gz，
  # 解包根本不经过 xz，零摩擦）。
  depends_on "bemly/tahoe/xz" => :build

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # xz 解出的单文件名因 brew 缓存命名而异（frida-server-<ver>-macos-x86_64
    # 或 frida-server--<ver>），通配兜底，统一改名为 frida-server。
    bin.install Dir["frida-server*"].fetch(0) => "frida-server"
    server = bin/"frida-server"
    # unxz 不给执行位（上游打包时原文件就是 644），而 brew 的 bin.install
    # 按源文件 exec 位决定 0555/0444——不 chmod 就装出个不可执行文件。
    chmod 0555, server

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包。
    #    校验放在 install 里：brew 6 已把 post_install 废弃为声明式的
    #    post_install_steps（跑不了 file(1) + odie 这类断言，见 style cop
    #    FormulaAudit/InstallSteps），老 DSL 会触发 odeprecated。
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", server.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{server} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(server.to_s, "--version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "frida-server #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      frida-server 已安装为 Intel(x86_64) 原生二进制，直接取自 frida/frida 官方发布包。

      它是动态插桩的"目标端"守护进程，默认只监听 127.0.0.1:27042，需要 root 运行：
        sudo #{opt_bin}/frida-server

      客户端（本机或远程）连接：
        frida -H 127.0.0.1 -l <脚本> <进程名>        # 本机连接
        frida-server -l 0.0.0.0                      # 如需远程连接（自担风险）

      注入受 SIP 保护的系统进程需要自行处理 SIP（本 tap 不代劳）；
      普通用户进程与未受保护的应用可直接注入。
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/frida-server --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/frida-server")
  end
end
