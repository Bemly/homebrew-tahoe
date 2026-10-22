class Zig < Formula
  desc "General-purpose programming language and toolchain (Intel host)"
  homepage "https://ziglang.org/"
  # 上游 ziglang.org 的 macOS x86_64 预编译（thin x86_64，otool 仅系统库，零 brew 依赖）。
  # 只收 Intel host 段（x86_64-macos），ARM 段不收；与 core 同名（core 无 x86_64_tahoe 瓶，只能源码编）。
  url "https://ziglang.org/download/0.17.0/zig-x86_64-macos-0.17.0.tar.xz"
  sha256 "4f9a1c5269aa17ebda5e6d3c2b89d6cbf36f7d2b22a0306e9ab98f25f95529c6"
  license "MIT"

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def pre_install
    # 磁盘空间检查：压缩包约 59MB，展开后约 300MB，留足余量
    required_mb = 1024
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 zig #{version}（Intel x86_64 host）"
  end

  def install
    # 上游 tar.xz 内是单一顶层目录 zig-x86_64-macos-<ver>/，brew 会自动下降进入；
    # 用 ** 通配兼容下降与否。布局：zig 二进制 + lib/（与二进制相对位置固定，bin/zig 对 prefix/lib）。
    bin.install Dir["**/zig"].fetch(0)
    prefix.install Dir["**/lib"].fetch(0)

    license = Dir["**/LICENSE"].first
    doc.install license if license

    # 校验放在 install 尾部：brew 6 已废弃 def post_install（见 11.37）。
    zig = bin/"zig"
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", zig.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{zig} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    version_out = Utils.safe_popen_read(zig.to_s, "version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "zig #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      zig 已安装为 Intel(x86_64) 原生，直接取上游 macOS x86_64 预编译。
      与 homebrew/core 的 zig 同名，二者不能同时 link。切换来源：
        用本 tap：brew unlink zig && brew link --overwrite #{full_name}
        用 core ：brew unlink #{full_name} && brew link zig
      交叉到 Linux/Windows 可直接用 zig cc（自带 sysroot，无需另装 -dev 头）：
        zig cc -target x86_64-linux-gnu
        zig cc -target aarch64-linux-gnu
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/zig version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/zig")
  end
end
