class Xcodegen < Formula
  desc "Generate your Xcode project from a spec file and your folder structure"
  homepage "https://github.com/yonaskolb/XcodeGen"
  url "https://github.com/yonaskolb/XcodeGen/releases/download/2.49.0/xcodegen.zip"
  sha256 "ae5598b33a19ad1e23e775d6648f97375c3529c970905f489358a21055b65e53"
  license "MIT"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    manifest_sha256 "61cd46cedba5bbdd5b9420509a57d87977dfe29ebef1f899febee8323c4ce416"
    sha256 cellar: :any_skip_relocation, tahoe: "1ffdf6bd88e61c1ef2122e6bee0167ce0abaadd7f4aa8602697e4ddd3696aa5e"
  end

  depends_on arch: :x86_64
  depends_on macos: :tahoe

  def install
    bin.install "bin/xcodegen"
    pkgshare.install "share/xcodegen/SettingPresets"
  end

  test do
    (testpath/"xcodegen.yml").write <<~YAML
      name: GeneratedProject
      options:
        bundleIdPrefix: com.project
      targets:
        TestProject:
          type: application
          platform: iOS
          sources: TestProject
    YAML
    (testpath/"TestProject").mkpath
    system bin/"xcodegen", "--spec", testpath/"xcodegen.yml"
    assert_path_exists testpath/"GeneratedProject.xcodeproj"
    assert_path_exists testpath/"GeneratedProject.xcodeproj/project.pbxproj"
    output = (testpath/"GeneratedProject.xcodeproj/project.pbxproj").read
    assert_match "name = TestProject", output
    assert_match "isa = PBXNativeTarget", output
  end
end
