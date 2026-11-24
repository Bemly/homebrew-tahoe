class Ffplay < Formula
  desc "Media player using FFmpeg libraries (Intel static build)"
  homepage "https://ffmpeg.org/"
  # evermeet 静态发行版：zip 内为单个 x86_64 二进制（无顶层目录，不触发自动下降）。
  # 不用 getrelease 的 7z：brew 解 7z 需要 p7zip，而 p7zip 在 core 里没有
  # x86_64_tahoe 瓶（用户要从源码编译）；zip 是 brew 原生格式，零依赖。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://evermeet.cx/ffmpeg/ffplay-9.1.zip"
  sha256 "b5916ccd0058834e8de7f069ecb51258a57088e1a3b518909c0d2a28f1a12bca"
  license "GPL-3.0-or-later"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "21813142a65c649ccc7c4a3fb8ac5578a2134451d86745d4fc11babbfd8cd077"
    sha256 cellar: :any_skip_relocation, tahoe: "21afa28776ec8c0bbbbb1ba68e5599f417a9c4c457bc750ad819c3ee0030ee40"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # 实测：zip 内无顶层目录，二进制直接解压在 CWD（与 mufetch 同构）。
    bin.install "ffplay"

    # 安装后架构与版本自检（放在 install 尾部，brew 6+ 已废弃 def post_install）
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
