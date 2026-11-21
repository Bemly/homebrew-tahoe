class Lima < Formula
  desc "Linux virtual machines"
  homepage "https://lima-vm.io/"
  url "https://github.com/lima-vm/lima/releases/download/v2.3.0/lima-2.3.0-Darwin-x86_64.tar.gz"
  sha256 "d58bc7d6b8158d638720d8c8fdb17eb58527dfead6a29a5b60f48a35ee4a65a6"
  license "Apache-2.0"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "e1f5a113d163c0d446198630833798f540a68eff63c5e52bd98380d4bfdc89df"
  end

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
