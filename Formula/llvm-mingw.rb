class LlvmMingw < Formula
  desc "LLVM/Clang based mingw-w64 toolchain for Windows (Intel host)"
  homepage "https://github.com/mstorsjo/llvm-mingw"
  # 上游 mstorsjo/llvm-mingw 的 macOS universal 预编译（x86_64+arm64 双切片，Intel 走 x86_64 切片）。
  # 只收 Intel host 段：本机 Intel Tahoex64 原生运行，target 覆盖 x86_64/aarch64-windows（winX64/winA64）。
  # 日期版本号（20261020）无点分段，brew 可扫出故不写 version 行；UpdaterCore 靠日期回退解析（见头注）。
  url "https://github.com/mstorsjo/llvm-mingw/releases/download/20261020/llvm-mingw-20261020-ucrt-macos-universal.tar.xz"
  sha256 "e9c13e4ede38e715003ffc674d4d00a1088df8235439d1f0c16188ff0704c17e"
  license "Apache-2.0" => { with: "LLVM-exception" }

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def pre_install
    # 磁盘空间检查：压缩包约 124MB，展开后约 1GB，留足余量
    required_mb = 2048
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 llvm-mingw #{version}（Intel x86_64 host）"
  end

  def install
    # 上游 tar.xz 内是单一顶层目录 llvm-mingw-<ver>-ucrt-macos-universal/，brew 会自动下降进入；
    # 用 ./* 通配兼容下降与否（照抄 messense 交叉工具链 install）。
    # wrapper 脚本自带 readlink 解析 symlink，bin.install_symlink 安全。
    (prefix/"toolchain").install Dir["./*"]
    Dir.glob(prefix/"toolchain/bin/*") { |file| bin.install_symlink file }

    # 校验放在 install 尾部：brew 6 已废弃 def post_install（见 11.37）。
    clang = bin/"clang"
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", clang.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{clang} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    version_out = Utils.safe_popen_read(clang.to_s, "--version")
    unless version_out.include?("clang")
      opoo "版本自检未通过：#{version_out.lines.first.to_s.strip}"
    end

    ohai "llvm-mingw #{version} 安装完成（x86_64 host universal）"
  end

  def caveats
    <<~EOS
      llvm-mingw 交叉工具链已安装为 Intel(x86_64) host 原生（universal 含 x86_64 切片）。
      配套 Rust 使用（以 xwin 替代链接器时二选一）：
        export CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER=x86_64-w64-mingw32-gcc
        export CARGO_TARGET_AARCH64_PC_WINDOWS_MSVC_LINKER=aarch64-w64-mingw32-gcc
      注意：target triple 仍是 *-pc-windows-msvc（Rust），实际 CC 走 mingw wrapper；
      如需严格 MSVC SDK 则改走 xwin（另装，不进本 tap）。
    EOS
  end

  test do
    assert_match "clang", shell_output("#{bin}/clang --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/clang")
  end
end
