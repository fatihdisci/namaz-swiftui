import Foundation

/// App Store Connect identifiers used by user-facing App Store links.
enum AppStoreConfig {
    /// Numeric Apple ID from App Store Connect → App Information → Apple ID.
    /// Replace `APP_STORE_ID` before release if App Store Connect ID is not present in repo metadata.
    static let appStoreID = "APP_STORE_ID"

    static var writeReviewURL: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
    }
}
