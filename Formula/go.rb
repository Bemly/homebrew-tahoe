class Go < Formula
  desc "Open source programming language (Intel x86_64 for macOS Tahoe)"
  homepage "https://go.dev/"
  # Go 官方 darwin-amd64 tar 包：完整工具链（bin/go、gofmt、pkg、src），
  # 只链系统库（otool 确认无 Homebrew 依赖），零依赖。
  # 不用同版本 .pkg：pkg 安装器要写 /usr/local/go、必须 root 权限，
  # 公式无 sudo 不可用；tar.gz 是 brew 原生路线（node 同例）。
  # brew 从 URL 尾部 darwin-amd64 只能扫出 "64"，与真实版本不符，
  # 必须显式声明（audit 仅在声明与扫描值相同时才判冗余；node 同款坑，见 11.3）。
  url "https://go.dev/dl/go1.27.1.darwin-amd64.tar.gz"
  version "1.27.1"
  sha256 "8f8f52c6649542cf027bbc9b9c68d1ec042f9f34808a40413f0b8b3f66f3caa4"
  license "BSD-3-Clause"

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 go 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/go，
  # 不能同时安装。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：展开后约 280MB，留足余量
    required_mb = 1024
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 go #{version}（Intel x86_64）"

    # 若已存在其他来源的 go，提前告知同名冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/go/*"].map { |keg| File.basename(keg) }
                                                   .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 go：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 go 同名，不能同时安装，请先卸载另一方：
        brew uninstall go
    EOS
  end

  def install
    # 实测：brew 解压后会下降进 tar 内唯一的顶层目录（go/）。
    # 整树原样装进 prefix（bin/go 是真文件非软链）：go 按二进制路径
    # 自动定位 GOROOT，拆开装反而会找不到 pkg/src。
    prefix.install Dir["*"]
  end

  def post_install
    go = bin/"go"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", go.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{go} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(go.to_s, "version")
    unless version_out.include?("go#{version}")
      opoo "版本自检未通过：期望 go#{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "go #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      go 已安装为 Intel(x86_64) 原生工具链，直接取自 Go 官方发布包
      （GOROOT 自动指向 #{opt_prefix}，无需手动设环境变量）。

      与 homebrew/core 的 go 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall go && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install go
    EOS
  end

  test do
    assert_match "go#{version}", shell_output("#{bin}/go version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/go")
    # 真编译一次：证明工具链可用（单文件、不联网、不写模块缓存之外）
    (testpath/"hello.go").write('package main;import "fmt";func main(){fmt.Println("hi")}')
    system bin/"go", "build", "-o", testpath/"hello", testpath/"hello.go"
    assert_match "hi", shell_output(testpath/"hello")
  end
end
