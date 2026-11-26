class YtDlp < Formula
  desc "Feature-rich command-line audio/video downloader"
  homepage "https://github.com/yt-dlp/yt-dlp"
  # 上游官方 macOS 通用预编译单二进制（universal x86_64+arm64，otool 仅系统库，
  # 零 brew 依赖；此构建无补全参数，不硬凑补全文件；见 AGENTS.md §11.3）。
  # 文件名无版本但路径段是全版本（/download/2026.08.19/），brew 能正确扫出，
  # 故不写 version 行（写了判冗余；cmake 同例，先写后删）。
  url "https://github.com/yt-dlp/yt-dlp/releases/download/2026.11.23/yt-dlp_macos"
  sha256 "57654854886d0398a798895aadf5173e2749fbb5e249b9f3728022ab376e11fb"
  license "Unlicense"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "7923ea14e58ea3939e4ad1a71ac6e75e8a2247aea250ec99aa41e4b3cd61394a"
    sha256 cellar: :any_skip_relocation, tahoe: "070bd7a4298643ef971641a63f60d5cbb59d6218118a6c57360cda806cf09a5c"
  end

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
