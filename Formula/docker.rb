class Docker < Formula
  desc "Pack, ship and run any application as a lightweight container"
  homepage "https://www.docker.com/"
  url "https://download.docker.com/mac/static/stable/x86_64/docker-29.10.0.tgz"
  sha256 "18fd600a2fc0bc2e62f34f66b0fd717dc2a774aa533bf3cef98011b9d37e0459"
  license "Apache-2.0"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "8cca0e72626a99b507459cae1884418436435435eea1ffadc41b440d1dac7afc"
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
