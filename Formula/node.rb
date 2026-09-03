class Node < Formula
  desc "JavaScript runtime built on V8 (Intel x86_64 for macOS Tahoe)"
  homepage "https://nodejs.org/"
  url "https://nodejs.org/dist/v26.8.1/node-v26.8.1-darwin-x64.tar.gz"
  # brew 从 URL 尾部 darwin-x64.tar.gz 只能扫出 "64"，与真实版本不符，
  # 必须显式声明（audit 仅在声明与扫描值相同时才判冗余）
  version "26.8.1"
  sha256 "fe9c6dbf9c8e1b4443803d75e2a20366e420dae650c747dbb116b22975751baf"
  license "MIT"

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # Homebrew 官方不为 Tahoe 构建 x86_64 bottle，这里直接引用上游官方发布包。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def pre_install
    required_mb = 512
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 node #{version}（Intel x86_64）"
  end

  def install
    # staging 已下降进唯一顶层目录 node-v<ver>-darwin-x64（11.1）。
    # 整树进 libexec：cp_r 原样保留 npm/corepack 的 bin 符号链接
    # （../lib/node_modules/... 相对路径），拆开装会破坏 npm 的模块解析。
    libexec.install Dir["bin", "include", "lib", "share"]
    # 外层命令入口用相对符号链接指向 libexec 内的原件
    bin.install_symlink Dir[libexec/"bin/*"]

    man_pages = Dir["#{libexec}/share/man/man1/*"]
    man1.install man_pages unless man_pages.empty?
  end

  def post_install
    node_bin = bin/"node"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", node_bin.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{node_bin} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（node --version 输出 v 前缀版本号）
    version_out = Utils.safe_popen_read(node_bin.to_s, "--version").strip
    if version_out != "v#{version}"
      opoo "版本自检未通过：期望 v#{version}，实际 #{version_out}"
    end

    ohai "node #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      node 已安装为 Intel(x86_64) 原生二进制，直接取自 Node.js 官方发布包。

      与 homebrew/core 的 node 同名，二者不能同时安装（brew 会直接拒绝）。
      切换来源必须先卸载再装另一个：
        用本 tap：brew uninstall node && brew install bemly/tahoe-intel/node
        用 core ：brew uninstall bemly/tahoe-intel/node && brew install node
      注意：全局包在 $(brew --prefix)/lib/node_modules 下，随所属 keg 存亡。
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/node --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/node")
  end
end
