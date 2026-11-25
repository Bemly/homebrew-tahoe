import Foundation

@main
struct LlamaCppCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "llama.cpp",
            gitHeadRepo: "Bemly/llama.cpp",
            gitHeadBranch: "main"
        ))
    }
}
