import AVFoundation
import Foundation

/// Hafız tilaveti (Kur'an ses) servisi.
///
/// - Arapça metin uygulama içinde çalınmaz; alquran.cloud API'sinden tek seferlik
///   `scripts/fill_ayet_audio.py` ile JSON'a yazılır (runtime'da metin için ağa gidilmez).
/// - Ses, çalışma anında `cdn.islamic.network` üzerinden stream edilir. İlk dinlemede
///   dosya opportünist olarak Caches dizinine yazılır; aynı ayet tekrar dinlenince ağa
///   gidilmeden yerel kopyadan çalınır (basit cache, kalıcı offline mod değil).
///
/// Reciter: Mishary Alafasy (`ar.alafasy`). Kaynak: Islamic Network (islamic.network).
final class QuranAudioService {
    static let shared = QuranAudioService()

    /// Varsayılan hafız edition kimliği (CDN).
    static let defaultReciter = "ar.alafasy"
    /// Varsayılan ses bit hızı (kbps). 128 = mobil veri için iyi denge.
    static let defaultBitrate = 128
    /// Kullanıcıya gösterilecek hafız adı (atıf/credit).
    static let reciterDisplayName = "Mishary Alafasy"

    private static let cdnBase = "https://cdn.islamic.network/quran/audio"
    private static let apiBase = "https://api.alquran.cloud/v1/ayah"

    enum AudioError: LocalizedError {
        case badStatus(Int)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .badStatus(let code): return "Sunucu hatası (\(code))"
            case .invalidResponse: return "Geçersiz yanıt"
            }
        }
    }

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - URL oluşturma (saf, ağ gerektirmez — birim test edilebilir)

    /// Global ayet numarasından (1-6236) hafız ses CDN URL'ini oluşturur.
    /// Örn. 52 → https://cdn.islamic.network/quran/audio/128/ar.alafasy/52.mp3
    func audioURL(
        globalAyahNumber: Int,
        bitrate: Int = QuranAudioService.defaultBitrate,
        reciter: String = QuranAudioService.defaultReciter
    ) -> URL {
        URL(string: "\(Self.cdnBase)/\(bitrate)/\(reciter)/\(globalAyahNumber).mp3")!
    }

    // MARK: - Arapça metin (script / ileride kullanım için)

    /// alquran.cloud'dan Uthmani Arapça metni ve global ayet numarasını çeker.
    /// Uygulama akışında çağrılmaz (metin JSON'a statik yazılır); script ve test için.
    func fetchAyahText(surah: Int, ayah: Int) async throws -> (arabicText: String, globalAyahNumber: Int) {
        let url = URL(string: "\(Self.apiBase)/\(surah):\(ayah)/quran-uthmani")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else { throw AudioError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw AudioError.badStatus(http.statusCode) }
        let decoded = try JSONDecoder().decode(AyahResponse.self, from: data)
        return (decoded.data.text, decoded.data.number)
    }

    // MARK: - Cache + AVPlayerItem

    /// Caches/quran-audio/ — sistem tarafından gerektiğinde temizlenebilir (kalıcı değil).
    private static func cacheDirectory() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent("quran-audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    func cachedFileURL(
        globalAyahNumber: Int,
        bitrate: Int = QuranAudioService.defaultBitrate,
        reciter: String = QuranAudioService.defaultReciter
    ) -> URL {
        Self.cacheDirectory().appendingPathComponent("\(reciter)-\(bitrate)-\(globalAyahNumber).mp3")
    }

    /// Çalınacak `AVPlayerItem` üretir. Dosya cache'te varsa yerelden (ağsız) çalar;
    /// yoksa CDN'den stream eder ve arka planda cache'e indirir.
    func makePlayerItem(
        globalAyahNumber: Int,
        bitrate: Int = QuranAudioService.defaultBitrate,
        reciter: String = QuranAudioService.defaultReciter
    ) -> AVPlayerItem {
        let cacheURL = cachedFileURL(globalAyahNumber: globalAyahNumber, bitrate: bitrate, reciter: reciter)
        if FileManager.default.fileExists(atPath: cacheURL.path) {
            return AVPlayerItem(url: cacheURL)
        }
        let remoteURL = audioURL(globalAyahNumber: globalAyahNumber, bitrate: bitrate, reciter: reciter)
        prefetchToCache(remoteURL: remoteURL, cacheURL: cacheURL)
        return AVPlayerItem(url: remoteURL)
    }

    /// CDN dosyasını arka planda indirip cache'e yazar. Stream ile birlikte ayet başına
    /// yalnızca bir kez çalışır; sonraki dinlemeler tamamen yerelden olur.
    private func prefetchToCache(remoteURL: URL, cacheURL: URL) {
        let task = session.downloadTask(with: remoteURL) { tempURL, response, _ in
            guard let tempURL,
                  let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode) else { return }
            try? FileManager.default.removeItem(at: cacheURL)
            try? FileManager.default.moveItem(at: tempURL, to: cacheURL)
        }
        task.resume()
    }
}

// MARK: - API yanıt modeli

private struct AyahResponse: Decodable {
    struct AyahData: Decodable {
        let text: String
        let number: Int
    }
    let data: AyahData
}
