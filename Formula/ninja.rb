class Ninja < Formula
  desc "Small build system with a focus on speed (Intel slice for Tahoe)"
  homepage "https://ninja-build.org/"
  # 上游官方 ninja-mac.zip：单个 universal 二进制（含 x86_64 切片，
  # doubao-ime 同例），在 Intel 上原生运行。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/ninja-build/ninja/releases/download/v1.13.2/ninja-mac.zip"
  sha256 "c99048673aa765960a99cf10c6ddb9f1fad506099ff0a0e137ad8960a88f321b"
  license "Apache-2.0"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "44caf1ce672f7e09009b5738654b54164470ea9178e041e0f71389412f6bced3"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 ninja 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/ninja，
  # 不能同时安装。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：本体不足 1MB，留足余量
    required_mb = 256
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 ninja #{version}（Intel x86_64）"

    # 若已存在其他来源的 ninja，提前告知同名冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/ninja/*"].map { |keg| File.basename(keg) }
                                                      .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 ninja：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 ninja 同名，不能同时安装，请先卸载另一方：
        brew uninstall ninja
    EOS
  end

  def install
    # zip 内无顶层目录：单个 ninja 二进制直接在 CWD。
    bin.install "ninja"
  end

  def post_install
    ninja = bin/"ninja"

    # 1) 必须含 x86_64 切片（universal 二进制含 arm64+x86_64，防止误装纯 arm64 包）
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", ninja.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{ninja} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(ninja.to_s, "--version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "ninja #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      ninja 已安装为 Intel(x86_64) 原生二进制，直接取自上游官方发布包
      （universal 包的 x86_64 切片）。

      与 homebrew/core 的 ninja 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall ninja && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install ninja
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ninja --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/ninja")
  end
end
