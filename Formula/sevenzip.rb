class Sevenzip < Formula
  desc "7-Zip is a file archiver with a high compression ratio"
  homepage "https://www.7-zip.org/"
  version "26.06"
  sha256 "3af68b124052da7fc2a246c96b0bea6a68bfee389baa788f4cead1a133445586"
  license all_of: ["LGPL-2.1-or-later", "BSD-3-Clause"]

  url "https://github.com/ip7z/7zip/releases/download/#{version}/7z#{version.to_s.delete(".")}-mac-x64.tar.xz"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "338aff4d774d061d13ccc5e0cd1ad0677702613013bb5d736c4aedd642d4b270"
    sha256 cellar: :any_skip_relocation, tahoe: "2190ef8638d74cd14abe1980e936f71094b6a06d2f3d4073a88ef134196d34f5"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    bin.install "7zz"
    doc.install "readme.txt", "History.txt", "License.txt"
  end

  test do
    (testpath/"foo.txt").write("hello world!\n")
    system bin/"7zz", "a", "-t7z", "foo.7z", "foo.txt"
    system bin/"7zz", "x", "foo.7z", "-oout"
    assert_equal "hello world!\n", (testpath/"out/foo.txt").read
  end
end
