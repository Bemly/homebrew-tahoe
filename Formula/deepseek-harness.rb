class DeepseekHarness < Formula
  desc "DeepSeek agent harness with plugin architecture and web UI"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  # 上游 npm 包直引；包内是纯 JS（lib/bin.js，shebang node），无架构之分，
  # 跑在本 tap 的 node 上（同 cmd.rb 的 npm 路线）。
  url "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.2.2-rc.5.tgz"
  sha256 "67da5a3c458f46cd278e0eec6ad0e3a44e99fd13087c6f11a1b362268900a52c"
  license "MIT"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "3a19ef0168f6e8cf291dc53ee64292053dae7214b90e619ae66d4130d11f8248"
  end

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/node"
  depends_on macos: :tahoe
  # core 的 node 在 Intel Tahoe 没有 x86_64 瓶（装它要从源码编译数小时），
  # 故依赖本 tap 出瓶的 node。与 core 的 dsh（Dancer's shell）不同名公式，
  # 但双方都提供 bin/dsh，同时安装时以后 link 的为准（见 caveats）。

  def install
    # 标准 npm 公式写法：在解压出的 package 目录内安装到 libexec，
    # 再把 dsh 入口软链进 bin（包内 bin 为 { dsh: lib/bin.js }）。
    system "npm", "install", *std_npm_args

    # @deepseek-ai/libreoffice-kit 附带的 frame-forwarding.node 预编译为 MH_DYLIB 且未带
    # -headerpad_max_install_names，Homebrew 安装尾部的 fix_dynamic_linkage 改写 dylib ID
    # 会因头空间不足直接失败：清理非 darwin-x64 预编译件，并用 -Wl,-headerpad_max_install_names
    # 原地重编 darwin-x64/frame-forwarding.node。
    ff_dir = libexec/"lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/libreoffice-kit/frame-forwarding"
    if ff_dir.directory?
      %w[darwin-arm64 win32-arm64 win32-x64].each do |plat|
        rm_r(ff_dir/"prebuilds"/plat) if (ff_dir/"prebuilds"/plat).exist?
      end
      x64_node = ff_dir/"prebuilds/darwin-x64/frame-forwarding.node"
      if x64_node.exist?
        node_include = Formula["bemly/tahoe/node"].opt_libexec/"include/node"
        cd ff_dir do
          system ENV.cxx,
                 "-arch", "x86_64", "-mmacosx-version-min=11.0", "-std=c++17", "-O2", "-fPIC",
                 "-Iinclude", "-Isrc", "-I#{node_include}",
                 "-DNAPI_VERSION=8", "-DNODE_GYP_MODULE_NAME=dsh_frame_forwarding",
                 "-shared", "-undefined", "dynamic_lookup",
                 "-Wl,-headerpad_max_install_names",
                 "-Wl,-install_name,@rpath/frame-forwarding.node",
                 "src/receiver.cc", "src/node-producer.cc", "src/producer.cc", "src/transport.cc",
                 "-framework", "IOSurface", "-framework", "CoreFoundation", "-lbsm",
                 "-o", x64_node
          system "codesign", "--force", "--sign", "-", x64_node
        end
      end
    end

    bin.install_symlink libexec/"bin/dsh"
  end

  def caveats
    <<~EOS
      dsh 由 npm 包 @deepseek-ai/dsh 提供，跑在本 tap 的 node 上
      （#{formula_opt_bin("bemly/tahoe/node")}/node）。

      启动 Web UI（默认 http://127.0.0.1:3080，本地启动会自动打开浏览器）：
        dsh web
      只起服务、不自动打开浏览器：
        dsh web --no-open

      注意：homebrew/core 有个同名但无关的公式 dsh（Dancer's shell），
      双方都提供 bin/dsh。若 core 的 dsh 已安装，本公式会 link 失败，
      二选一：
        用 DeepSeek Harness：brew uninstall dsh && brew link bemly/tahoe/deepseek-harness
        用 Dancer's shell：brew unlink bemly/tahoe/deepseek-harness && brew link dsh

      版本跟踪 npm 的 `latest` 标签（`updater/deepseek-harness.swift`），
      watcher 扫到更新会自动改写并重制瓶；`alpha` 预览版不追。
    EOS
  end

  test do
    # dsh 是 commander 启动器：--help 列出 web / plugin 等入口
    assert_match "web", shell_output("#{bin}/dsh --help")
    # web 子应用自带帮助（经 --profile web 透传），证明 Web 所需产物齐全
    assert_match(/web|Web|profile/i, shell_output("#{bin}/dsh web --help"))
  end
end
