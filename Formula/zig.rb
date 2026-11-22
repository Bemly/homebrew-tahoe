class Zig < Formula
  desc "General-purpose programming language and toolchain (Intel host)"
  homepage "https://ziglang.org/"
  # 上游 ziglang.org 的 macOS x86_64 预编译（thin x86_64，otool 仅系统库，零 brew 依赖）。
  # 只收 Intel host 段（x86_64-macos），ARM 段不收；与 core 同名（core 无 x86_64_tahoe 瓶，只能源码编）。
  url "https://ziglang.org/download/0.17.1/zig-x86_64-macos-0.17.1.tar.xz"
  sha256 "9af07b20319fbd0c92ee46ad23e81d6a782b1aaea2cfb8dcbff35f1d2c7ddbb7"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "059b181b28cc29c4e2553c3bc9c84d0477c7d262cd596e54e0c20a8e18140131"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # 上游 tar.xz 内是单一顶层目录 zig-x86_64-macos-<ver>/，brew 会自动下降进入；
    # 二进制必须只取文件：Dir["**/zig"] 会先命中 lib/std/zig/ 目录（fetch(0) 即装错目录，
    # 制瓶 39741781774 实锤），故用 File.file? 过滤。
    # 布局：zig 二进制 + lib/（与二进制相对位置固定，bin/zig 对 prefix/lib）。
    bin.install Dir["**/zig"].select { |f| File.file?(f) }.fetch(0)
    prefix.install Dir["**/lib"].select { |f| File.directory?(f) }.fetch(0)

    license = Dir["**/LICENSE"].first
    doc.install license if license

    # 校验放在 install 尾部：brew 6 已废弃 def post_install（见 AGENTS.md §11.1）。
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
