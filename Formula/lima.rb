class Lima < Formula
  desc "Linux virtual machines"
  homepage "https://lima-vm.io/"
  url "https://github.com/lima-vm/lima/releases/download/v2.3.0/lima-2.3.0-Darwin-x86_64.tar.gz"
  sha256 "d58bc7d6b8158d638720d8c8fdb17eb58527dfead6a29a5b60f48a35ee4a65a6"
  license "Apache-2.0"
  compatibility_version 1

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    bin.install Dir["bin/*"]
    libexec.install Dir["libexec/*"]
    share.install Dir["share/*"]
    generate_completions_from_executable(bin/"limactl", "completion")
  end

  test do
    assert_match "limactl version #{version}", shell_output("#{bin}/limactl --version")
  end
end
