class Fish < Formula
  desc "User-friendly command-line shell (Intel build for macOS Tahoe)"
  homepage "https://fishshell.com/"
  # fish-shell 官方 .app.zip：内含完整 unix 树（base/ 即官方 install.sh
  # 要 ditto 到 /usr/local 的内容：bin/etc/share）。只取 base/ 装进 prefix，
  # 不装 .app 本体——shell 要的是稳定路径（/etc/shells + chsh），.app 内路径
  # 随版本变化且对 shell 无用。
  # base 内 fish 为 universal（arm64+x86_64），x86_64 切片原生运行
  # （universal 含 x86_64 即满足 Intel 要求，doubao-ime 同例）。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/fish-shell/fish-shell/releases/download/4.9.0/fish-4.9.0.app.zip"
  sha256 "ba3d066d7e75a0f04935000c8624cf5c80dce8677a7acd51dd51d6b8f3f43e11"
  license "GPL-2.0-only"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 cellar: :any_skip_relocation, tahoe: "835e0a08f56db3b46b35392cedb65a845f539b81458c874ceddefb92ee6f7a43"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 fish 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/fish，
  # 不能同时安装。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：解压后约 120MB，留足余量
    required_mb = 512
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 fish #{version}（Intel x86_64）"

    # 若已存在其他来源的 fish，提前告知同名冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/fish/*"].map { |keg| File.basename(keg) }
                                                     .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 fish：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 fish 同名，不能同时安装，请先卸载另一方：
        brew uninstall fish
    EOS
  end

  def install
    # 实测：brew 解压后会下降进 zip 内唯一的顶层目录（fish-4.9.0.app/），
    # 故用 ** 通配定位 base/，无论是否下降都能命中（见 11.1）。
    # base/ 即官方 install.sh 要 ditto 的 unix 树，原样装进 prefix；
    # 例外有二：① etc/fish 下 completions/functions/conf.d 三个子目录上游就是
    # 空占位（无文件），整树装会触发 brew 空数组告警——只装 config.fish，
    # 空目录用 mkpath 原样建出（与上游 ditto 落盘布局一致）；
    # ② fish_indent/fish_key_reader 在 4.9.0 包里是纯 arm64（无 x86_64 切片），
    # 在 Intel 上根本跑不起来——只装主 fish（universal，x86_64 切片原生），
    # 不装这两个坏件（man 页保留，等上游修好再加回；见 11.19）。
    base = Dir["**/base"].fetch(0)
    bin.install "#{base}/usr/local/bin/fish"
    (etc/"fish").install "#{base}/usr/local/etc/fish/config.fish"
    %w[functions completions conf.d].each { |d| (etc/"fish"/d).mkpath }
    share.install Dir["#{base}/usr/local/share/*"]
  end

  def post_install
    fish = bin/"fish"

    # 1) 必须含 x86_64 切片（universal 二进制含 arm64+x86_64，防止误装纯 arm64 包）
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", fish.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{fish} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错；
    #    中文 locale 下输出"fish，版本 4.9.0"，故只比对版本号本身）
    version_out = Utils.safe_popen_read(fish.to_s, "--version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "fish #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      fish 已安装为 Intel(x86_64) 原生二进制，直接取自 fish-shell 官方 .app.zip
      内含的 unix 树（与官方 install.sh 落盘内容一致）。

      注意：4.9.0 包里的 fish_indent/fish_key_reader 是纯 arm64（上游打包问题），
      在 Intel 上无法运行，本公式暂不安装这两个（主 fish 不受影响）。

      设为默认 shell（brew 不能代写 /etc/shells，需手动执行）：
        sudo sh -c 'echo #{opt_bin}/fish >> /etc/shells'
        chsh -s #{opt_bin}/fish

      与 homebrew/core 的 fish 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall fish && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install fish
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/fish --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/fish")
  end
end
