class Ldid < Formula
  desc "Lets you manipulate the signature block in a Mach-O binary"
  homepage "https://cydia.saurik.com/info/ldid/"
  url "git://git.saurik.com/ldid.git",
      tag:      "v2.1.5",
      revision: "a23f0faadd29ec00a6b7fb2498c3d15af15a7100"
  license "AGPL-3.0-or-later"
  revision 2
  head "git://git.saurik.com/ldid.git", branch: "master"

  depends_on arch: :x86_64
  depends_on "bemly/tahoe/libplist"
  depends_on macos: :tahoe
  depends_on "bemly/tahoe/openssl@3"

  conflicts_with "ldid-procursus", because: "ldid-procursus installs a conflicting ldid binary"

  def install
    openssl = formula_opt_prefix("bemly/tahoe/openssl@3")
    ENV.prepend "CPPFLAGS", "-I#{openssl}/include"
    ENV.prepend "LDFLAGS", "-L#{openssl}/lib"
    ENV.append_to_cflags "-I."
    ENV.append "CXXFLAGS", "-std=c++11"
    linker_flags = %w[lookup2.o -lcrypto -lplist-2.0]

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
