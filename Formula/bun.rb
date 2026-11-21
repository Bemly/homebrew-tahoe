class Bun < Formula
  desc "Incredibly fast JavaScript runtime, bundler, test runner, and package manager"
  homepage "https://bun.com/"
  url "https://github.com/oven-sh/bun/releases/download/bun-v1.4.5/bun-darwin-x64.zip"
  version "1.4.5"
  sha256 "a4972e778cce4b6a194d7d289f326aa61576d71d80b7a53e9da2f3739566e5fd"
  license "MIT"
  compatibility_version 1

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    bin.install "bun"
    bin.install_symlink "bun" => "bunx"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/bun --version")
  end
end
