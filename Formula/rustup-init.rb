class RustupInit < Formula
  desc "Rust toolchain installer, official static build (Intel x86_64)"
  homepage "https://rust-lang.github.io/rustup/"
  # Rust 官方静态归档里的 rustup-init 裸二进制（自包含，零依赖），
  # 与 core 从源码 cargo 构建的 rustup 等价，但无需 Rust 工具链先行。
  # 命名 rustup-init 而不用 rustup：与 core 的 rustup 同名会共用 Cellar，
  # 改名后独立存在，双方互不干扰（二进制名也不同，无 link 冲突）。
  # 版本在路径段（/archive/1.29.1/），brew 可扫描，无需 version 行（compose 同例）。
  url "https://static.rust-lang.org/rustup/archive/1.29.1/x86_64-apple-darwin/rustup-init"
  sha256 "259e2b84274434085163fe8d556510571772cda2aa6d87ca6aa664f57bc644e3"
  license any_of: ["Apache-2.0", "MIT"]

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def pre_install
    # 磁盘空间检查：本体约 30MB，留足余量
    required_mb = 512
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 rustup-init #{version}（Intel x86_64）"
  end

  def install
    # 上游裸二进制（无压缩包，brew 按未压缩文件处理，直接装进 bin）。
    bin.install "rustup-init"
  end

  def post_install
    rustup_init = bin/"rustup-init"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", rustup_init.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{rustup_init} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(rustup_init.to_s, "--version")
    unless version_out.include?("rustup-init #{version}")
      opoo "版本自检未通过：期望 rustup-init #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "rustup-init #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      rustup-init 已安装为 Intel(x86_64) 原生二进制（Rust 官方静态构建）。
      装工具链（默认 stable，写 ~/.cargo 与 ~/.rustup，不碰系统目录）：
        #{opt_bin}/rustup-init -y --default-toolchain stable --profile minimal
      之后按提示把 ~/.cargo/bin 加进 PATH 即可（caveats 不能代写家目录配置）。

      与 core 的 rustup 不同名，可共存：core 的是 cargo 现编的 rustup，
      本公式是官方 rustup-init，用哪个看你调哪个二进制。
    EOS
  end

  test do
    assert_match "rustup-init #{version}", shell_output("#{bin}/rustup-init --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/rustup-init")
  end
end
