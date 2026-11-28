class Xcodes < Formula
  desc "Command-line tool to install and switch between multiple versions of Xcode"
  homepage "https://github.com/XcodesOrg/xcodes"
  # 版本号由 brew 从 URL 路径段 /download/2.2.1/ 扫描得出，不重复声明 version
  # （实测 Version.parse 对整条 URL 返回 2.2.1；显式写会触发 audit 冗余告警）。
  url "https://github.com/XcodesOrg/xcodes/releases/download/2.2.1/xcodes.zip"
  sha256 "b7e60a095dcba4235a4634e6c996dbb7bbb65e3b580c79c3ed7eb5cf02e57ce3"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "684ea9cfc1491793c6bf37bd6671fc6be3cf913f63b4a968c88694ea0c4feb8a"
    sha256 cellar: :any_skip_relocation, tahoe: "bf81860174f6c3175f836127621b5d31ab8a0d78a0eb87eb28ff26a6f872ab59"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 上游 release 的 xcodes.zip 是单个 universal 二进制（x86_64 + arm64），
  # Developer ID 签名并经公证（spctl 报 Notarized Developer ID），解压即 0755，
  # 无顶层目录；只依赖系统框架与 /usr/lib/swift 下的 Swift 运行时，零 brew 依赖。
  def install
    bin.install "xcodes"
    exe = bin/"xcodes"

    # 架构自检：必须是含 x86_64 slice 的二进制（纯 arm64 直接 odie）。
    # 校验放在 install 尾部：brew 6+ 已废弃命令式 post_install。
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", exe.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{exe} 不含 x86_64 slice。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(exe.to_s, "version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "xcodes #{version} 安装完成（universal，含 x86_64 slice）"
  end

  def caveats
    <<~EOS
      xcodes 已安装为上游官方 universal 预编译二进制（x86_64 + arm64，Developer ID 签名并公证）。

      与 homebrew/core 的 xcodes 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/xcodes，
      不能同时安装。从 core 版切换过来：
        brew uninstall xcodes && brew install #{full_name}

      core 在 macOS 26 的 Intel 瓶缺失，升级 core 版会回退源码编译；本版直接装瓶，不编译。
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/xcodes version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/xcodes")
  end
end
