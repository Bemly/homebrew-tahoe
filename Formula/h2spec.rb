class H2spec < Formula
  desc "HTTP/2 conformance testing tool (Intel x86_64 for macOS Tahoe)"
  homepage "https://github.com/summerwind/h2spec"
  # 上游官方 darwin_amd64 tar 包（单个 h2spec 二进制，无顶层目录）。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/summerwind/h2spec/releases/download/v2.6.0/h2spec_darwin_amd64.tar.gz"
  sha256 "981cb9f90a6f5e36300063022bd4eb7438d3dcf66d63a146a8541359697d1601"
  license "Apache-2.0"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "93429801238fc73f8fe2a83ccd0b0249e891c8f36575a99eeb56cbded9a1b203"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 h2spec 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/h2spec，
  # 不能同时安装。安装后如需切换见 caveats。

  def install
    # tar 内无顶层目录：单个 h2spec 二进制直接在 CWD。
    bin.install "h2spec"

    # 安装后架构与版本自检（放在 install 尾部，brew 6+ 已废弃 def post_install）
    h2spec = bin/"h2spec"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", h2spec.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{h2spec} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(h2spec.to_s, "--version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "h2spec #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      h2spec 已安装为 Intel(x86_64) 原生二进制，直接取自上游官方发布包
      （H2 协议负向/一致性测试，Phase 2 用）。

      与 homebrew/core 的 h2spec 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall h2spec && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install h2spec
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/h2spec --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/h2spec")
  end
end
