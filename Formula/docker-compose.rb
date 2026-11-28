class DockerCompose < Formula
  desc "Docker plugin for multi-container applications (Intel build)"
  homepage "https://github.com/docker/compose"
  # 上游官方裸二进制（文件名无版本，版本号只在路径 v5.5.1 段；无压缩包，
  # brew 按未压缩文件处理，直接改名装进 bin）。
  # 版本号由 brew 从 URL（含路径段）扫描得出，实测文件名里的 x86_64 与
  # 无版本文件名都不影响扫描，不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/docker/compose/releases/download/v5.8.1/docker-compose-darwin-x86_64"
  sha256 "59ddcb7f6a077b2b11b361fca4c62a1de20fd44054ec6c98188c9bb993db4fbb"
  license "Apache-2.0"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "0133f759b459a07f58dc6ceb7b3773ff3f4e048cb65120e8b2611dc642a8f67b"
    sha256 cellar: :any_skip_relocation, tahoe: "c69e31817c3f3ff6c00ae608f9ce0c70d589f4ce71c282b435451c2efc97311d"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 docker-compose 同名，二者共用
  # #{HOMEBREW_PREFIX}/Cellar/docker-compose，不能同时安装。安装后如需切换见 caveats。

  def install
    # 裸二进制：改名装进 bin（上游文件名无版本，只有平台后缀）。
    bin.install "docker-compose-darwin-x86_64" => "docker-compose"

    # 安装后架构与版本自检（放在 install 尾部，brew 6+ 已废弃 def post_install）
    compose = bin/"docker-compose"
    # 裸二进制下载为 0644，Cleaner 仅在 install 结束后补 0555；install 内自检前须显式加执行位
    chmod 0555, compose

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", compose.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{compose} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(compose.to_s, "version")
    unless version_out.include?("v#{version}")
      opoo "版本自检未通过：期望 v#{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "docker-compose #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      docker-compose 已安装为 Intel(x86_64) 原生二进制，直接取自上游官方发布包。

      注册为 Docker CLI 插件（brew 不能代写家目录，需手动执行）：
        mkdir -p ~/.docker/cli-plugins
        ln -sf #{opt_bin}/docker-compose ~/.docker/cli-plugins/docker-compose
        docker compose version

      与 homebrew/core 的 docker-compose 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall docker-compose && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install docker-compose
    EOS
  end

  test do
    assert_match "v#{version}", shell_output("#{bin}/docker-compose version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/docker-compose")
  end
end
