class Sst < Formula
  desc "Build full-stack apps on your own infrastructure"
  homepage "https://sst.dev"
  # 取自 anomalyco/homebrew-tap 的 sst.rb（GoReleaser 产物，只留 Intel mac 段）。
  # 上游是 anomalyco/sst 的官方发布包；源文件 desc/homepage 为空，此处按上游补齐。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余，见 11.3）。
  url "https://github.com/anomalyco/sst/releases/download/v4.17.1/sst-mac-x86_64.tar.gz"
  sha256 "9244910c50db88140f12579ce94923d2f0eae5f22a27bc884b2e1d7d245dcbf5"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 cellar: :any_skip_relocation, tahoe: "162710ad8ab13cf6121a841f14f544021aeb99cf7678961f70ef67fa20115c40"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def pre_install
    # 磁盘空间检查：sst 本体较小，留足余量
    required_mb = 256
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 sst #{version}（Intel x86_64）"
  end

  def install
    # 上游 tar.gz 内是 sst 二进制 + LICENSE/README（无单一顶层目录），
    # 用 ** 通配兼容 brew 是否下降。
    bin.install Dir["**/sst"].fetch(0)

    license = Dir["**/LICENSE"].first
    doc.install license if license
  end

  def post_install
    st = bin/"sst"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", st.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{st} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）。
    #    注意 sst 不支持 `--version`（裸跑打帮助且 exit 1），版本用 `sst version` 子命令取。
    version_out = Utils.safe_popen_read(st.to_s, "version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "sst #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      sst 已安装为 Intel(x86_64) 原生二进制，取自 anomalyco/sst 的官方发布包。
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/sst version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/sst")
  end
end
