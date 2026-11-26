class Docker < Formula
  desc "Pack, ship and run any application as a lightweight container"
  homepage "https://www.docker.com/"
  url "https://download.docker.com/mac/static/stable/x86_64/docker-29.10.1.tgz"
  sha256 "3dc940c19679e254a9d03930af5fa03aeff14b35200b0d5945e1b018eba60e7f"
  license "Apache-2.0"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "eef36dd7a8b876598951f518dc883cffb642e8e70766b1ca1e9faaef35b200cf"
    sha256 cellar: :any_skip_relocation, tahoe: "268a0b0e9e733c814c6dbb3a20bc593c5a3f54bbbb08f2fbc8f41b222e549bd9"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    bin.install "docker"
    generate_completions_from_executable(bin/"docker", "completion")
  end

  test do
    assert_match "Docker version #{version}", shell_output("#{bin}/docker --version")
  end
end
