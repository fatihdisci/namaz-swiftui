import Foundation
import Observation

/// Uygulama içi dil yönetimi.
/// İlk açılışta cihaz dili Türkçe → "tr", değilse → "en" (StorageService varsayılanı).
/// Dil değişince ilgili .lproj bundle'ı yüklenir; tüm view'lar `t(_:)` üzerinden
/// okuduğu için @Observable sayesinde anında yeniden çizilir.
@Observable
final class LanguageService {
    static let shared = LanguageService()

    private(set) var currentLanguage: String
    private var bundle: Bundle

    @ObservationIgnored private let storage: StorageService

    init(storage: StorageService = .shared) {
        self.storage = storage
        let language = storage.language
        self.currentLanguage = language
        self.bundle = Self.localizedBundle(language: language)
    }

    func setLanguage(_ code: String) {
        guard code != currentLanguage, ["tr", "en"].contains(code) else { return }
        currentLanguage = code
        storage.language = code
        bundle = Self.localizedBundle(language: code)
        // Sistem tarafı (bildirim içerikleri vb.) bir sonraki açılışta da bu dili kullansın.
        UserDefaults.standard.set([code], forKey: "AppleLanguages")
    }

    /// Verilen dilin .lproj bundle'ı. Bulunamazsa ana bundle'a düşer.
    static func localizedBundle(language: String) -> Bundle {
        guard
            let path = Bundle.main.path(forResource: language, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else { return .main }
        return bundle
    }

    /// String Catalog'dan çeviri. Anahtar bulunamazsa anahtarın kendisi döner.
    func t(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    /// Format argümanlı çeviri (örn. "%lddk sonra").
    func t(_ key: String, _ args: CVarArg...) -> String {
        String(format: t(key), arguments: args)
    }
}
