import Foundation

@main
struct ToshLLMCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "toshllm",
            formulaPath: "Casks",
            isCask: true,
            gitHeadRepo: "Bemly/toshllm",
            gitHeadBranch: "main"
        ))
    }
}
