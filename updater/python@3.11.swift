// updater/python@3.11.swift —— 与 Formula/python@3.11.rb 一一同名的检查器入口

import Foundation

@main
struct PythonAT311Check {
    static func main() {
        runCheck(CheckConfig(formula: "python@3.11", brewName: "python@3.11"))
    }
}
