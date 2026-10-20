class Wabt < Formula
  desc "Web Assembly Binary Toolkit"
  homepage "https://github.com/WebAssembly/wabt"
  # 代编译模式（core 拷入 + 双门槛，规则见 AGENTS.md 6 节 / 11.4 / 11.9）：
  # 上游 GitHub Releases 的 macOS 资产只有 macos-arm64（1.0.38 的 macos-14 包
  # 也是纯 arm64，下载 file 实测）——Intel Mac 上游零预编译可用；core 同样只有
  # arm64_tahoe / x86_64_linux 瓶，无 x86_64_tahoe。url 行即上游源码 release
  # 资产（与 core 同源同 sha）。
  # 文件名 wabt-1.0.42.tar.xz 自带全版本号，brew 扫描正确，不写 version 行（11.3）。
  # audit 的「至少一条 http 镜像」不触发：wabt 不在 core curl 递归依赖树里
  # （该 problem 仅在 curl_dep? 为真时出现，见 11.28 注释）。
  url "https://github.com/WebAssembly/wabt/releases/download/1.0.42/wabt-1.0.42.tar.xz"
  sha256 "a76cda3c174a43097863a07fc0b0c202f770f53e21806ea2636f167d1ffb1e30"
  license "Apache-2.0"
  revision 1

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "ce984267d68f7f58f146091058faf3ccc2c8728c52736aeb6b6c319bd7a065aa"
  end

  # 构建依赖走本 tap 全名：core 的 cmake 在 Intel Tahoe 无瓶（用户侧只能源码编，
  # 11.44），本 tap 的 cmake 是官方 universal 包、已出 GHCR 瓶，秒装。裸名按
  # brew 6 的 FromNameLoader 永远解析到 core（11.27），故指向本 tap 必须写全名。
  depends_on "bemly/tahoe/cmake" => :build
  # openssl@4 是生态枢纽（扇入 520+），裸名留给 core（11.49 同例；Intel 上无
  # tahoe 瓶时由 core 源码构建一次，tap 不复制枢纽）。
  depends_on arch: :x86_64
  depends_on arch: :x86_64
  depends_on macos: :tahoe
  depends_on "openssl@4"

  uses_from_macos "python" => :build

  # 本 tap 只收录 Intel(x86_64) + macOS 26(Tahoe) 及以上可用的软件（双门槛硬约束）。

  deny_network_access!

  # 以下 install / test 照抄 core 公式（编译行为与官方一致，杜绝手写出错）；
  # install 尾部补拆箱校验（brew 6 起 def post_install 已废弃，校验挪进 install
  # 尾部，见 11.37）。
  def install
    args = %w[
      -DBUILD_TESTS=OFF
      -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    ]
    args << "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" if OS.linux?

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    arch = Utils.safe_popen_read("file", "-b", (bin/"wat2wasm").to_s)
    odie "期望 x86_64，实际：#{arch}" unless arch.include?("x86_64")
    ver = Utils.safe_popen_read((bin/"wat2wasm").to_s, "--version").strip
    odie "wat2wasm --version 自检失败" if ver.blank?
    ohai "wabt #{ver}（#{arch.strip}）"
  end

  def caveats
    tools = %w[wat2wasm wasm2wat wasm2c wasm-interp wasm-validate wasm-objdump
               wasm-decompile wasm-strip wasm-stats wat-desugar wast2json]
    listing = tools.map { |t| "         #{t}" }.join("\n")
    <<~EOS
      已安装 WebAssembly Binary Toolkit 全套工具：

      #{listing}

      与 homebrew/core 的 wabt 同名，二者不能同时安装（11.4）。切换来源：
        用本 tap：brew unlink wabt && brew link --overwrite #{full_name}
        用 core ：brew unlink #{full_name} && brew link wabt
    EOS
  end

  test do
    (testpath/"sample.wast").write("(module (memory 1) (func))")
    assert_match version.to_s, shell_output("#{bin}/wat2wasm --version")
    system bin/"wat2wasm", testpath/"sample.wast"
    assert_path_exists testpath/"sample.wasm"
    assert_match "x86_64", shell_output("file -b #{bin}/wat2wasm")
    system bin/"wasm-validate", testpath/"sample.wasm"
  end
end
