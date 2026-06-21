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

    func testLegacyPrayerLocationDefaultsToStandardAsrCalculation() throws {
        let location = PrayerLocation(
            countryCode: "TR",
            countryName: "Türkiye",
            admin1Name: "Ankara",
            admin2Name: "Çankaya",
            latitude: 39.9179,
            longitude: 32.8627,
            timeZoneIdentifier: "Europe/Istanbul",
            school: AsrCalculation.hanafi.rawValue
        )
        let encoded = try JSONEncoder().encode(location)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "school")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(PrayerLocation.self, from: legacyData)
        XCTAssertEqual(decoded.school, AsrCalculation.standard.rawValue)
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

    private func makeTimes(source: PrayerTimeSource) -> PrayerTimes {
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
            hijriMonthName: "Ramadan",
            hijriYear: "1447",
            source: source
        )
    }
}
