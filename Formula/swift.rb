class Swift < Formula
  desc "Open-source Swift toolchain (official macOS package, repackaged)"
  homepage "https://swift.org/"
  url "https://download.swift.org/swift-6.4.2-release/xcode/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE-osx.pkg"
  sha256 "0a7d8489900d21dbf5f0187cb570e646a4c0226d0ddef2cbde8c7f54dfe79736"
  license "Apache-2.0"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "c80cc3b3006eeba238e7a22fd8530e2b4910633fe92423be78f9560d7bfbac25"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    pkg = Dir["*.pkg"].fetch(0)
    stage = buildpath/"swift-stage"
    system "pkgutil", "--expand-full", pkg, stage
    payload = Dir[stage/"*-osx-package.pkg/Payload"].fetch(0)
    toolchain = libexec/"toolchain"
    toolchain.install Dir[File.join(payload, "usr", "*")]
    # 工具链 bin 里有 clang/lldb 等，link 到 prefix/bin 会撞其它公式；
    # 只暴露 swift/swiftc，走 exec 脚本保证 @rpath 按真实路径解析。
    %w[swift swiftc].each { |name| bin.write_exec_script toolchain/"bin"/name }
  end

  test do
    assert_match "6.4.2", shell_output("#{bin}/swift --version 2>&1")
  end
end
