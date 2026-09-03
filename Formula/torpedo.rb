class Torpedo < Formula
  desc "Connect to databases in private VPCs securely, no VPN required"
  homepage "https://github.com/sst/torpedo"
  # 取自 anomalyco/homebrew-tap 的 torpedo.rb（GoReleaser 产物，只留 Intel mac 段）。
  # 上游是 sst/torpedo 的官方发布包；源文件 desc/homepage 为空，此处按上游补齐。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余，见 11.3）。
  url "https://github.com/sst/torpedo/releases/download/v0.0.13/torpedo-mac-x86_64.tar.gz"
  sha256 "6f506cd9875688557a06cd1642ffd26c0ed0af17ac0452fd3e43725d5f87ba46"
  license "MIT"

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def pre_install
    # 磁盘空间检查：torpedo 本体较小，留足余量
    required_mb = 256
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 torpedo #{version}（Intel x86_64）"
  end

  def install
    # 上游 tar.gz 内是 torpedo 二进制 + LICENSE/README（无单一顶层目录），
    # 用 ** 通配兼容 brew 是否下降。
    bin.install Dir["**/torpedo"].fetch(0)

    license = Dir["**/LICENSE"].first
    doc.install license if license
  end

  def post_install
    tp = bin/"torpedo"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", tp.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{tp} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) torpedo 无任何版本命令（`--version` / `version` 均报错非零退出，见实测），
    #    且 safe_popen_read 不容忍非零退出码（同 neofetch 坑），故不做版本自检；
    #    版本正确性由 sha256 + brew 从 URL 扫描保证。
    ohai "torpedo #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      torpedo 已安装为 Intel(x86_64) 原生二进制，取自 sst/torpedo 的官方发布包。
    EOS
  end

  test do
    # torpedo 无版本命令（`--version` exit 1），用 `--help`（exit 0）确认可运行
    assert_match "torpedo", shell_output("#{bin}/torpedo --help")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/torpedo")
  end
end
