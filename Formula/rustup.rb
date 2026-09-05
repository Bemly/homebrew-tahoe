class Rustup < Formula
  desc "Rust toolchain installer"
  homepage "https://rust-lang.github.io/rustup/"
  # Rust 官方静态归档里的 rustup-init 裸二进制（自包含，零依赖），与 core 从
  # 源码 cargo 构建的 rustup 同一上游——区别只是 core 自己编、我们直接拿官方
  # 静态包（CI 无需 Rust 工具链先行）。rustup-init 不是 rustup 的依赖，
  # 它俩是同一个二进制：上游发布物就叫 rustup-init，argv[0] 决定行为，
  # core 编出来也先叫 rustup-init 再改名（见 core 公式注释），这里同理。
  # 公式名与 core 同名 rustup（本 tap 是 x64 备用源，命名与上游保持一致）：
  # 与 core 版共用 Cellar，不能共存，装前须先卸 core 版（见 caveats）。
  # 曾用名 rustup-init：撞 core 改名别名（rustup-init→rustup，全局生效），
  # 任何 tap 再叫它都会报 migrate 错，故废弃（见 11.32）。
  # 版本在路径段（/archive/1.29.1/），brew 可扫描，无需 version 行（compose 同例）。
  url "https://static.rust-lang.org/rustup/archive/1.29.1/x86_64-apple-darwin/rustup-init"
  sha256 "259e2b84274434085163fe8d556510571772cda2aa6d87ca6aa664f57bc644e3"
  license any_of: ["Apache-2.0", "MIT"]

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 cellar: :any_skip_relocation, tahoe: "ae4932eb6b6343934bd97e257aceeaaffb989aadf8c144f2edf258abfe183732"
  end

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

    ohai "安装 rustup #{version}（Intel x86_64，官方静态构建）"
  end

  def install
    # 上游发布物就叫 rustup-init：装成 rustup（与 core 行为一致），
    # 代理垫片照抄 core 列表，装完工具链后 cargo/rustc 即开即用。
    bin.install "rustup-init" => "rustup"

    %w[cargo cargo-clippy cargo-fmt cargo-miri clippy-driver rls rust-analyzer
       rust-gdb rust-gdbgui rust-lldb rustc rustdoc rustfmt].each do |name|
      bin.install_symlink bin/"rustup" => name
    end
  end

  def post_install
    rustup = bin/"rustup"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", rustup.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{rustup} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(rustup.to_s, "--version")
    unless version_out.include?("rustup #{version}")
      opoo "版本自检未通过：期望 rustup #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "rustup #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      rustup 已安装为 Intel(x86_64) 原生二进制（Rust 官方静态构建），
      与 homebrew/core 的 rustup 同名，装前须先卸 core 版：
        brew uninstall rustup
      工具链改由 rustup 自己管理（不再用 core 的 rust 公式）：
        rustup toolchain install stable --profile minimal
      之后 cargo/rustc 走代理垫片直接可用；升级 rustup 本体用 brew，
      不要 `rustup self update`（会绕开 brew 改 Cellar）。

      切回 core 版：
        brew uninstall #{full_name} && brew install rustup
    EOS
  end

  test do
    assert_match "rustup #{version}", shell_output("#{bin}/rustup --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/rustup")
  end
end
