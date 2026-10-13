class Scrcpy < Formula
  desc "Display and control Android devices over USB or TCP/IP"
  homepage "https://github.com/Genymobile/scrcpy"
  # 上游官方 macOS x86_64 预编译包（thin x86_64，otool 全系统库，SDL/ffmpeg 已静态链入，
  # 零 brew 依赖；附带 universal adb 与设备端 scrcpy-server；见 AGENTS.md 11.47）。
  # 单一顶层目录（scrcpy-macos-x86_64-v<ver>/），brew 会下降进入，故直接用相对路径。
  url "https://github.com/Genymobile/scrcpy/releases/download/v5.0.1/scrcpy-macos-x86_64-v5.0.1.tar.gz"
  sha256 "31a5467a9e907f162b093267cbbab1276b15c6e709c2ea8159566a8d165beb50"
  license "Apache-2.0"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "c7427dbdc8eb33e8e58135777aece438bdca515e8e51633ebd106e645741ac91"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # 扁平布局必须整体保留：scrcpy 按自身所在目录定位 scrcpy-server 与 adb，
    # 拆散即找不到 server。进 libexec，bin 用官方 wrapper 指过去（不猜 symlink 解析）。
    libexec.install %w[scrcpy adb scrcpy-server]
    bin.write_exec_script libexec/"scrcpy"
    # write_exec_script 只写文件不给执行位（644），必须手动 chmod（否则 bin/scrcpy
    # 以 exit 1 静默失败；/tmp 手测因顺手 chmod +x 没暴露，见 11.47）。
    # frida 的 xz 无执行位是同类问题（见 11.37）。
    chmod 0555, bin/"scrcpy"
    man1.install "scrcpy.1"

    # 拆箱校验（post_install 已废弃，校验挪进 install 尾部，走最终交付物）。
    arch = Utils.safe_popen_read("/usr/bin/file", "-b", (libexec/"scrcpy").to_s)
    odie "期望 x86_64，实际：#{arch}" unless arch.include?("x86_64")
    ver = Utils.safe_popen_read((bin/"scrcpy").to_s, "--version")[/\d+\.\d+\.\d+/]
    odie "scrcpy --version 自检失败" if ver.blank?
    ohai "scrcpy #{ver}（#{arch.strip}）"
  end

  def caveats
    <<~EOS
      已链接 scrcpy 到 PATH（libexec 内附带同目录 adb 与 scrcpy-server，不要拆散）。
      连手机前先在开发者选项里打开 USB 调试，再跑 `scrcpy`（`adb devices` 应能列出设备）。
      与 homebrew/core 的 scrcpy 同名不能共存，先 `brew uninstall scrcpy` 再装本版。
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/scrcpy --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{libexec}/scrcpy")
    assert_path_exists libexec/"scrcpy-server"
    assert_path_exists libexec/"adb"
  end
end
