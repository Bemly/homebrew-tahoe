class Jadx < Formula
  desc "Dex to Java decompiler"
  homepage "https://github.com/skylot/jadx"
  url "https://github.com/skylot/jadx/releases/download/v1.5.7/jadx-1.5.7.zip"
  sha256 "1755e4242ade71a077438723689f404079592ec7764a3a0572f98fef94ebcbf3"
  license "Apache-2.0"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "b6a80386410ce2f27b8cdc2168fb053b759d58c31317b67f699bc4b45aabb067"
  end

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/openjdk"
  depends_on macos: :tahoe

  def install
    libexec.install Dir["*"]
    env = { JAVA_HOME: "${JAVA_HOME:-#{Formula["bemly/tahoe/openjdk"].opt_prefix}}" }
    (bin/"jadx").write_env_script libexec/"bin/jadx", env
    (bin/"jadx-gui").write_env_script libexec/"bin/jadx-gui", env
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/jadx --version")
  end
end
