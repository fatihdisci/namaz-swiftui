import Foundation

/// App Store Connect identifiers used by user-facing App Store links.
enum AppStoreConfig {
    /// Numeric Apple ID from App Store Connect → App Information → Apple ID.
    static let appStoreID = "6779243966"

    static var writeReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }
}
