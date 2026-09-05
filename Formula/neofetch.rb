class Neofetch < Formula
  desc "System info script (Intel x86_64 build for macOS Tahoe)"
  homepage "https://github.com/dylanaraps/neofetch"
  # 版本号由 brew 从 URL 扫描得出（archive/7.1.0.tar.gz → 7.1.0），不重复声明 version
  # （否则 audit 判为冗余，见 AGENTS.md 11.3）。
  # neofetch 已归档，7.1.0 为最后一版，不再有更新；故不建 updater/neofetch.swift 检查器。
  url "https://github.com/dylanaraps/neofetch/archive/refs/tags/7.1.0.tar.gz"
  sha256 "58a95e6b714e41efc804eca389a223309169b2def35e57fa934482a6b47c27e7"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "9349dbdf49f3be597e427c0e1374d2f7b7db93881dbd24a344f770e940a0fe6e"
  end

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的二进制。
  # Homebrew 官方不为 Tahoe 构建 x86_64 bottle，这里直接引用上游发布包。
  # neofetch 是纯 bash 脚本（无编译、无架构限制），但仍按 tap 约定强制 Intel + Tahoe 门槛。
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # 上游 Makefile 的 install 目标仅做 cp/mkdir，接受 PREFIX（默认 /usr）。
    # 直接 make install 进 Cellar（脚本工具的标准做法）；man 页随之进 share/man，brew 自动 link。
    system "make", "install", "PREFIX=#{prefix}"
  end

  # neofetch 是纯 bash 脚本（无编译、无架构限制），Intel + Tahoe 门槛由公式顶部的
  # 硬性约束保证，安装后无需再做二进制架构校验或版本自检。
  # 注：neofetch --version 退出码恒为 1（上游已知 bug），若用 Utils.safe_popen_read
  # 调它会抛 ErrorDuringExecution 导致 post_install 报错，故此处不写 post_install。

  def caveats
    <<~EOS
      neofetch 是纯 bash 脚本（项目已归档，7.1.0 为最后一版），取自上游发布包。

      与 homebrew/core 的 neofetch 同名，二者不能同时 link。切换来源：
        用本 tap：brew unlink neofetch && brew link --overwrite #{full_name}
        用 core ：brew unlink #{full_name} && brew link neofetch
    EOS
  end

  test do
    assert_predicate bin/"neofetch", :executable?
    # neofetch --version 退出码恒为 1（上游 bug），shell_output 第二个参数指定预期退出码
    assert_match version.to_s, shell_output("#{bin}/neofetch --version 2>&1", 1)
  end
end
