class Ldid < Formula
  desc "Lets you manipulate the signature block in a Mach-O binary"
  homepage "https://cydia.saurik.com/info/ldid/"
  url "git://git.saurik.com/ldid.git",
      tag:      "v2.1.5",
      revision: "a23f0faadd29ec00a6b7fb2498c3d15af15a7100"
  license "AGPL-3.0-or-later"
  revision 2
  head "git://git.saurik.com/ldid.git", branch: "master"

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "00f18d94d02d2fb55973ea6ae6db085fdd14a5397dfaec0dc0df8b1a994ef574"
    sha256 cellar: :any, tahoe: "57568339fec37b76b56ca59365dbcce3a665625cd871c7fb2dc73fa8a953ea43"
  end

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libplist"
  depends_on macos: :tahoe
  depends_on "bemly/tahoe/openssl@3"

  conflicts_with "ldid-procursus", because: "ldid-procursus installs a conflicting ldid binary"

  def install
    openssl = formula_opt_prefix("bemly/tahoe/openssl@3")
    ENV.append_to_cflags "-I."
    ENV.append "CXXFLAGS", "-std=c++11 -I#{openssl}/include"
    linker_flags = ["lookup2.o", "-L#{openssl}/lib", "-lcrypto",
                    "-L#{formula_opt_lib("bemly/tahoe/libplist")}", "-lplist-2.0"]

    system "make", "lookup2.o"
    system "make", "ldid", "LDLIBS=#{linker_flags.join(" ")}"

    bin.install "ldid"
    bin.install_symlink "ldid" => "ldid2"
  end

  test do
    cp test_fixtures("mach/a.out"), testpath
    system bin/"ldid", "-S", "a.out"
  end
end
