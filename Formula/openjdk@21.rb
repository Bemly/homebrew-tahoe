class OpenjdkAT21 < Formula
  desc "Development kit for the Java programming language (Eclipse Temurin)"
  homepage "https://adoptium.net/"
  url "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.13%2B9/OpenJDK21U-jdk_x64_mac_hotspot_21.0.13_9.tar.gz"
  version "21.0.13"
  sha256 "9aa1d1c17ae5467a022679e7e0af5c00797d94ac462ed1a46f4db07a8a34a6dd"
  license "GPL-2.0-only" => { with: "Classpath-exception-2.0" }
  compatibility_version 1

  keg_only "bottled by bemly/tahoe; avoid auto-link conflicts with core"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    home = Dir["**/Contents/Home"].fetch(0)
    prefix.install Dir[File.join(home, "*")]
  end

  test do
    assert_match "21.0.13", shell_output("#{bin}/java -version 2>&1")
  end
end
