class Caddy < Formula
  desc "Powerful extensible server platform (Intel x86_64 for macOS Tahoe)"
  homepage "https://caddyserver.com/"
  # 上游官方 mac_amd64 tar 包（顶层即 caddy 二进制，无嵌套目录）。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/caddyserver/caddy/releases/download/v2.11.4/caddy_2.11.4_mac_amd64.tar.gz"
  sha256 "34bc9e5cceee8d67844ef51da624f5b79e8d070f27236e050c3f0066a2dba534"
  license "Apache-2.0"

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 caddy 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/caddy，
  # 不能同时安装。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：本体约 40MB，留足余量
    required_mb = 512
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 caddy #{version}（Intel x86_64）"

    # 若已存在其他来源的 caddy，提前告知同名冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/caddy/*"].map { |keg| File.basename(keg) }
                                                      .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 caddy：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 caddy 同名，不能同时安装，请先卸载另一方：
        brew uninstall caddy
    EOS
  end

  def install
    # tar 内无顶层目录：caddy / LICENSE / README.md 直接在 CWD。
    bin.install "caddy"
    doc.install "LICENSE"
  end

  def post_install
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
