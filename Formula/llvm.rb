class Llvm < Formula
  desc "Next-gen compiler infrastructure (Intel x86_64 prebuilt for macOS Tahoe)"
  homepage "https://llvm.org/"
  # 上游最后一个 Intel mac 预编译（20+ 仅 macOS-ARM64，18.x 同样只有 ARM64）。
  # 版本锁死 19.1.7，不跟检查器（无 updater/llvm.swift，ffserver 同例）：
  # 本仓要的是 bindgen 0.73 运行时的 libclang 9+（16~23 都吃），19 够用且带全后端；
  # 追 core stable（23.x）就得走源码代编译（PGO 三阶段 6 小时起步即超时，见 11.51）。
  # 版本号由 brew 从 URL 文件名扫描得出，不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/llvm/llvm-project/releases/download/llvmorg-19.1.7/LLVM-19.1.7-macOS-X64.tar.xz"
  version "19.1.7"
  sha256 "49405e75fbe7ad6f8139a33f59ec8c5112b75b3027405c7b92d19f4c6f02c78a"
  # 文件名尾部 macOS-X64 会让 brew 扫出 "64"（node/go 同款致盲，见 11.3），
  # 必须显式声明（audit 仅在声明与扫描值相同时才判冗余）。
  license "Apache-2.0" => { with: "LLVM-exception" }

  keg_only :provided_by_macos

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # 预编译包只链系统库（otool 实测 bin/clang-19 与 lib/libclang.dylib 仅
  # libSystem/libz/libc++），零 brew 依赖。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def pre_install
    # 磁盘空间检查：包 1.6GB，解包 8.3GB（bin/ 5.8G 带调试信息 + lib/ 2.4G），留足余量
    required_mb = 18432
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 llvm #{version}（Intel x86_64 预编译）"
  end

  def install
    # 实测：tar 内是单一顶层目录 LLVM-19.1.7-macOS-X64/，brew 会自动下降进入；
    # 整包进 prefix（bin 相对 lib 的资源定位不能拆，保持上游布局：
    # bin/ + include/ + lib/ + libexec/ + share/）。
    prefix.install Dir["*"]

    license = Dir["LICENSE*"].first
    doc.install license if license

    # 校验放 install 尾部（post_install 已废弃，见 11.37）：file 认 x86_64 + 版本自检。
    clang = bin/"clang-19"
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", clang.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{clang} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    version_out = Utils.safe_popen_read(clang.to_s, "--version")
    unless version_out.include?("clang version 19.1.7")
      opoo "版本自检未通过：期望 clang version 19.1.7，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "llvm #{version} 安装完成（x86_64 原生预编译）"
  end

  def caveats
    <<~EOS
      llvm 已安装为 Intel(x86_64) 预编译（上游最后一个 Intel mac 构建，版本锁死
      19.1.7，不跟 brew 检查器更新；要的是 bindgen 运行时的 libclang，19 够用）。
      与系统 clang 不冲突（keg-only，未链接）。

      给 bindgen 用（本仓用法）：
        export LIBCLANG_PATH=#{opt_lib}

      与 homebrew/core 的 llvm 同名，二者不能同时 link。切换来源：
        用本 tap：brew unlink llvm && brew link --overwrite #{full_name}
        用 core ：brew unlink #{full_name} && brew link llvm
    EOS
  end

  test do
    assert_match "clang version 19.1.7", shell_output("#{bin}/clang --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/clang-19")
    assert_path_exists lib/"libclang.dylib", "libclang.dylib 缺失，bindgen 用不了"
  end
end
