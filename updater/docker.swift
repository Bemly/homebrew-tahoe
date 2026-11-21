// updater/docker.swift —— 与 Formula/docker.rb 一一同名的检查器入口

import Foundation

@main
struct DockerCheck {
    static func main() {
        runCheck(CheckConfig(
            formula: "docker",
            brewName: "docker",
            downloadURL: { "https://download.docker.com/mac/static/stable/x86_64/docker-\($0).tgz" },
            checksumsURL: nil))
    }
}
