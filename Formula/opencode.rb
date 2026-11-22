class Opencode < Formula
  desc "AI coding agent built for the terminal"
  homepage "https://opencode.ai"
  # 取自 anomalyco/homebrew-tap 的 opencode.rb（GoReleaser 产物，取 mac 双架构段）。
  # 上游是 anomalyco/opencode fork 的官方发布包，非 homebrew/core 的 npm 版。
  # 主 url/sha 是 Intel 段（放顶层：brew readall 会在 Linux 下验公式，
  # 顶层无 url 直接报 requires at least a URL；on_macos 包不住 Linux）。
  # ARM 段在 on_macos 内覆盖（结构照源文件）。
  # 版本号由 brew 从 URL 扫描得出，不重复声明 version（否则 audit 判为冗余，见 AGENTS.md §11.1）。
  # 实测本系列 URL（v 前缀 + darwin-x64/mac-x86_64 尾部）能正确扫出版本，与 node 的 x64 坑不同。
  url "https://github.com/anomalyco/opencode/releases/download/v1.19.6/opencode-darwin-x64.zip"
  sha256 "39aabb10005059f80f007a119a33405dcd46325300993eb6cbcc961c7243dd31"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "5f1e88f37a03ef607922f1f5acd89bb77e7b16c3a3758c989e3cdef416a9601f"
  end

  # 瓶是 x86_64 的（macos-26-intel 制出）；ARM 安装回退到上游直链（同版本 arm64 包）。

  # 本 tap 只收录 macOS 26(Tahoe) 及以上可用的二进制。
  # arch 门槛已摘（opencode 双架构，Intel/ARM 各取各的包；摘门槛是例外，见 AGENTS.md §4）。
  # ripgrep 走本 tap 的瓶（Intel 上是 GHCR 瓶；ARM 上 core 无瓶则源码编译，
  # ripgrep 同样摘了 arch 门槛，否则 ARM 装 opencode 会被依赖挡住）。
  depends_on "bemly/tahoe/ripgrep"
  depends_on macos: :tahoe

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/anomalyco/opencode/releases/download/v1.19.6/opencode-darwin-arm64.zip"
      sha256 "c0be3f34dde2fdcb31b25120f303c6ed5b69b828f16e5e0fbecff21a882adda1"
    end
  end

  # 与 homebrew/core 的 opencode 同名（core 是 npm 版），二者共用 Cellar/opencode，
  # 不能同时安装。安装后如需切换见 caveats。

  def install
    # 上游 zip 内是单个 opencode 二进制（无顶层目录），用 ** 通配兼容 brew 是否下降。
    bin.install Dir["**/opencode"].fetch(0)

    # 安装后架构与版本自检（放在 install 尾部，brew 6+ 已废弃 def post_install）
    oc = bin/"opencode"

    # 1) 必须是本机架构原生二进制（Intel 取 x64 段，ARM 取 arm64 段）
    expected = Hardware::CPU.arm? ? "arm64" : "x86_64"
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", oc.to_s)
    unless file_out.include?(expected)
      odie <<~EOS
        架构校验失败：#{oc} 不是 #{expected} 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(oc.to_s, "--version")
    unless version_out.include?(version.to_s)
      opoo "版本自检未通过：期望 #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "opencode #{version} 安装完成（#{expected} 原生）"
  end

  def caveats
    <<~EOS
      opencode 已安装为本机架构原生二进制，取自 anomalyco/opencode 的官方发布包
      （Intel 取 darwin-x64 段走 GHCR 瓶；ARM 取 darwin-arm64 段走上游直链，
      本 tap 不出 arm64 瓶）。

      与 homebrew/core 的 opencode（npm 版）同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall opencode && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install opencode
    EOS
  end

  test do
    expected = Hardware::CPU.arm? ? "arm64" : "x86_64"
    assert_match version.to_s, shell_output("#{bin}/opencode --version")
    assert_match expected, shell_output("/usr/bin/file -b #{bin}/opencode")
  end
end
