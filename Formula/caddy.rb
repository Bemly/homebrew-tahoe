class Caddy < Formula
  desc "Powerful extensible server platform (Intel x86_64 for macOS Tahoe)"
  homepage "https://caddyserver.com/"
  # 上游官方 mac_amd64 tar 包（顶层即 caddy 二进制，无嵌套目录）。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/caddyserver/caddy/releases/download/v2.11.9/caddy_2.11.9_mac_amd64.tar.gz"
  sha256 "22af256a2cc45606f6bfa8786cd89130529331319665926f4e972234a658fb30"
  license "Apache-2.0"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "f99ed31b75c8c956b62db51299ceccae6f1b1b22f0c9fdbead96ba04646be8d8"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 caddy 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/caddy，
  # 不能同时安装。安装后如需切换见 caveats。

  def install
    # tar 内无顶层目录：caddy / LICENSE / README.md 直接在 CWD。
    bin.install "caddy"
    doc.install "LICENSE"

    # 安装后架构与版本自检（放在 install 尾部，brew 6+ 已废弃 def post_install）
    caddy = bin/"caddy"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", caddy.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{caddy} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(caddy.to_s, "version")
    unless version_out.include?("v#{version}")
      opoo "版本自检未通过：期望 v#{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "caddy #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      caddy 已安装为 Intel(x86_64) 原生二进制，直接取自上游官方发布包
      （H2/H3 互操作基线服务，反向代理 QUIC 时用它做对端）。

      与 homebrew/core 的 caddy 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall caddy && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install caddy
    EOS
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/caddy version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/caddy")
  end
end
