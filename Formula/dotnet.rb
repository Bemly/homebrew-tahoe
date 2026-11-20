class Dotnet < Formula
  desc ".NET SDK (official macOS x64 tarball, repackaged)"
  homepage "https://dotnet.microsoft.com/"
  url "https://builds.dotnet.microsoft.com/dotnet/Sdk/11.0.100/dotnet-sdk-11.0.100-osx-x64.tar.gz"
  sha256 "7e2adb537cf3259e75261c6a2f45e4aeb461e4974573ae8ffb7b1b70f0e652f1"
  license "MIT"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    prefix.install Dir["*"]
    bin.write_exec_script prefix/"dotnet"
    chmod 0555, bin/"dotnet"
  end

  test do
    assert_match "11.0.100", shell_output("#{bin}/dotnet --version")
  end
end
