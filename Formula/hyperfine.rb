class Hyperfine < Formula
  desc "Command-line benchmarking tool (Intel x86_64 for macOS Tahoe)"
  homepage "https://github.com/sharkdp/hyperfine"
  # 上游官方 x86_64-apple-darwin tar 包（单顶层目录，brew 会下降进入）。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/sharkdp/hyperfine/releases/download/v1.20.0/hyperfine-v1.20.0-x86_64-apple-darwin.tar.gz"
  sha256 "f58d0b90993fadfa122a351428c469ce24afef3865f027f0e6e86f0830d088f1"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 cellar: :any_skip_relocation, tahoe: "f06f971f7a56111f8a27e7c5ce16f7e572fdff02c8eadabd5e39f92fc5542be8"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 hyperfine 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/hyperfine，
  # 不能同时安装。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：本体约 2MB，留足余量
    required_mb = 256
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 hyperfine #{version}（Intel x86_64）"

    # 若已存在其他来源的 hyperfine，提前告知同名冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/hyperfine/*"].map { |keg| File.basename(keg) }
                                                          .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 hyperfine：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 hyperfine 同名，不能同时安装，请先卸载另一方：
        brew uninstall hyperfine
    EOS
  end

  def install
    # 实测：brew 解压后会下降进 tar 内唯一的顶层目录，
    # 故用 ** 通配定位二进制与补全文件（见 11.1）。
    bin.install Dir["**/hyperfine"].fetch(0)
    man1.install Dir["**/hyperfine.1"].fetch(0)
    bash_completion.install Dir["**/autocomplete/hyperfine.bash"].fetch(0) => "hyperfine"
    zsh_completion.install Dir["**/autocomplete/_hyperfine"].fetch(0)
    fish_completion.install Dir["**/autocomplete/hyperfine.fish"].fetch(0)
  end

  def post_install
    hyperfine = bin/"hyperfine"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", hyperfine.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{hyperfine} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(hyperfine.to_s, "--version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "hyperfine #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      hyperfine 已安装为 Intel(x86_64) 原生二进制，直接取自上游官方发布包
      （Phase 4 命令级重复基准用）。

      与 homebrew/core 的 hyperfine 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall hyperfine && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install hyperfine
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/hyperfine --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/hyperfine")
    # 真跑一次基准：证明可用（sleep 0.01 跑 3 次，不联网；输出格式随版本变，
    # 只断言 Benchmark 标题行这种稳定锚点，不锁 "Mean" 字样——1.20 已改成
    # "Time (mean ± σ)"，锁字样必红）
    assert_match "Benchmark 1", shell_output("#{bin}/hyperfine --runs 3 'sleep 0.01'")
  end
end
