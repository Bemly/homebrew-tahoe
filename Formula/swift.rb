class Swift < Formula
  desc "Open-source Swift toolchain (official macOS package, repackaged)"
  homepage "https://swift.org/"
  url "https://download.swift.org/swift-6.4.3-release/xcode/swift-6.4.3-RELEASE/swift-6.4.3-RELEASE-osx.pkg"
  sha256 "ccbfc46b166625613286abfa63b6e974b5b6a7c2205e5bc9e52d09f6e051e859"
  license "Apache-2.0"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "fd1dd27c43829a6080d9afa8aabbf043af26171726b9e5fac3b03ffa7952e2cf"
    sha256 cellar: :any, tahoe: "529824889e2d515323a3135d2158cd85ef894bfafb711cca633504ed8b48895b"
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
