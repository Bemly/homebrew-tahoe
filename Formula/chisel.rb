class Chisel < Formula
  desc "Fast TCP/UDP tunnel over HTTP(S), Intel x86_64 build for macOS Tahoe"
  homepage "https://github.com/jpillora/chisel"
  # 上游官方 darwin_amd64 裸二进制（gzip 单文件，gunzip -N 还原为 chisel）。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/jpillora/chisel/releases/download/v1.12.0/chisel_1.12.0_darwin_amd64.gz"
  sha256 "4aeae36c867f11c8e8c3f2b913a0e063ea3c6d29e1c14a52ed2e6eef8cfc4395"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "2c45cf8964b075981f164bbc5aaebe09553e25acddedcee876dd524ce910acb9"
  end

  # bottle do 块不要手填：由 bottle.yml 制瓶后自动写回（见 AGENTS.md 4/8.5）。

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def pre_install
    # 磁盘空间检查：二进制约 12MB，留足余量
    required_mb = 256
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 chisel #{version}（Intel x86_64）"
  end

  def install
    # gzip 内是单文件、无顶层目录；gunzip -N 按头里的原名还原为 chisel。
    # 通配兜底，防止上游改名导致 fetch 后文件名与预期不符。
    bin.install Dir["chisel*"].fetch(0) => "chisel"
    chisel = bin/"chisel"
    # gunzip 不还原执行位（解出 0644），而 bin.install 按源文件 exec 位决定
    # 0555/0444——不 chmod 就装出个不可执行文件（frida-server/yt-dlp 同例）。
    chmod 0555, chisel

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包。
    #    校验放在 install 里：brew 6 已把 post_install 废弃为声明式的
    #    post_install_steps（跑不了 file(1) + odie 这类断言，见
    #    FormulaAudit/InstallSteps），老 DSL 会触发 odeprecated。
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", chisel.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{chisel} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(chisel.to_s, "--version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "chisel #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      chisel 是单二进制（client / server 同体），直接取自 jpillora/chisel 官方发布包。

      注意：homebrew/core 另有一个同名但完全无关的 chisel（Facebook 的 LLDB
      命令集），两者共用 #{HOMEBREW_PREFIX}/Cellar/chisel，不能同时安装。
      如已装过 core 版，请先卸载：
        brew uninstall chisel

      典型用法（服务端与客户端是同一个二进制）：
        chisel server --reverse --port 8080
        chisel client http://<server>:8080 R:8080:localhost:80

      SOCKS5 代理模式：
        chisel server --socks5 --port 8080
        chisel client http://<server>:8080 socks
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/chisel --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/chisel")
  end
end
