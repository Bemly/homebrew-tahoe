class PostgresqlAT13 < Formula
  desc "Object-relational database system (EDB macOS x64 binaries, repackaged)"
  homepage "https://www.postgresql.org/"
  url "https://get.enterprisedb.com/postgresql/postgresql-13.23-1-osx-binaries.zip"
  sha256 "622604b1bb62f74ef5e7fca733d741f3fdd2db73ac4c2b51b43e154d5c651679"
  license "PostgreSQL"

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    # brew 会自动下降进唯一顶层 pgsql 目录，兼容两种 CWD
    root = Dir["**/pgsql"].first || "."
    prefix.install Dir[File.join(root, "*")]
  end

  test do
    assert_match "13.23", shell_output("#{bin}/postgres --version")
  end
end
