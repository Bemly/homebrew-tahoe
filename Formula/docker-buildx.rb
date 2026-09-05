class DockerBuildx < Formula
  desc "Docker CLI plugin for extended build capabilities (Intel build)"
  homepage "https://github.com/docker/buildx"
  # 上游官方裸二进制（无压缩包，brew 按未压缩文件处理，直接改名装进 bin）。
  # 版本号由 brew 从 URL 扫描得出（实测 darwin-amd64 尾缀不影响扫描），
  # 不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/docker/buildx/releases/download/v0.37.0/buildx-v0.37.0.darwin-amd64"
  sha256 "9d5a359608ffddbc9049eb0a8128db798a1fcc30cbfb2e451cb49ab99cbe0635"
  license "Apache-2.0"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "9bb882b0e0ed0eac72751f452fcc1c2b61f5bcbb19606eae9496def41c00da32"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 docker-buildx 同名，二者共用
  # #{HOMEBREW_PREFIX}/Cellar/docker-buildx，不能同时安装。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：本体约 68MB，留足余量
    required_mb = 512
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 docker-buildx #{version}（Intel x86_64）"

    # 若已存在其他来源的 docker-buildx，提前告知同名冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/docker-buildx/*"].map { |keg| File.basename(keg) }
                                                              .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 docker-buildx：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 docker-buildx 同名，不能同时安装，请先卸载另一方：
        brew uninstall docker-buildx
    EOS
  end

  def install
    # 裸二进制：改名装进 bin（上游文件名带版本与平台后缀）。
    bin.install "buildx-v#{version}.darwin-amd64" => "docker-buildx"
  end

  def post_install
    buildx = bin/"docker-buildx"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", buildx.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{buildx} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(buildx.to_s, "version")
    unless version_out.include?("v#{version}")
      opoo "版本自检未通过：期望 v#{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "docker-buildx #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      docker-buildx 已安装为 Intel(x86_64) 原生二进制，直接取自上游官方发布包。

      注册为 Docker CLI 插件（brew 不能代写家目录，需手动执行）：
        mkdir -p ~/.docker/cli-plugins
        ln -sf #{opt_bin}/docker-buildx ~/.docker/cli-plugins/docker-buildx
        docker buildx version

      与 homebrew/core 的 docker-buildx 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall docker-buildx && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install docker-buildx
    EOS
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/docker-buildx version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/docker-buildx")
  end
end
