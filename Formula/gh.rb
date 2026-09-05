class Gh < Formula
  desc "GitHub CLI (Intel x86_64 build for macOS Tahoe)"
  homepage "https://cli.github.com/"
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）
  url "https://github.com/cli/cli/releases/download/v2.100.0/gh_2.100.0_macOS_amd64.zip"
  sha256 "fcd7799e85eb575f3c7d2b1679bfbfedaefa1269d4bc7d096b51e10939b4812b"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "8b60f2163a279b6f0ffd9a72de2b2467235aa4edaa2e33d0380d53e05cd93076"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # Homebrew 官方不为 Tahoe 构建 x86_64 bottle，所以这里直接引用上游官方发布包。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 gh 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/gh，
  # 不能同时 link。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：gh 本体 42MB，展开后 man 页等共约 50MB，留足余量
    required_mb = 256
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 gh #{version}（Intel x86_64）"

    # 若已存在其他来源的 gh，提前告知 link 冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/gh/*"].map { |keg| File.basename(keg) }
                                                   .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 gh：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 gh 同名，安装后若未自动 link，请执行：
        brew unlink gh && brew link --overwrite #{full_name}
    EOS
  end

  def install
    # 实测：brew 解压 zip 后会自动下降进入其中唯一的顶层目录，
    # 因此 install 的 CWD 已经是 gh_<version>_macOS_amd64/。
    # 这里用 ** 通配，无论 brew 是否下降都能命中，避免硬编码目录名。
    bin.install Dir["**/bin/gh"].fetch(0)
    man1.install Dir["**/share/man/man1/*.1"]

    license = Dir["**/LICENSE"].first
    doc.install license if license
  end

  def post_install
    gh = bin/"gh"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", gh.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{gh} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 隔离属性无需处理：brew 在下载阶段已清掉 com.apple.quarantine
    #    （实测装完 xattr -l 为空；且文件是 0555，手动 xattr -d 反而会 EACCES）

    # 3) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(gh.to_s, "--version")
    unless version_out.include?("gh version #{version}")
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "gh #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      gh 已安装为 Intel(x86_64) 原生二进制，直接取自 GitHub 官方发布包。

      启用命令补全：
        bash     echo 'eval "$(#{opt_bin}/gh completion -s bash)"' >> ~/.bash_profile
        zsh      echo 'eval "$(#{opt_bin}/gh completion -s zsh)"' >> ~/.zshrc
        fish     #{opt_bin}/gh completion -s fish > ~/.config/fish/completions/gh.fish

      首次使用请先登录：
        gh auth login

      与 homebrew/core 的 gh 同名，二者不能同时 link。切换来源：
        用本 tap：brew unlink gh && brew link --overwrite #{full_name}
        用 core ：brew unlink #{full_name} && brew link gh
    EOS
  end

  test do
    assert_match "gh version #{version}", shell_output("#{bin}/gh --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/gh")
  end
end
