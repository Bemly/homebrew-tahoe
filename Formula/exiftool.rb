class Exiftool < Formula
  desc "Perl lib for reading and writing EXIF metadata (Intel x86_64, macOS Tahoe)"
  homepage "https://exiftool.org"
  # 上游官方纯 Perl 发行包 Image-ExifTool-<ver>.tar.gz：无需编译，直接拆文件安装。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余，见 11.3）。
  # url 与 homebrew/core 公式一致（SourceForge）；CPAN 作 HTTP mirror（同一 tarball、
  # 同一 sha256），本机实测 SourceForge 的 dl 跳转偶发不可达，CPAN 可兜底（见 11.55）。
  # watcher 走 brew 全量式：url / sha256 直取 formulae.brew.sh 的 urls.stable，
  # 镜像行按版本子串同步改写（见 updater/exiftool.swift）。
  url "https://downloads.sourceforge.net/project/exiftool/Image-ExifTool-13.55.tar.gz"
  mirror "https://cpan.metacpan.org/authors/id/E/EX/EXIFTOOL/Image-ExifTool-13.55.tar.gz"
  sha256 "5f4c81d34ad406538c2871ad72dbfceb5d9b412b2f16cbbeb4d712d270846667"
  license any_of: ["Artistic-1.0-Perl", "GPL-1.0-or-later"]

  # bottle do 块不要手填：由 bottle.yml 制瓶后自动写回（见 AGENTS.md 4/8.5）。

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的软件。
  # exiftool 是纯 Perl 脚本（架构无关），门槛仍按 tap 约定强制保留。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  uses_from_macos "perl"

  def pre_install
    # 磁盘空间检查：源码包约 7.4MB、装完约 20MB，留足余量
    required_mb = 256
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 exiftool #{version}（纯 Perl，Intel x86_64）"
  end

  def install
    # 纯 Perl：不跑 Makefile.PL、不编译。exiftool 脚本的 BEGIN 块按自身所在目录
    # 找同级的 lib/ 并 unshift @INC，所以脚本与 lib/ 必须一起放进 libexec，
    # 再用 wrapper 暴露到 bin（core 公式同款 write_env_script）。
    libexec.install "exiftool", "lib"
    doc.install Dir["html/*"]
    (bin/"exiftool").write_env_script libexec/"exiftool", PERL5LIB: libexec/"lib"

    # 版本自检：脚本没有 Mach-O 架构可校验（chisel/yt-dlp 的 file(1) 检查不适用），
    # x86_64 + Tahoe 由顶部 depends_on 硬性保证。
    ver = Utils.safe_popen_read((libexec/"exiftool").to_s, "-ver").strip
    opoo "版本自检未通过：期望 #{version}，实际 #{ver}" if ver != version.to_s
    ohai "exiftool #{ver} 安装完成（纯 Perl，无编译）"
  end

  def caveats
    <<~EOS
      exiftool 是纯 Perl 程序（Image::ExifTool），本公式直接取上游官方 tar.gz，
      不编译、也不安装 core 版那套 brotli/xz + CPAN XS 模块（在 Intel Tahoe 上
      它们没有瓶，会拖出一整串源码编译）。常规 EXIF/元数据读写不受影响；
      JXL BrotliEXIF 等需要可选模块的功能请改用 core 版。

      与 homebrew/core 的 exiftool 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/exiftool，
      不能同时安装。如已装 core 版，请先卸载：
        brew uninstall exiftool

      基本用法：
        exiftool photo.jpg
        exiftool -Artist="bemly" photo.jpg
        exiftool -ver
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/exiftool -ver")
    test_image = test_fixtures("test.jpg")
    assert_match %r{MIME Type\s+: image/jpeg},
                 shell_output("#{bin}/exiftool #{test_image}")
  end
end
