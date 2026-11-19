// updater/z3.swift —— 与 Formula/z3.rb 一一同名的检查器入口

import Foundation

@main
struct Z3Check {
    static func main() {
        runCheck(CheckConfig(
            formula: "z3",
            downloadURL: { "https://github.com/Z3Prover/z3/releases/download/z3-\($0)/z3-\($0)-x64-osx-13.3.zip" },
            githubRepo: "Z3Prover/z3",
            githubTagPrefix: "z3-"))
    }
}
