class Opencode < Formula
  desc "AI coding agent built for the terminal"
  homepage "https://opencode.ai"
  # 取自 anomalyco/homebrew-tap 的 opencode.rb（GoReleaser 产物，只留 Intel mac 段）。
  # 上游是 anomalyco/opencode fork 的官方发布包，非 homebrew/core 的 npm 版。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余，见 11.3）。
  # 实测本系列 URL（v 前缀 + darwin-x64/mac-x86_64 尾部）能正确扫出版本，与 node 的 x64 坑不同。
  url "https://github.com/anomalyco/opencode/releases/download/v1.18.27/opencode-darwin-x64.zip"
  sha256 "e182eab3a6bf095ff773d303bbc7938d3551a636eab00625b599ad6383fabd88"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 cellar: :any_skip_relocation, tahoe: "ee6ad4657705928ac2909c62478fb0f5060a0077526a7db54dd87844aa7e3006"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # ripgrep 走本 tap 的 GHCR 瓶（core 的 ripgrep 无 x86_64_tahoe 瓶，会回退源码编译）。
  depends_on arch: :x86_64
  depends_on "bemly/tahoe-intel/ripgrep"
  depends_on macos: :tahoe

  # 与 homebrew/core 的 opencode 同名（core 是 npm 版），二者共用 Cellar/opencode，
  # 不能同时安装。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：opencode 本体约 150MB，留足余量
    required_mb = 512
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 opencode #{version}（Intel x86_64）"

    # 若已存在其他来源的 opencode，提前告知同名冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/opencode/*"].map { |keg| File.basename(keg) }
                                                         .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 opencode：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 opencode 同名，不能同时安装，请先卸载另一方：
        brew uninstall opencode
    EOS
  end

  def install
    # 上游 zip 内是单个 opencode 二进制（无顶层目录），用 ** 通配兼容 brew 是否下降。
    bin.install Dir["**/opencode"].fetch(0)
  end

  def post_install
    oc = bin/"opencode"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", oc.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{oc} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(oc.to_s, "--version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "opencode #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      opencode 已安装为 Intel(x86_64) 原生二进制，取自 anomalyco/opencode 的官方发布包。

      与 homebrew/core 的 opencode（npm 版）同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall opencode && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install opencode
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/opencode --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/opencode")
  end
end
