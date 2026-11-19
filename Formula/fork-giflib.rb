class ForkGiflib < Formula
  desc "Library and utilities for processing GIFs"
  homepage "https://giflib.sourceforge.net/"
  url "https://downloads.sourceforge.net/project/giflib/giflib-6.x/giflib-6.1.3.tar.gz"
  sha256 "b65b66b99f0424b93525f987386f22fc5efb9da2bfc92ad4a532249aaffbab0e"
  license "MIT"
  compatibility_version 1

  livecheck do
    url :stable
    regex(%r{url=.*?/giflib[._-]v?(\d+(?:\.\d+)+)\.t}i)
  end

  keg_only "forked dependency of bemly/tahoe; avoid symlink conflicts with homebrew/core"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    args = ["PREFIX=#{prefix}"]
    # Manually skipping shared libutil due to https://sourceforge.net/p/giflib/bugs/189/.
    # It is currently unused (binaries link to libutil.a) and not installed.
    args << "LIBUTILSO=" if OS.mac?

    system "make", "all", *args
    ENV.deparallelize # avoid parallel mkdir
    system "make", "install", *args
  end

  test do
    output = shell_output("#{bin}/giftext #{test_fixtures("test.gif")}")
    assert_match "Screen Size - Width = 1, Height = 1", output
  end
end
