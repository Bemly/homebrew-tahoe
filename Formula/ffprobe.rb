class Ffprobe < Formula
  desc "Multimedia stream analyzer (Intel static build for macOS Tahoe)"
  homepage "https://ffmpeg.org/"
  # evermeet 静态发行版：zip 内为单个 x86_64 二进制（无顶层目录，不触发自动下降）。
  # 不用 getrelease 的 7z：brew 解 7z 需要 p7zip，而 p7zip 在 core 里没有
  # x86_64_tahoe 瓶（用户要从源码编译）；zip 是 brew 原生格式，零依赖。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://evermeet.cx/ffmpeg/ffprobe-9.1.zip"
  sha256 "fe81b028c213d6387a5c6b315692b3ceddcd31eb6dae55bbcae257a862573918"
  license "GPL-3.0-or-later"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "d95c40a26c9a51768b098cf9504f64e8b41444ca9e62502998cd4e9029e5f296"
    sha256 cellar: :any_skip_relocation, tahoe: "dd8edf746a595e8bd7f4a47e7b0963d5663b0c6f2c520470b3213bd0fa95c0f8"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # 实测：zip 内无顶层目录，二进制直接解压在 CWD（与 mufetch 同构）。
    bin.install "ffprobe"

    # 安装后架构与版本自检（放在 install 尾部，brew 6+ 已废弃 def post_install）
    ffprobe = bin/"ffprobe"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", ffprobe.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{ffprobe} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错；
    #    evermeet 构建带 -tessus 后缀，如 ffprobe version 9.0.1-tessus）
    version_out = Utils.safe_popen_read(ffprobe.to_s, "-version")
    unless version_out.include?("ffprobe version #{version}")
      opoo "版本自检未通过：期望 ffprobe version #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "ffprobe #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      ffprobe 已安装为 Intel(x86_64) 静态二进制，直接取自 evermeet 官方发行版
      （与本 tap 的 ffmpeg 同版本配套；GPG 签名已在收录时验证，密钥见
      https://evermeet.cx/ffmpeg/）。
    EOS
  end

  test do
    assert_match "ffprobe version #{version}", shell_output("#{bin}/ffprobe -version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/ffprobe")
  end
end
