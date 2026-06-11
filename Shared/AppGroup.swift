import Foundation

enum AppGroup {
    static let identifier = "group.com.fatihdisci.vakit.shared"

    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}
