class Starship < Formula
  desc "Cross-shell prompt for astronauts"
  homepage "https://starship.rs/"
  url "https://github.com/starship/starship/releases/download/v1.27.0/starship-x86_64-apple-darwin.tar.gz"
  sha256 "344e4d38787e0aa86dd522ae5462e6fb6da1227691f81a79ffed480a4563ccb3"
  license "ISC"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    bin.install "starship"
    generate_completions_from_executable(bin/"starship", "completions")
  end

  test do
    ENV["STARSHIP_CONFIG"] = ""
    assert_equal "❯ ", shell_output("#{bin}/starship module character")
  end
end
