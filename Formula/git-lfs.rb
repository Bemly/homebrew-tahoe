class GitLfs < Formula
  desc "Git extension for versioning large files (Intel x86_64 for macOS Tahoe)"
  homepage "https://git-lfs.com/"
  # 上游官方 darwin-amd64 zip（单顶层目录 git-lfs-<ver>/，内含二进制 + 全套
  # man 页；自带的 install.sh 要写 /usr/local 不用，直接拆文件装）。
  # 版本号由 brew 从 URL 扫描得出（amd64-v 形态实测可扫，buildx 同例），
  # 不重复声明 version（否则 audit 判为冗余）。
  url "https://github.com/git-lfs/git-lfs/releases/download/v3.8.0/git-lfs-darwin-amd64-v3.8.0.zip"
  sha256 "f1c17aeca0b4eaab9ea606226477dbed3b84b56fe0811a9f967d2ea2b2393c53"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 cellar: :any_skip_relocation, tahoe: "a902646b6b4074b5205726a069a3116511d3640a018bb5660a2ea7ecf14a9dbc"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # 与 homebrew/core 的 git-lfs 同名，二者共用 #{HOMEBREW_PREFIX}/Cellar/git-lfs，
  # 不能同时安装。安装后如需切换见 caveats。
  def pre_install
    # 磁盘空间检查：本体约 15MB + man 页，留足余量
    required_mb = 256
    df_line = Utils.safe_popen_read("/bin/df", "-m", HOMEBREW_PREFIX.to_s).lines.last.to_s
    available_mb = df_line.split[3].to_i

    if available_mb.positive? && available_mb < required_mb
      odie <<~EOS
        磁盘空间不足：#{HOMEBREW_PREFIX} 仅剩 #{available_mb}MB，至少需要 #{required_mb}MB。
      EOS
    end

    ohai "安装 git-lfs #{version}（Intel x86_64）"

    # 若已存在其他来源的 git-lfs，提前告知同名冲突的处理方式
    other_kegs = Dir[HOMEBREW_PREFIX/"Cellar/git-lfs/*"].map { |keg| File.basename(keg) }
                                                        .reject { |v| v == version.to_s }
    return if other_kegs.empty?

    opoo <<~EOS
      Cellar 中已存在其他版本的 git-lfs：#{other_kegs.join(", ")}
      本 formula 与 homebrew/core 的 git-lfs 同名，不能同时安装，请先卸载另一方：
        brew uninstall git-lfs
    EOS
  end

  def install
    # 实测：brew 解压后会下降进 zip 内唯一的顶层目录（git-lfs-<version>/），
    # 故用 ** 通配定位二进制与 man 页（见 11.1）。
    bin.install Dir["**/git-lfs"].fetch(0)
    man1.install Dir["**/man/man1/*.1"]
    man5.install Dir["**/man/man5/*.5"]
    man7.install Dir["**/man/man7/*.7"]

    readme = Dir["**/README.md"].first
    doc.install readme if readme
  end

  def post_install
    git_lfs = bin/"git-lfs"

    # 1) 必须是 Intel x86_64 原生二进制，防止误装 arm64 包
    file_out = Utils.safe_popen_read("/usr/bin/file", "-b", git_lfs.to_s)
    unless file_out.include?("x86_64")
      odie <<~EOS
        架构校验失败：#{git_lfs} 不是 x86_64 二进制。
        file(1) 报告：#{file_out.strip}
      EOS
    end

    # 2) 版本自检（sha256 已校验过压缩包，此处兜底确认公式版本号没写错）
    version_out = Utils.safe_popen_read(git_lfs.to_s, "version")
    unless version_out.include?("git-lfs/#{version}")
      opoo "版本自检未通过：期望 git-lfs/#{version}，实际 #{version_out.lines.first.to_s.strip}"
    end

    ohai "git-lfs #{version} 安装完成（x86_64 原生）"
  end

  def caveats
    <<~EOS
      git-lfs 已安装为 Intel(x86_64) 原生二进制，直接取自上游官方发布包。

      收尾还需手动跑一次（brew 不代写 git 配置，core 同例）：
        # 全局 git 配置
        git lfs install

      与 homebrew/core 的 git-lfs 同名，二者不能同时安装。切换来源：
        用本 tap：brew uninstall git-lfs && brew install #{full_name}
        用 core ：brew uninstall #{full_name} && brew install git-lfs
    EOS
  end

  test do
    assert_match "git-lfs/#{version}", shell_output("#{bin}/git-lfs version")
    assert_match "x86_64", shell_output("/usr/bin/file -b #{bin}/git-lfs")
    # 照抄 core 用例：track 写 .gitattributes 即证明 git 联动正常
    system "git", "init"
    system "git", "lfs", "track", "test"
    assert_match(/^test filter=lfs/, File.read(".gitattributes"))
  end
end
