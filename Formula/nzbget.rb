class Nzbget < Formula
  desc "Binary newsgrabber for nzb files"
  homepage "https://nzbget.com/"
  license "GPL-2.0-or-later"
  version "26.3"
  url "https://github.com/nzbgetcom/nzbget/releases/download/v#{version}/nzbget-#{version}-bin-macos-x64.zip"
  sha256 "d3f5a2b520d9a40e9821272b1564ac031857e1032a7aec9bb37c913b3ffc1e69"

  depends_on "bemly/tahoe/sevenzip"
  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    root = Pathname(Dir["**/Resources/daemon/usr/local"].fetch(0))
    bin.install root/"bin/nzbget"
    share.install root/"share/nzbget"
    doc.install share/"nzbget/doc/ChangeLog.md", share/"nzbget/doc/COPYING"

    inreplace share/"nzbget/nzbget.conf" do |s|
      s.gsub! "DirectWrite=yes", "DirectWrite=no"
      s.gsub! "ArticleCache=0", "ArticleCache=700"
      s.gsub! "SevenZipCmd=${AppDir}/7za", "SevenZipCmd=7zz"
      s.gsub! "UnrarCmd=${AppDir}/unrar", "UnrarCmd=7zz"
    end
    etc.install share/"nzbget/nzbget.conf"

    chmod 0555, bin/"nzbget"
    odie "NZBGet 架构或版本自检失败" unless Utils.safe_popen_read(bin/"nzbget", "-V").include?(version.to_s)
  end

  service do
    run [opt_bin/"nzbget", "-c", etc/"nzbget.conf", "-s", "-o", "OutputMode=Log",
         "-o", "ConfigTemplate=#{etc}/nzbget.conf",
         "-o", "WebDir=#{opt_prefix}/share/nzbget/webui"]
    keep_alive true
    environment_variables PATH: "#{HOMEBREW_PREFIX}/bin:/usr/bin:/bin:/usr/sbin:/sbin"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/nzbget -V")
  end
end
