class Socat < Formula
  desc "SOcket CAT: netcat on steroids"
  homepage "http://www.dest-unreach.org/socat/"
  url "https://distfiles.alpinelinux.org/distfiles/edge/socat-1.8.1.3.tar.gz"
  mirror "http://www.dest-unreach.org/socat/download/socat-1.8.1.3.tar.gz"
  sha256 "06602ffd591e98c75b3dc1d66f0f19136cc666b0b2d95caad987d6ab2cb28097"
  license "GPL-2.0-only"
  compatibility_version 1

  livecheck do
    url "http://www.dest-unreach.org/socat/download/"
    regex(/href=.*?socat[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe
  depends_on "openssl@3"

  def install
    # NOTE: readline must be disabled as the license is incompatible with GPL-2.0-only,
    # https://www.gnu.org/licenses/gpl-faq.html#AllCompatibility
    system "./configure", "--disable-readline", *std_configure_args
    system "make", "install"
  end

  test do
    # core 的用例连 www.google.com:80 取首行——依赖外部明文 HTTP，
    # 在代理/沙箱环境下对端建连后不回数据，会 hang 到超时；且单测本就不该
    # 依赖公网。改走本机回环：listener EXEC:cat 原样回显，断言往返一致。
    port = free_port
    listener = spawn bin/"socat", "TCP-LISTEN:#{port},reuseaddr", "EXEC:cat"
    sleep 2
    output = pipe_output("#{bin}/socat - TCP:127.0.0.1:#{port}", "hello")
    assert_equal "hello", output
  ensure
    Process.kill("TERM", listener)
    Process.wait(listener)
  end
end
