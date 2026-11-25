import Foundation

@main
struct LibzipCheck {
    static func main() {
        runCheck(CheckConfig(formula: "libzip", brewName: "libzip"))
    }
}
