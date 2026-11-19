// updater/fzf.swift —— 与 Formula/fzf.rb 一一同名的检查器入口
// 跟随上游 GitHub release 的 darwin_amd64 预编译包，不钉死版本。

import Foundation

@main
struct FzfCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "fzf",
            downloadURL: { "https://github.com/junegunn/fzf/releases/download/v\($0)/fzf-\($0)-darwin_amd64.tar.gz" },
            githubRepo: "junegunn/fzf"))
    }
}
