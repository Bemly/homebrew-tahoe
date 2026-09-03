class Mufetch < Formula
  desc "Fast, customizable system information tool (Intel x86_64 for macOS Tahoe)"
  homepage "https://github.com/ashish0kumar/mufetch"
  url "https://github.com/ashish0kumar/mufetch/releases/download/v0.1.1/mufetch_darwin_x86_64.tar.gz"
  sha256 "71be64e17d22cece98ebc2f54c5c6e964e9a868623546fd2a3c29573278a5dbb"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 cellar: :any_skip_relocation, tahoe: "05f0e4712d9a2b332ba2dbec4acc3bb16063c7805f1b75f2ff2a461eb3119ac2"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # 上游 release 提供 macOS amd64 预编译包，直接引用（不构建）。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # 实测：tar 内无顶层目录，三个文件直接解压在 CWD（LICENSE / README.md / mufetch），
    # 与 gh/node 那种"单顶层目录自动下降"不同，这里直接按文件名安装即可。
    bin.install "mufetch"
    doc.install "README.md"
    doc.install "LICENSE"
  end

  def post_install
    mufetch = bin/"mufetch"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", mufetch.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{mufetch} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（--version 实测退出码为 0，可用 safe_popen_read）
    version_out = Utils.safe_popen_read(mufetch.to_s, "--version")
    unless version_out.include?("mufetch version #{version}")
      opoo "版本自检未通过：期望 mufetch version #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "mufetch #{version} 安装完成（x86_64 原生）"
  end

  test do
    assert_match "mufetch version #{version}", shell_output("#{bin}/mufetch --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/mufetch")
  end
end
