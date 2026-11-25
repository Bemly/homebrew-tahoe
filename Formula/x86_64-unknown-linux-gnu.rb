class X8664UnknownLinuxGnu < Formula
  desc "GCC cross toolchain for x86_64 Linux (Intel host)"
  homepage "https://github.com/messense/homebrew-macos-cross-toolchains"
  # 上游 messense/homebrew-macos-cross-toolchains 的预编译工具链，只留 Intel host 段。
  # 版本号由 brew 从 URL 路径段 v<ver>/ 扫描得出，不重复声明 version（audit 判冗余，见 AGENTS.md §11.1）。
  url "https://github.com/messense/homebrew-macos-cross-toolchains/releases/download/v15.2.0/x86_64-unknown-linux-gnu-x86_64-darwin.tar.gz"
  sha256 "d82e9eb461939fe079b47c0a55c9c4130310507eeb55e60f076e65f3d4c6cb1e"
  license "GPL-3.0-or-later" => { with: "GCC-exception-3.1" }

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "d796bb30ab27450389ec28603de4736e493e3667b2dc6a2b456f824b2797aeca"
    sha256 tahoe: "ddf8a9c2960390dfa97f1f14d012edeeb8cb69a6c8d70a338b5c2ae6774b7411"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # 运行时依赖走本源同名瓶（guile/xz/zstd），用户端零源码编译。
  depends_on arch: :x86_64
  depends_on "bemly/tahoe/bdw-gc"
  depends_on "bemly/tahoe/python@3.14"
  depends_on "bemly/tahoe/xz"
  depends_on "bemly/tahoe/zstd"
  depends_on "bemly/tahoe/guile"
  depends_on macos: :tahoe

  def install
    # 上游 tar.gz 内是单一顶层目录 x86_64-unknown-linux-gnu/，brew 会自动下降进入；
    # 用 ./* 通配兼容下降与否（照抄上游 install）。
    (prefix/"toolchain").install Dir["./*"]
    Dir.glob(prefix/"toolchain/bin/*") { |file| bin.install_symlink file }

    # 预编译 gdb 硬编码链接了 core 的 python@3.14 与 xz，重指到本源同名瓶避免拖入 core 依赖
    gdb = prefix/"toolchain/bin/x86_64-unknown-linux-gnu-gdb"
    system "install_name_tool",
           "-change", "/usr/local/opt/python@3.14/Frameworks/Python.framework/Versions/3.14/Python",
                      "#{Formula["bemly/tahoe/python@3.14"].opt_prefix}/Frameworks/Python.framework/Versions/3.14/Python",
           "-change", "/usr/local/opt/xz/lib/liblzma.5.dylib",
                      "#{Formula["bemly/tahoe/xz"].opt_lib}/liblzma.5.dylib",
           gdb.to_s

    # 校验放在 install 尾部：brew 6 已废弃 def post_install（见 AGENTS.md §11.1），
    # 新公式用声明式 post_install_steps 才过 style，此处直接在 install 内断言。
    gcc = bin/"x86_64-unknown-linux-gnu-gcc"
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

    ohai "x86_64-unknown-linux-gnu #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      x86_64-unknown-linux-gnu 交叉工具链已安装为 Intel(x86_64) 原生二进制。
      配套 Rust 使用：
        export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc
      另见上游说明：
        https://github.com/messense/homebrew-macos-cross-toolchains
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/x86_64-unknown-linux-gnu-gcc --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/x86_64-unknown-linux-gnu-gcc")
  end
end
