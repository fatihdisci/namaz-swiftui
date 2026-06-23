import XCTest
@testable import Vakit

/// `QuranAudioService` URL formatlama mantığı ve `Verse` ses alanı decode testleri.
/// Ağ gerektiren `fetchAyahText` testi entegrasyon testi olarak işaretlidir ve
/// yalnızca `RUN_NETWORK_TESTS=1` ortam değişkeniyle çalışır (CI'da varsayılan kapalı).
final class QuranAudioServiceTests: XCTestCase {

    // MARK: - URL formatlama (ağ gerektirmez)

    func testAudioURLDefaultReciterAndBitrate() {
        // Bakara 2:45 → global ayet 52
        let url = QuranAudioService.shared.audioURL(globalAyahNumber: 52)
        XCTAssertEqual(
            url.absoluteString,
            "https://cdn.islamic.network/quran/audio/128/ar.alafasy/52.mp3"
        )
    }

    func testAudioURLAyetulKursi() {
        // Bakara 2:255 (Ayet-ül Kürsi) → global ayet 262
        let url = QuranAudioService.shared.audioURL(globalAyahNumber: 262)
        XCTAssertEqual(
            url.absoluteString,
            "https://cdn.islamic.network/quran/audio/128/ar.alafasy/262.mp3"
        )
    }

    func testAudioURLCustomBitrate() {
        let url = QuranAudioService.shared.audioURL(globalAyahNumber: 1, bitrate: 64)
        XCTAssertEqual(
            url.absoluteString,
            "https://cdn.islamic.network/quran/audio/64/ar.alafasy/1.mp3"
        )
    }

    func testAudioURLCustomReciter() {
        let url = QuranAudioService.shared.audioURL(globalAyahNumber: 100, reciter: "ar.husary")
        XCTAssertEqual(
            url.absoluteString,
            "https://cdn.islamic.network/quran/audio/128/ar.husary/100.mp3"
        )
    }

    func testCachedFileURLIsInCachesDirectory() {
        let url = QuranAudioService.shared.cachedFileURL(globalAyahNumber: 52)
        XCTAssertEqual(url.lastPathComponent, "ar.alafasy-128-52.mp3")
        XCTAssertTrue(url.path.contains("quran-audio"))
    }

    // MARK: - Verse ses alanı decode

    func testVerseDecodesSingleAudioAyahNumber() throws {
        let json = """
        {
          "id": "v001", "arapca": "نص", "turkce": "x", "ingilizce": "x",
          "sureAdi": "Bakara", "sureNo": 2, "ayetNo": "45",
          "kaynak": "Bakara 2:45", "atifUrl": null, "sesAyetNo": [52]
        }
        """.data(using: .utf8)!
        let verse = try JSONDecoder().decode(Verse.self, from: json)
        XCTAssertEqual(verse.audioAyahNumbers, [52])
        XCTAssertTrue(verse.hasAudio)
    }

    func testVerseDecodesAudioRange() throws {
        let json = """
        {
          "id": "v030", "arapca": "نص", "turkce": "x", "ingilizce": "x",
          "sureAdi": "İnşirâh", "sureNo": 94, "ayetNo": "5-6",
          "kaynak": "İnşirâh 94:5-6", "atifUrl": null, "sesAyetNo": [6095, 6096]
        }
        """.data(using: .utf8)!
        let verse = try JSONDecoder().decode(Verse.self, from: json)
        XCTAssertEqual(verse.audioAyahNumbers, [6095, 6096])
        XCTAssertTrue(verse.hasAudio)
    }

    /// `sesAyetNo` alanı olmayan eski içerik geriye dönük uyumlu decode olmalı.
    func testVerseWithoutAudioFieldDecodes() throws {
        let json = """
        {
          "id": "v999", "arapca": null, "turkce": "x", "ingilizce": "x",
          "sureAdi": "Bakara", "sureNo": 2, "ayetNo": "1",
          "kaynak": "Bakara 2:1", "atifUrl": null
        }
        """.data(using: .utf8)!
        let verse = try JSONDecoder().decode(Verse.self, from: json)
        XCTAssertEqual(verse.audioAyahNumbers, [])
        XCTAssertFalse(verse.hasAudio)
    }

    /// Bundle'daki tüm ayetlerin ses numarası dolu olduğunu doğrular.
    @MainActor
    func testBundledVersesAllHaveAudio() {
        let verses = DailyContent.verses
        XCTAssertFalse(verses.isEmpty)
        for verse in verses {
            XCTAssertTrue(verse.hasAudio, "Ayet \(verse.id) (\(verse.source)) ses numarası eksik")
            XCTAssertNotNil(verse.arabic, "Ayet \(verse.id) Arapça metni eksik")
        }
    }

    // MARK: - Entegrasyon (ağ) — varsayılan kapalı

    func testFetchAyahTextIntegration() async throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["RUN_NETWORK_TESTS"] == "1",
            "Ağ entegrasyon testi: RUN_NETWORK_TESTS=1 ile çalıştırın."
        )
        let (text, number) = try await QuranAudioService.shared.fetchAyahText(surah: 2, ayah: 45)
        XCTAssertEqual(number, 52)
        XCTAssertFalse(text.isEmpty)
    }
}
