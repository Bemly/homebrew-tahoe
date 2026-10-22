// updater/aarch64-unknown-linux-gnu.swift —— 与 Formula/aarch64-unknown-linux-gnu.rb 一一同名的检查器入口
//
// messense/homebrew-macos-cross-toolchains 的 aarch64-unknown-linux-gnu 交叉工具链，
// 不在 homebrew/core，走 UpdaterCore 的 github 流：版本判据是
// messense/homebrew-macos-cross-toolchains 的 releases/latest 跳转目标 tag
//（不跟随、不耗 GitHub API 限额）。tag 带 v 前缀（如 v15.2.0），默认剥离。
// 本 tap 只收 Intel host 段（x86_64-darwin），ARM 段不收（见 11.27 sst 同例）。
// 下载源是版本化直链（releases/download/v<ver>/aarch64-unknown-linux-gnu-x86_64-darwin.tar.gz）；
// 上游有单文件 .sha256 sidecar（"<sha>  <filename>"），checksumsURL 指向它，
// 核心按 asset 精确匹配取 sha（免 203MB 下载实算，仅新版本时取 100B 级 sidecar）。
// 改写：文件名无版本、版本只在路径 v<ver>/ 段，版本子串替换只换路径段；
// 公式有显式 version 行（文件名扫不出版本，见 11.3），核心同步改写。
//
// 注意：Swift 要求实参顺序与 CheckConfig.init 的形参声明一致.

import Foundation

@main
struct Aarch64UnknownLinuxGnuCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "aarch64-unknown-linux-gnu",
            asset: { version in
                "aarch64-unknown-linux-gnu-x86_64-darwin.tar.gz"
            },
            downloadURL: { version in
                "https://github.com/messense/homebrew-macos-cross-toolchains/releases/download/v\(version)/aarch64-unknown-linux-gnu-x86_64-darwin.tar.gz"
            },
            checksumsURL: { version in
                "https://github.com/messense/homebrew-macos-cross-toolchains/releases/download/v\(version)/aarch64-unknown-linux-gnu-x86_64-darwin.tar.gz.sha256"
            },
            githubRepo: "messense/homebrew-macos-cross-toolchains",
            githubTagPrefix: "v"
        ))
    }
}
