import Foundation

@main
struct AudioCppCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "audio.cpp",
            gitHeadRepo: "Bemly/audio.cpp",
            gitHeadBranch: "main"
        ))
    }
}
