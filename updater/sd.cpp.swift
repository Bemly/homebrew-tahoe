import Foundation

@main
struct SdCppCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "sd.cpp",
            gitHeadRepo: "Bemly/stable-diffusion.cpp",
            gitHeadBranch: "main"
        ))
    }
}
