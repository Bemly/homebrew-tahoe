class Aarch64UnknownLinuxGnu < Formula
  desc "GCC cross toolchain for aarch64 Linux (Intel host)"
  homepage "https://github.com/messense/homebrew-macos-cross-toolchains"
  # 上游 messense/homebrew-macos-cross-toolchains 的预编译工具链，只留 Intel host 段。
  # 版本号由 brew 从 URL 路径段 v<ver>/ 扫描得出，不重复声明 version（audit 判冗余，见 11.3）。
  url "https://github.com/messense/homebrew-macos-cross-toolchains/releases/download/v15.2.0/aarch64-unknown-linux-gnu-x86_64-darwin.tar.gz"
  sha256 "7fa485313b7049d57c5de56bf876d5c4648ebfd736f86a8f4739596218523127"
  license "GPL-3.0-or-later" => { with: "GCC-exception-3.1" }

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # 运行时依赖照抄上游（裸名留 core，枢纽不自瓶，见 AGENTS.md 6 节）：
  # bdw-gc/guile/python@3.14 在 core 无 x86_64_tahoe 瓶，首次安装由 core 源码构建；
  # zstd 有 tahoe 瓶秒装。gdb 另链 xz（经 python 传递，无需显式声明）。
  depends_on arch: :x86_64
  depends_on "bdw-gc"
  depends_on "guile"
  depends_on macos: :tahoe
  depends_on "python@3.14"
  depends_on "zstd"

  def pre_install
    # 磁盘空间检查：压缩包 203MB，展开后约 1GB，留足余量
    required_mb = 2048
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 aarch64-unknown-linux-gnu #{version}（Intel x86_64）"
  end

  def install
    # 上游 tar.gz 内是单一顶层目录 aarch64-unknown-linux-gnu/，brew 会自动下降进入；
    # 用 ./* 通配兼容下降与否（照抄上游 install）。
    (prefix/"toolchain").install Dir["./*"]
    Dir.glob(prefix/"toolchain/bin/*") { |file| bin.install_symlink file }

    # 校验放在 install 尾部：brew 6 已废弃 def post_install（见 11.37），
    # 新公式用声明式 post_install_steps 才过 style，此处直接在 install 内断言。
    gcc = bin/"aarch64-unknown-linux-gnu-gcc"
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", gcc.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{gcc} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    version_out = Utils.safe_popen_read(gcc.to_s, "--version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "aarch64-unknown-linux-gnu #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      aarch64-unknown-linux-gnu 交叉工具链已安装为 Intel(x86_64) 原生二进制。
      配套 Rust 使用：
        export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-unknown-linux-gnu-gcc
      另见上游说明：
        https://github.com/messense/homebrew-macos-cross-toolchains
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/aarch64-unknown-linux-gnu-gcc --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/aarch64-unknown-linux-gnu-gcc")
  end
end
