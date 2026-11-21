class Xcodegen < Formula
  desc "Generate your Xcode project from a spec file and your folder structure"
  homepage "https://github.com/yonaskolb/XcodeGen"
  url "https://github.com/yonaskolb/XcodeGen/releases/download/2.48.0/xcodegen.zip"
  sha256 "620c9f0dc10849f94728ab5df52d225ebab8187439dd6fee1925e59e80dff892"
  license "MIT"
  compatibility_version 1

  bottle do
    root_url "https://ghcr.io/v2/bemly/tahoe"
    sha256 cellar: :any_skip_relocation, tahoe: "102978fcca524339bd3fae2e86d0a45a3ef7f7dd17fa9752b153b4c90b6da720"
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
