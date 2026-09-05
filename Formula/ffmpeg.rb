class Ffmpeg < Formula
  desc "Play, record, convert, and stream audio and video (Intel static build)"
  homepage "https://ffmpeg.org/"
  # evermeet 静态发行版：zip 内为单个 x86_64 二进制（无顶层目录，不触发自动下降）。
  # 不用 getrelease 的 7z：brew 解 7z 需要 p7zip，而 p7zip 在 core 里没有
  # x86_64_tahoe 瓶（用户要从源码编译）；zip 是 brew 原生格式，零依赖。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://evermeet.cx/ffmpeg/ffmpeg-9.0.1.zip"
  sha256 "8a8c9e549983409fe6604b9aa665648b7a5def9407fe814c39c8b2ea7f64a48f"
  license "GPL-3.0-or-later"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "cda0a60b52564cd45541dbd5e9957f65b239a47f93ce5bc2abaec8af3864d098"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 ffmpeg 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/ffmpeg，
  # 不能同时安装。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：本体约 80MB，留足余量
    required_mb = 512
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 ffmpeg #{version}（Intel x86_64 静态版）"

    # 若已存在其他来源的 ffmpeg，提前告知同名冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/ffmpeg/*"].map { |keg| File.basename(keg) }
                                                       .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 ffmpeg：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 ffmpeg 同名，不能同时安装，请先卸载另一方：
        brew uninstall ffmpeg
    EOS
  end

  def install
    # 实测：zip 内无顶层目录，二进制直接解压在 CWD（与 mufetch 同构）。
    bin.install "ffmpeg"
  end

  def post_install
    ffmpeg = bin/"ffmpeg"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", ffmpeg.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{ffmpeg} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错；
    #    evermeet 构建带 -tessus 后缀，如 ffmpeg version 9.0.1-tessus）
    version_out = Utils.safe_popen_read(ffmpeg.to_s, "-version")
    unless version_out.include?("ffmpeg version #{version}")
      opoo "版本自检未通过：期望 ffmpeg version #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "ffmpeg #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      ffmpeg 已安装为 Intel(x86_64) 静态二进制，直接取自 evermeet 官方发行版
      （GPL 构建，含 x264/x265 等编码器；GPG 签名已在收录时验证，密钥见
      https://evermeet.cx/ffmpeg/）。

      与 homebrew/core 的 ffmpeg 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall ffmpeg && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install ffmpeg
    EOS
  end

  test do
    assert_match "ffmpeg version #{version}", shell_output("#{bin}/ffmpeg -version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/ffmpeg")
  end
end
