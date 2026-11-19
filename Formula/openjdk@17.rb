class OpenjdkAT17 < Formula
  desc "Development kit for the Java programming language (Eclipse Temurin)"
  homepage "https://adoptium.net/"
  url "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.21%2B9/OpenJDK17U-jdk_x64_mac_hotspot_17.0.21_9.tar.gz"
  version "17.0.21"
  sha256 "868f5c672b3389fdbe48e44f94ae170f01668b1401360944fc7159d7cc9772cc"
  license "GPL-2.0-only" => { with: "Classpath-exception-2.0" }
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any, tahoe: "2534a071b8f4805e30d34ef368059f4e83605dfd3c7859a983456dfe4d7ee00d"
  end

  keg_only "bottled by bemly/tahoe; avoid auto-link conflicts with core"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    home = Dir["**/Contents/Home"].fetch(0)
    prefix.install Dir[File.join(home, "*")]
  end

  test do
    assert_match "17.0.21", shell_output("#{bin}/java -version 2>&1")
  end
end
