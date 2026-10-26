class YtDlp < Formula
  desc "Feature-rich command-line audio/video downloader"
  homepage "https://github.com/yt-dlp/yt-dlp"
  # 上游官方 macOS 通用预编译单二进制（universal x86_64+arm64，otool 仅系统库，
  # 零 brew 依赖；此构建无补全参数，不硬凑补全文件；见 AGENTS.md 11.48）。
  # 文件名无版本但路径段是全版本（/download/2026.08.19/），brew 能正确扫出，
  # 故不写 version 行（写了判冗余；cmake 同例，先写后删）。
  url "https://github.com/yt-dlp/yt-dlp/releases/download/2026.10.21/yt-dlp_macos"
  sha256 "7a6fe71d7d680f1fb0ac18d4949873d77db2859e90017c0f44bd94b23be4ee40"
  license "Unlicense"


  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    bin.install "yt-dlp_macos" => "yt-dlp"
    # 裸二进制无执行位（curl/ brew 下载均 644），手动给（frida/scrcpy 同例）。
    chmod 0555, bin/"yt-dlp"

    # 拆箱校验（post_install 已废弃，校验挪进 install 尾部，走最终交付物）。
    arch = Utils.safe_popen_read("/usr/bin/file", "-b", (bin/"yt-dlp").to_s)
    odie "期望 x86_64，实际：#{arch}" unless arch.include?("x86_64")
    ver = Utils.safe_popen_read((bin/"yt-dlp").to_s, "--version").strip
    odie "yt-dlp --version 自检失败" if ver.blank?
    ohai "yt-dlp #{ver}（#{arch.strip}）"
  end

  def caveats
    <<~EOS
      合并/转码需要 ffmpeg：`brew install bemly/tahoe/ffmpeg`（本 tap 同样有瓶）。
      与 homebrew/core 的 yt-dlp 同名不能共存，先 `brew uninstall yt-dlp` 再装本版。
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/yt-dlp --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/yt-dlp")
  end
end
