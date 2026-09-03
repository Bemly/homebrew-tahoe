class Ffplay < Formula
  desc "Media player using FFmpeg libraries (Intel static build)"
  homepage "https://ffmpeg.org/"
  # evermeet 静态发行版：zip 内为单个 x86_64 二进制（无顶层目录，不触发自动下降）。
  # 不用 getrelease 的 7z：brew 解 7z 需要 p7zip，而 p7zip 在 core 里没有
  # x86_64_tahoe 瓶（用户要从源码编译）；zip 是 brew 原生格式，零依赖。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://evermeet.cx/ffmpeg/ffplay-9.0.1.zip"
  sha256 "1557feb3e93d6b9e66d3a0556aefe8f081e554ea271930582d734d0ed6aefc98"
  license "GPL-3.0-or-later"

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

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

    ohai "安装 ffplay #{version}（Intel x86_64 静态版）"
  end

  def install
    # 实测：zip 内无顶层目录，二进制直接解压在 CWD（与 mufetch 同构）。
    bin.install "ffplay"
  end

  def post_install
    ffplay = bin/"ffplay"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", ffplay.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{ffplay} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错；
    #    evermeet 构建带 -tessus 后缀，如 ffplay version 9.0.1-tessus）
    version_out = Utils.safe_popen_read(ffplay.to_s, "-version")
    unless version_out.include?("ffplay version #{version}")
      opoo "版本自检未通过：期望 ffplay version #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "ffplay #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      ffplay 已安装为 Intel(x86_64) 静态二进制，直接取自 evermeet 官方发行版
      （与本 tap 的 ffmpeg 同版本配套；GPG 签名已在收录时验证，密钥见
      https://evermeet.cx/ffmpeg/）。

      ffplay 需要图形界面播放；无显示环境下可用 `ffplay -version` 验证安装。
    EOS
  end

  test do
    assert_match "ffplay version #{version}", shell_output("#{bin}/ffplay -version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/ffplay")
  end
end
