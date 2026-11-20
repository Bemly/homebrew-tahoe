class PostgresqlAT13 < Formula
  desc "Object-relational database system (EDB macOS x64 binaries, repackaged)"
  homepage "https://www.postgresql.org/"
  url "https://get.enterprisedb.com/postgresql/postgresql-13.23-1-osx-binaries.zip"
  sha256 "622604b1bb62f74ef5e7fca733d741f3fdd2db73ac4c2b51b43e154d5c651679"
  license "PostgreSQL"

  keg_only "bundled openssl/icu libraries conflict with core formula"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  # EDB 包自带 openssl/icu 动态库和头文件，link 到 /usr/local 会撞 core openssl@3

  def install
    # brew 会自动下降进唯一顶层 pgsql 目录，兼容两种 CWD
    root = Dir["**/pgsql"].first || "."
    %w[bin include lib share].each do |dir|
      src = File.join(root, dir)
      files = Dir[File.join(src, "*")]
      send(dir).install files unless files.empty?
    end
  end

  test do
    assert_match "13.23", shell_output("#{bin}/postgres --version")
  end

  caveats <<~EOS
    EDB 二进制包自带 openssl/icu，未链接到 /usr/local 以避免撞 core openssl@3。
    要用其中的命令请把 /usr/local/opt/postgresql@13/bin 加进 PATH，或用绝对路径调用。
  EOS
end
