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
    private static let lastCheckKey = "lastContentUpdateCheck"
    private static let checkInterval: TimeInterval = 6 * 60 * 60

    enum ContentError: Error {
        case badStatus(Int)
        case invalidVersion
        case invalidContent(String)
    }

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
    @discardableResult
    func refreshIfNeeded() async -> Bool {
        guard !isUpdating else { return false }
        if cachedVersion > 0,
           let lastCheck = UserDefaults.standard.object(forKey: Self.lastCheckKey) as? Date,
           Date().timeIntervalSince(lastCheck) < Self.checkInterval {
            return false
        }
        isUpdating = true
        lastError = nil
        defer { isUpdating = false }

        do {
            let remoteVersion = try await fetchRemoteVersion()
            UserDefaults.standard.set(Date(), forKey: Self.lastCheckKey)
            let cachedVersion = UserDefaults.standard.integer(forKey: Self.cachedVersionKey)

            if remoteVersion > cachedVersion {
                try await downloadContent()
                UserDefaults.standard.set(remoteVersion, forKey: Self.cachedVersionKey)
                return true
            }
        } catch {
            lastError = error.localizedDescription
            // Sessiz hata — bundle fallback çalışır
        }
        return false
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

    var bundledVersion: Int {
        guard let url = Bundle.main.url(forResource: "content-version", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let version = try? JSONDecoder().decode(ContentVersion.self, from: data).version else {
            return 0
        }
        return version
    }

    var shouldUseCachedContent: Bool {
        cachedVersion > 0 && cachedVersion >= bundledVersion
    }

    // MARK: - Private

    private func fetchRemoteVersion() async throws -> Int {
        let url = URL(string: "\(Self.repoBase)/\(Self.versionFileName)")!
        let data = try await fetchData(from: url)
        let versionInfo = try JSONDecoder().decode(ContentVersion.self, from: data)
        guard versionInfo.version > 0 else { throw ContentError.invalidVersion }
        return versionInfo.version
    }

    private func downloadContent() async throws {
        var downloads: [String: Data] = [:]

        for fileName in Self.contentFiles {
            let url = URL(string: "\(Self.repoBase)/\(fileName)")!
            let data = try await fetchData(from: url)
            guard Self.isValidContent(data, fileName: fileName) else {
                throw ContentError.invalidContent(fileName)
            }
            downloads[fileName] = data
        }

        // Tüm dosyalar indirilip doğrulandıktan sonra cache'e yazılır. Böylece ağ veya
        // şema hatasında eski, eksiksiz içerik seti kullanılmaya devam eder.
        for fileName in Self.contentFiles {
            guard let data = downloads[fileName] else {
                throw ContentError.invalidContent(fileName)
            }
            try data.write(to: cachedFileURL(fileName), options: .atomic)
        }
    }

    private func fetchData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw ContentError.badStatus((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return data
    }

    nonisolated static func isValidContent(_ data: Data, fileName: String) -> Bool {
        switch fileName {
        case "ayetler.json": return validItems((try? JSONDecoder().decode([Verse].self, from: data)) ?? [])
        case "dualar.json": return validItems((try? JSONDecoder().decode([Dua].self, from: data)) ?? [])
        case "hadisler.json": return validItems((try? JSONDecoder().decode([Hadith].self, from: data)) ?? [])
        case "esma.json": return validItems((try? JSONDecoder().decode([EsmaName].self, from: data)) ?? [])
        default: return false
        }
    }

    private nonisolated static func validItems<T: Identifiable>(_ items: [T]) -> Bool where T.ID: Hashable {
        !items.isEmpty && Set(items.map(\.id)).count == items.count
    }
}

// MARK: - Version JSON modeli

private struct ContentVersion: Decodable {
    let version: Int
}

extension Notification.Name {
    static let vakitContentUpdated = Notification.Name("vakitContentUpdated")
}
