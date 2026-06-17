import Foundation

/// Remote içerik yöneticisi.
/// GitHub raw'dan JSON'ları çeker, cihaza cache'ler.
/// İnternet yoksa veya hata olursa sessizce başarısız olur — DailyContent bundle fallback'i kullanır.
@Observable
@MainActor
final class RemoteContentService {
    static let shared = RemoteContentService()

    // MARK: - Sabitler

    private static let repoBase = "https://raw.githubusercontent.com/fatihdisci/namaz-swiftui/main/content"
    private static let contentFiles = ["ayetler.json", "dualar.json", "hadisler.json", "esma.json"]
    private static let versionFileName = "content-version.json"
    private static let cachedVersionKey = "cachedContentVersion"

    // MARK: - Durum

    private(set) var isUpdating = false
    private(set) var lastError: String?

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Cache Yolu

    /// Cache dizini: Documents/cached-content/
    private static nonisolated func _cacheDir() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dir = docs.appendingPathComponent("cached-content", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func cachedFileURL(_ fileName: String) -> URL {
        Self._cacheDir().appendingPathComponent(fileName)
    }

    // MARK: - Public API

    /// Uygulama açılışında çağır. İnternet varsa günceller, yoksa sessizce döner.
    func refreshIfNeeded() async {
        guard !isUpdating else { return }
        isUpdating = true
        lastError = nil
        defer { isUpdating = false }

        do {
            let remoteVersion = try await fetchRemoteVersion()
            let cachedVersion = UserDefaults.standard.integer(forKey: Self.cachedVersionKey)

            if remoteVersion > cachedVersion {
                try await downloadContent(version: remoteVersion)
                UserDefaults.standard.set(remoteVersion, forKey: Self.cachedVersionKey)
            }
        } catch {
            lastError = error.localizedDescription
            // Sessiz hata — bundle fallback çalışır
        }
    }

    /// Cache'lenmiş JSON'u oku. Yoksa nil.
    nonisolated func cachedJSON(_ fileName: String) -> Data? {
        let url = Self._cacheDir().appendingPathComponent(fileName)
        return try? Data(contentsOf: url)
    }

    /// Cache'lenmiş ve decode edilmiş içeriği döndür. Yoksa nil.
    nonisolated func cachedContent<T: Decodable>(_ fileName: String) -> [T]? {
        guard let data = cachedJSON(fileName) else { return nil }
        return try? JSONDecoder().decode([T].self, from: data)
    }

    /// Cache'lenmiş versiyon numarası. 0 = hiç cache yok.
    var cachedVersion: Int {
        UserDefaults.standard.integer(forKey: Self.cachedVersionKey)
    }

    // MARK: - Private

    private func fetchRemoteVersion() async throws -> Int {
        let url = URL(string: "\(Self.repoBase)/\(Self.versionFileName)")!
        let (data, _) = try await session.data(from: url)
        let versionInfo = try JSONDecoder().decode(ContentVersion.self, from: data)
        return versionInfo.version
    }

    private func downloadContent(version: Int) async throws {
        for fileName in Self.contentFiles {
            let url = URL(string: "\(Self.repoBase)/\(fileName)")!
            let (data, _) = try await session.data(from: url)
            try data.write(to: cachedFileURL(fileName), options: .atomic)
        }
    }
}

// MARK: - Version JSON modeli

private struct ContentVersion: Decodable {
    let version: Int
}
