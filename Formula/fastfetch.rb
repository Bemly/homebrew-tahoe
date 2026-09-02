class Fastfetch < Formula
  desc "Neofetch-like system info tool (Intel x86_64 for macOS Tahoe)"
  homepage "https://github.com/fastfetch-cli/fastfetch"
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）
  url "https://github.com/fastfetch-cli/fastfetch/releases/download/2.68.1/fastfetch-macos-amd64.tar.gz"
  sha256 "1e9a6ba7474a41b3cc2bb1b923afcf40c749c25bd17dc1e62b64464e7445a534"
  license "MIT"

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # Homebrew 官方不为 Tahoe 构建 x86_64 bottle，这里直接引用上游官方发布包。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 上游 tar.gz 解压后是单一顶层目录 fastfetch-macos-amd64/usr/...，
  # brew 会自动下降进入该目录，因此下面用 ** 通配、不硬编码顶层目录名。
  def install
    bin.install Dir["**/usr/bin/fastfetch"].fetch(0)
    # flashfetch 是 fastfetch 的 neofetch 风格别名二进制，一并安装（若存在）
    flash = Dir["**/usr/bin/flashfetch"].first
    bin.install flash if flash

    # presets：fastfetch 默认从可执行文件同级 ../share/fastfetch/presets 读取
    presets = Dir["**/usr/share/fastfetch/presets"].first
    (share/"fastfetch").install presets if presets

    man1.install Dir["**/usr/share/man/man1/*.1"]
    bc = Dir["**/usr/share/bash-completion/completions/fastfetch"].first
    bash_completion.install bc if bc
    zc = Dir["**/usr/share/zsh/site-functions/_fastfetch"].first
    zsh_completion.install zc if zc
    fc = Dir["**/usr/share/fish/vendor_completions.d/fastfetch.fish"].first
    fish_completion.install fc if fc
    license = Dir["**/usr/share/licenses/fastfetch/LICENSE"].first
    doc.install license if license
  end

  def post_install
    ff = bin/"fastfetch"

    # 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", ff.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{ff} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(ff.to_s, "--version")
    unless version_out.include?("fastfetch #{version}")
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "fastfetch #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      fastfetch 已安装为 Intel(x86_64) 原生二进制，直接取自 GitHub 官方发布包。

      常用：
        fastfetch            # 默认输出
        fastfetch -c neofetch   # 用内置 neofetch 风格预设

      与 homebrew/core 的 fastfetch 同名，二者不能同时 link。切换来源：
        用本 tap：brew unlink fastfetch && brew link --overwrite #{full_name}
        用 core ：brew unlink #{full_name} && brew link fastfetch
    EOS
  end

  test do
    assert_match "fastfetch", shell_output("#{bin}/fastfetch --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/fastfetch")
  end
end
