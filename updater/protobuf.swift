// updater/protobuf.swift —— 与 Formula/protobuf.rb 一一同名的检查器入口

import Foundation

@main
struct ProtobufCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "protobuf",
            downloadURL: { "https://github.com/protocolbuffers/protobuf/releases/download/v\($0)/protoc-\($0)-osx-x86_64.zip" },
            githubRepo: "protocolbuffers/protobuf"))
    }
}
