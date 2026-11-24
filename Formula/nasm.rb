class Nasm < Formula
  desc "Netwide Assembler prebuilt for Intel macOS"
  homepage "https://www.nasm.us/"
  url "https://www.nasm.us/pub/nasm/releasebuilds/3.02/macosx/nasm-3.02-macosx.zip"
  sha256 "4c1bbb09853f5f5ffc9b7832cbc9366c4761bc79ce7ffb148b0e427e5f3fa114"
  license "BSD-2-Clause"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "3817cc62ce5d07ec4d956a0a864d5fe1f44a36263825cba228e6b0e8f656f2a2"
    sha256 cellar: :any_skip_relocation, tahoe: "14aad678884d6d934b5b5ecdbf07c85cedd8c34cc70dce939f81d7cb4cf18c6f"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  deny_network_access!

  def install
    %w[nasm ndisasm].each do |name|
      binary = Pathname(Dir["**/#{name}"].fetch(0))
      system "lipo", "-thin", "x86_64", binary, "-o", "#{binary}.thin"
      File.rename("#{binary}.thin", binary)
      system "codesign", "--force", "--sign", "-", binary
      bin.install binary
    end
    man1.install Dir["**/man1/*.1"]
    doc.install Dir["**/LICENSE"].fetch(0), Dir["**/nasmdoc.pdf"].fetch(0)

    chmod 0555, bin/"nasm"
    chmod 0555, bin/"ndisasm"
    odie "NASM 架构或版本自检失败" unless Utils.safe_popen_read(bin/"nasm", "-v").include?("NASM version 3.02")
  end

  test do
    (testpath/"foo.s").write <<~ASM
      mov eax, 0
      mov ebx, 0
      int 0x80
    ASM
    system bin/"nasm", "foo.s"
    code = File.open(testpath/"foo", "rb") { |f| f.read.unpack("C*") }
    expected = [0x66, 0xb8, 0x00, 0x00, 0x00, 0x00, 0x66, 0xbb,
                0x00, 0x00, 0x00, 0x00, 0xcd, 0x80]
    assert_equal expected, code
  end
end
