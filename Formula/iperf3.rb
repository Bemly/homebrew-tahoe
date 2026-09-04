class Iperf3 < Formula
  desc "Network throughput measurement tool, static build (Intel x86_64)"
  homepage "https://software.es.net/iperf/"
  # userdocs/iperf3-static 的 macOS 静态构建（openssl 静态链接，零 brew 依赖，
  # 绕开 core 公式引入 openssl@4 依赖树的问题）。
  # 注意：资产名含 runner 世代后缀（osx-13/osx-15，随维护者换 runner 变化），
  # install 用通配不写死；版本判据走 brew iperf3 stable，资产发现逻辑见
  # updater/iperf3.swift（expanded_assets 抓取 + HEAD 探测兜底）。
  # 版本在路径段（/download/3.21/），brew 可扫描，无需 version 行（compose 同例）。
  url "https://github.com/userdocs/iperf3-static/releases/download/3.21/iperf3-amd64-osx-15"
  sha256 "71474bb614e2d48f3c5fcb63ae7b77b51e37043f989478ee9021223db856a8e6"
  license "BSD-3-Clause"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 cellar: :any_skip_relocation, tahoe: "927c2873423933e15451fbf79856b4cda7b04b7118aa4729536d1c4aaed2ff74"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 iperf3 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/iperf3，
  # 不能同时安装。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：本体约 1MB，留足余量
    required_mb = 256
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 iperf3 #{version}（Intel x86_64 静态构建）"

    # 若已存在其他来源的 iperf3，提前告知同名冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/iperf3/*"].map { |keg| File.basename(keg) }
                                                       .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 iperf3：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 iperf3 同名，不能同时安装，请先卸载另一方：
        brew uninstall iperf3
    EOS
  end

  def install
    # 上游裸二进制（无压缩包）：文件名后缀随构建机变化，通配后改名装进 bin。
    bin.install Dir["iperf3-amd64-osx-*"].fetch(0) => "iperf3"
  end

  def post_install
    iperf3 = bin/"iperf3"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", iperf3.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{iperf3} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(iperf3.to_s, "--version")
    unless version_out.include?("iperf #{version}")
      opoo "版本自检未通过：期望 iperf #{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "iperf3 #{version} 安装完成（x86_64 静态构建，无 openssl 依赖）"
  end

  def caveats
    <<~EOS
      iperf3 已安装为 Intel(x86_64) 静态二进制（Phase 4 裸网络吞吐基线用），
      不依赖 openssl@4，单文件即跑。

      与 homebrew/core 的 iperf3 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall iperf3 && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install iperf3
    EOS
  end

  test do
    assert_match "iperf #{version}", shell_output("#{bin}/iperf3 --version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/iperf3")
  end
end
