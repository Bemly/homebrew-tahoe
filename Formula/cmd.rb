class Cmd < Formula
  desc "AI coding agent for the terminal (npm: command-code)"
  homepage "https://www.npmjs.com/package/command-code"
  # 上游 npm tarball 直引；包内是纯 JS（dist/index.mjs），无需编译。
  url "https://registry.npmjs.org/command-code/-/command-code-1.45.0.tgz"
  sha256 "4f5a8e78b3d04efc7908b6c28d7eee60fd6c613c0ba9794e8268521d3ce29bb3"
  # 上游 package.json 的 license 是 "UNLICENSED"（npm 的私有占位，不是标准 SPDX 标识），
  # 声明会被 audit 判无效 SPDX —— 不声明则 audit 跳过 license 检查。

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe-intel"
    sha256 cellar: :any, tahoe: "7fa924d9d06989e9fe56876b29650940a0447168f6a334b3952b15586bec28c3"
  end

  depends_on arch: :x86_64
  depends_on "bemly/tahoe-intel/node"
  depends_on macos: :tahoe
  # core 的 node 在 Intel Tahoe 没有 x86_64 瓶（装它要从源码编译数小时），
  # 故依赖本 tap 出瓶的 node。与 core 的 node 同名，二者不能共存。

  def install
    # 标准 npm 公式写法：在解压出的 package 目录内安装到 libexec，
    # 再把需要的命令软链进 bin（本包提供 cmd/cmdc/command-code/commandcode 四个入口，
    # 这里只暴露 cmd）。
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec/"bin/cmd"
  end

  def caveats
    <<~EOS
      cmd 由 npm 包 command-code 提供，是本 tap 的 node 上运行（#{formula_opt_bin("bemly/tahoe-intel/node")}/node）。

      与 homebrew/core 的 node 同名冲突：若你用的是 core 的 node，
      需先 `brew uninstall node` 再装本 tap 的 node。

      若敲 `cmd` 仍是旧版本（此前用 `npm i -g command-code` 装过的话，
      /usr/local/bin/cmd 会残留指向旧包的链接，把本公式的版本遮蔽掉），执行：
        brew link --overwrite bemly/tahoe-intel/cmd

      本公式不检查更新（上游版本随 npm 频繁变动），需要升级请手动改 url + sha256。
    EOS
  end

  test do
    # 实测：`cmd --version` 输出纯版本号（如 1.45.0）且退出码为 0
    assert_match version.to_s, shell_output("#{bin}/cmd --version")
  end
end
