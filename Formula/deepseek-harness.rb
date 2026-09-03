class DeepseekHarness < Formula
  desc "DeepSeek agent harness with plugin architecture and web UI"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  # 上游 npm 包直引；包内是纯 JS（lib/bin.js，shebang node），无架构之分，
  # 跑在本 tap 的 node 上（同 cmd.rb 的 npm 路线）。
  url "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.1.1-rc.2.tgz"
  sha256 "47ec05f45ada5ab87779ae18a90456b5ebff5421dc0ff5c179677d65e1c16057"
  license "MIT"

  depends_on arch: :x86_64
  depends_on "bemly/tahoe-intel/node"
  depends_on macos: :tahoe
  # core 的 node 在 Intel Tahoe 没有 x86_64 瓶（装它要从源码编译数小时），
  # 故依赖本 tap 出瓶的 node。与 core 的 dsh（Dancer's shell）不同名公式，
  # 但双方都提供 bin/dsh，同时安装时以后 link 的为准（见 caveats）。

  def install
    # 标准 npm 公式写法：在解压出的 package 目录内安装到 libexec，
    # 再把 dsh 入口软链进 bin（包内 bin 为 { dsh: lib/bin.js }）。
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec/"bin/dsh"
  end

  def caveats
    <<~EOS
      dsh 由 npm 包 @deepseek-ai/dsh 提供，跑在本 tap 的 node 上
      （#{formula_opt_bin("bemly/tahoe-intel/node")}/node）。

      启动 Web UI（默认 http://127.0.0.1:3080，本地启动会自动打开浏览器）：
        dsh web
      只起服务、不自动打开浏览器：
        dsh web --no-open

      注意：homebrew/core 有个同名但无关的公式 dsh（Dancer's shell），
      双方都提供 bin/dsh。若 core 的 dsh 已安装，本公式会 link 失败，
      二选一：
        用 DeepSeek Harness：brew uninstall dsh && brew link bemly/tahoe-intel/deepseek-harness
        用 Dancer's shell：brew unlink bemly/tahoe-intel/deepseek-harness && brew link dsh

      本公式不检查更新（上游处于 developer preview，版本迭代快），
      需要升级请手动改 url + sha256。
    EOS
  end

  test do
    # dsh 是 commander 启动器：--help 列出 web / plugin 等入口
    assert_match "web", shell_output("#{bin}/dsh --help")
    # web 子应用自带帮助（经 --profile web 透传），证明 Web 所需产物齐全
    assert_match(/web|Web|profile/i, shell_output("#{bin}/dsh web --help"))
  end
end
