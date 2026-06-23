import XCTest
@testable import Vakit

final class PrayerAccuracyTests: XCTestCase {
    func testInvalidZeroCoordinateIsRejected() {
        XCTAssertFalse(LocationSelectionViewModel.isValidCityCoordinate(latitude: 0, longitude: 0))
        XCTAssertFalse(LocationSelectionViewModel.isValidCityCoordinate(latitude: 91, longitude: 30))
        XCTAssertTrue(LocationSelectionViewModel.isValidCityCoordinate(latitude: 41.0082, longitude: 28.9784))
    }

    func testCityPreservesHanafiCalculation() {
        let city = City(
            name: "İstanbul",
            latitude: 41.0082,
            longitude: 28.9784,
            country: "Türkiye",
            timezone: "Europe/Istanbul",
            school: AsrCalculation.hanafi.rawValue
        )
        XCTAssertEqual(city.school, AsrCalculation.hanafi.rawValue)
    }

    func testEstimatedTimesAreNotReliableForNotifications() {
        XCTAssertFalse(makeTimes(source: .estimated).isReliableForNotifications)
        XCTAssertTrue(makeTimes(source: .localCalculation).isReliableForNotifications)
    }

    func testLegacyPrayerTimesCacheDefaultsToAladhanSource() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(makeTimes(source: .localCalculation))
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "source")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PrayerTimes.self, from: legacyData)
        XCTAssertEqual(decoded.source, .aladhan)
    }

    func testLegacyPrayerLocationDefaultsToRecommendedAsrCalculation() throws {
        // ISNA kullanan legacy data (school key'i yok) → recommendedAsrCalculation (.standard)
        let location = PrayerLocation(
            countryCode: "US",
            countryName: "United States",
            admin1Name: "New York",
            admin2Name: "Manhattan",
            latitude: 40.7128,
            longitude: -74.0060,
            timeZoneIdentifier: "America/New_York",
            calculationMethod: .isna,
            school: AsrCalculation.hanafi.rawValue
        )
        let encoded = try JSONEncoder().encode(location)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "school")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(PrayerLocation.self, from: legacyData)
        // ISNA'nın önerdiği Asr = Standard
        XCTAssertEqual(decoded.school, AsrCalculation.standard.rawValue)
    }

    func testRamadanDetectionAcceptsTurkishAndEnglishMonthNames() {
        XCTAssertTrue(makeTimes(source: .aladhan, hijriMonth: "Ramadan").isRamadan)
        XCTAssertTrue(makeTimes(source: .aladhan, hijriMonth: "Ramazan").isRamadan)
        XCTAssertFalse(makeTimes(source: .aladhan, hijriMonth: "Muharram").isRamadan)
    }

    @MainActor
    func testDuaCategoriesAndSearch() throws {
        let calmDua = try XCTUnwrap(DailyContent.duas.first { $0.id == "d003" })
        let knowledgeDua = try XCTUnwrap(DailyContent.duas.first { $0.id == "d005" })

        XCTAssertEqual(calmDua.category, .calm)
        XCTAssertEqual(knowledgeDua.category, .success)
        XCTAssertTrue(calmDua.matches("ferahlık", language: "tr"))
        XCTAssertTrue(knowledgeDua.matches("knowledge", language: "en"))
    }

    func testFavoriteDuaStorageTogglesDeterministically() throws {
        let suiteName = "PrayerAccuracyTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let storage = StorageService(defaults: defaults)

        storage.toggleFavoriteDua(id: "d003")
        XCTAssertEqual(storage.favoriteDuaIDs, ["d003"])
        storage.toggleFavoriteDua(id: "d003")
        XCTAssertTrue(storage.favoriteDuaIDs.isEmpty)
    }

    func testDateKeysRespectCityTimeZone() throws {
        let instant = Date(timeIntervalSince1970: 1_735_689_000) // UTC'de yıl sınırına yakın.
        let istanbul = try XCTUnwrap(TimeZone(identifier: "Europe/Istanbul"))
        let losAngeles = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))

        XCTAssertNotEqual(
            StorageService.dateKey(for: instant, timeZone: istanbul),
            StorageService.dateKey(for: instant, timeZone: losAngeles)
        )
    }

    // MARK: - Asr hesaplama önerileri

    func testDiyanetRecommendsStandardAsrCalculation() {
        XCTAssertEqual(CalculationMethod.diyanet.recommendedAsrCalculation, .standard)
    }

    func testAllMethodsRecommendStandardAsrCalculation() {
        XCTAssertEqual(CalculationMethod.diyanet.recommendedAsrCalculation, .standard)
        XCTAssertEqual(CalculationMethod.mwl.recommendedAsrCalculation, .standard)
        XCTAssertEqual(CalculationMethod.isna.recommendedAsrCalculation, .standard)
        XCTAssertEqual(CalculationMethod.ummAlQura.recommendedAsrCalculation, .standard)
        XCTAssertEqual(CalculationMethod.egyptian.recommendedAsrCalculation, .standard)
    }

    func testPrayerLocationDefaultInitUsesRecommendedAsrForDiyanet() {
        let location = PrayerLocation(
            countryCode: "TR",
            countryName: "Türkiye",
            latitude: 41.0082,
            longitude: 28.9784,
            timeZoneIdentifier: "Europe/Istanbul",
            calculationMethod: .diyanet
            // school verilmedi → recommendedAsrCalculation (.standard) kullanılmalı
        )
        XCTAssertEqual(location.school, AsrCalculation.standard.rawValue)
    }

    func testPrayerLocationDefaultInitUsesStandardForISNA() {
        let location = PrayerLocation(
            countryCode: "US",
            countryName: "United States",
            latitude: 40.7128,
            longitude: -74.0060,
            timeZoneIdentifier: "America/New_York",
            calculationMethod: .isna
            // school verilmedi → recommendedAsrCalculation (.standard) kullanılmalı
        )
        XCTAssertEqual(location.school, AsrCalculation.standard.rawValue)
    }

    func testPrayerLocationExplicitSchoolOverridesRecommended() {
        let location = PrayerLocation(
            countryCode: "TR",
            countryName: "Türkiye",
            latitude: 41.0082,
            longitude: 28.9784,
            timeZoneIdentifier: "Europe/Istanbul",
            calculationMethod: .diyanet,
            school: AsrCalculation.standard.rawValue
        )
        // Kullanıcı bilerek Standart seçmişse onu kullan
        XCTAssertEqual(location.school, AsrCalculation.standard.rawValue)
    }

    // MARK: - Asr migration

    func testAsrCorrectionConvertsErroneousDiyanetHanafiToStandardWhenNeverManuallySet() throws {
        let suiteName = "AsrCorrectionTest.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Hatalı eski göç durumu: method = Diyanet, school = 1 (Hanefi),
        // ama hasManuallySetAsrCalculation = false (kullanıcı elle seçmedi)
        defaults.set(CalculationMethod.diyanet.rawValue, forKey: "method")
        defaults.set(AsrCalculation.hanafi.rawValue, forKey: "school")
        // hasManuallySetAsrCalculation key'i set edilmemiş → false
        // asrSchoolStandardCorrectionMigrated key'i set edilmemiş → false

        let storage = StorageService(defaults: defaults)

        // Correction sonrası: Diyanet tablosuyla eşleşen Standard olmalı
        XCTAssertEqual(storage.school, AsrCalculation.standard.rawValue)
        XCTAssertTrue(defaults.bool(forKey: "asr_school_standard_correction_migrated"))
    }

    func testAsrCorrectionDoesNotOverwriteManualHanafiSelection() throws {
        let suiteName = "AsrCorrectionManual.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Kullanıcı Diyanet kullanıyor, ama bilerek Hanefi seçmiş
        defaults.set(CalculationMethod.diyanet.rawValue, forKey: "method")
        defaults.set(AsrCalculation.hanafi.rawValue, forKey: "school")
        defaults.set(true, forKey: "has_manually_set_asr")

        let storage = StorageService(defaults: defaults)

        // Correction kullanıcının manuel seçimini EZMEMELİ
        XCTAssertEqual(storage.school, AsrCalculation.hanafi.rawValue)
        XCTAssertTrue(defaults.bool(forKey: "asr_school_standard_correction_migrated"))
    }

    func testAsrCorrectionOnlyAppliesOnce() throws {
        let suiteName = "AsrCorrectionOnce.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // İlk durum: Hatalı eski göçten kalmış Diyanet + Hanefi + manuel değiştirilmemiş
        defaults.set(CalculationMethod.diyanet.rawValue, forKey: "method")
        defaults.set(AsrCalculation.hanafi.rawValue, forKey: "school")
        // hasManuallySetAsrCalculation = false (key yok)

        // İlk StorageService init'i correction yapar
        let storage1 = StorageService(defaults: defaults)
        XCTAssertEqual(storage1.school, AsrCalculation.standard.rawValue)

        // Kullanıcı sonradan manuel olarak Hanefi'ye döndürsün
        storage1.hasManuallySetAsrCalculation = true
        defaults.set(AsrCalculation.hanafi.rawValue, forKey: "school")

        // İkinci StorageService init'i correction'ı TEKRARLAMAMALI
        let storage2 = StorageService(defaults: defaults)
        XCTAssertEqual(storage2.school, AsrCalculation.hanafi.rawValue)
    }

    func testAsrCorrectionDoesNotAffectNonDiyanetMethods() throws {
        let suiteName = "AsrCorrectionNonTR.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // MWL kullanan ve Hanefi seçili görünen bir kullanıcı
        defaults.set(CalculationMethod.mwl.rawValue, forKey: "method")
        defaults.set(AsrCalculation.hanafi.rawValue, forKey: "school")

        let storage = StorageService(defaults: defaults)

        // MWL + Hanefi = correction yapılmamalı
        XCTAssertEqual(storage.school, AsrCalculation.hanafi.rawValue)
        XCTAssertTrue(defaults.bool(forKey: "asr_school_standard_correction_migrated"))
    }

    func testAPIDateFormattingUsesRequestedTimeZone() throws {
        let instant = Date(timeIntervalSince1970: 1_735_689_000)
        let istanbul = try XCTUnwrap(TimeZone(identifier: "Europe/Istanbul"))
        let losAngeles = try XCTUnwrap(TimeZone(identifier: "America/Los_Angeles"))

        XCTAssertNotEqual(
            PrayerTimeService.apiDateString(from: instant, timeZone: istanbul),
            PrayerTimeService.apiDateString(from: instant, timeZone: losAngeles)
        )
    }

    func testBundledContentFilesPassRemoteValidation() throws {
        for fileName in ["ayetler.json", "dualar.json", "hadisler.json", "esma.json"] {
            let parts = fileName.split(separator: ".", maxSplits: 1).map(String.init)
            let url = try XCTUnwrap(Bundle.main.url(forResource: parts[0], withExtension: parts[1]))
            let data = try Data(contentsOf: url)
            XCTAssertTrue(RemoteContentService.isValidContent(data, fileName: fileName), fileName)
        }
    }

    @MainActor
    func testBundledContentVersionIsAvailable() {
        XCTAssertGreaterThanOrEqual(RemoteContentService.shared.bundledVersion, 1)
    }

    func testExpandedDuaSchemaDecodesResearchFields() throws {
        let json = """
        [{
          "id":"d100", "tip":"kurani", "baslik_tr":"İlim Duası",
          "baslik_en":"Prayer for Knowledge", "kategori":"success",
          "etiketler":["ilim","sınav"], "arapca":"رَبِّ زِدْنِي عِلْمًا",
          "okunus":"Rabbi zidni ilma", "turkce":"Rabbim, ilmimi artır.",
          "ingilizce":"My Lord, increase me in knowledge.", "kaynak":"Tâhâ 20:114",
          "derece":null, "atifUrl":"https://kuran.diyanet.gov.tr/"
        }]
        """
        let dua = try XCTUnwrap(JSONDecoder().decode([Dua].self, from: Data(json.utf8)).first)

        XCTAssertEqual(dua.title(language: "tr"), "İlim Duası")
        XCTAssertEqual(dua.category, .success)
        XCTAssertTrue(dua.matches("sınav", language: "tr"))
    }

    /// Diyanet'in 21 Haziran 2026 Ankara tablosuna karşı çevrimdışı fallback sapmasını izler.
    func testOfflineAnkaraTimesStayNearDiyanetGoldenData() throws {
        let timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/Istanbul"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let date = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 21)))
        let result = PrayerTimeService.shared.calculateLocally(
            lat: 39.9334,
            lng: 32.8597,
            date: date,
            method: .diyanet,
            school: AsrCalculation.standard.rawValue,
            timezone: timeZone
        )
        let expected = [
            (result.fajr, 3, 17), (result.sunrise, 5, 13), (result.dhuhr, 12, 55),
            (result.asr, 16, 53), (result.maghrib, 20, 28), (result.isha, 22, 15),
        ]
        for (actual, hour, minute) in expected {
            let golden = try XCTUnwrap(calendar.date(bySettingHour: hour, minute: minute, second: 0, of: date))
            XCTAssertLessThanOrEqual(abs(actual.timeIntervalSince(golden)), 10 * 60)
        }
    }

    private func makeTimes(source: PrayerTimeSource, hijriMonth: String = "Ramadan") -> PrayerTimes {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        return PrayerTimes(
            date: date,
            fajr: date,
            sunrise: date.addingTimeInterval(3_600),
            dhuhr: date.addingTimeInterval(7_200),
            asr: date.addingTimeInterval(10_800),
            maghrib: date.addingTimeInterval(14_400),
            isha: date.addingTimeInterval(18_000),
            hijriDay: "1",
            hijriMonthName: hijriMonth,
            hijriYear: "1447",
            source: source
        )
    }
}
