import Foundation

@main
struct IdeviceinstallerCheck {
    static func main() {
        runCheck(CheckConfig(formula: "ideviceinstaller", brewName: "ideviceinstaller"))
    }
}
