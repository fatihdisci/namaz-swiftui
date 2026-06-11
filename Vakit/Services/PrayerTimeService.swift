import Foundation
import Adhan

/// Namaz vakti kaynağı: cache → Aladhan API → Adhan Swift (offline).
/// Uygulama ASLA internet bağımlısı değildir; her ağ hatasında lokal hesaplama devreye girer.
final class PrayerTimeService {
    static let shared = PrayerTimeService()

    private let storage: StorageService
    private let session: URLSession

    private static let apiBaseURL = "https://api.aladhan.com/v1"
    private static let requestTimeout: TimeInterval = 10

    enum ServiceError: Error {
        case invalidURL
        case badStatus(Int)
        case invalidResponse
        case incompleteTimings
    }

    init(storage: StorageService = .shared, session: URLSession = .shared) {
        self.storage = storage
        self.session = session
    }

    // MARK: - Aladhan API

    /// Aladhan'dan tek günün vakitlerini çeker.
    /// URL: https://api.aladhan.com/v1/timings/DD-MM-YYYY?latitude=&longitude=&method=&school=
    func fetchFromAladhan(
        lat: Double,
        lng: Double,
        date: Date,
        method: CalculationMethod,
        school: Int
    ) async throws -> PrayerTimes {
        var components = URLComponents(string: "\(Self.apiBaseURL)/timings/\(Self.apiDateString(from: date))")
        components?.queryItems = [
            URLQueryItem(name: "latitude", value: String(lat)),
            URLQueryItem(name: "longitude", value: String(lng)),
            URLQueryItem(name: "method", value: String(method.rawValue)),
            URLQueryItem(name: "school", value: String(school)),
        ]
        guard let url = components?.url else { throw ServiceError.invalidURL }

        var request = URLRequest(url: url)
        request.timeoutInterval = Self.requestTimeout

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ServiceError.badStatus(http.statusCode)
        }

        let payload = try JSONDecoder().decode(AladhanResponse.self, from: data)
        guard payload.code == 200 else { throw ServiceError.invalidResponse }

        let timings = payload.data.timings
        guard
            let fajr = Self.combine(date: date, withTiming: timings.fajr),
            let sunrise = Self.combine(date: date, withTiming: timings.sunrise),
            let dhuhr = Self.combine(date: date, withTiming: timings.dhuhr),
            let asr = Self.combine(date: date, withTiming: timings.asr),
            let maghrib = Self.combine(date: date, withTiming: timings.maghrib),
            let isha = Self.combine(date: date, withTiming: timings.isha)
        else {
            throw ServiceError.incompleteTimings
        }

        let hijri = payload.data.date.hijri

        return PrayerTimes(
            date: Calendar.current.startOfDay(for: date),
            fajr: fajr,
            sunrise: sunrise,
            dhuhr: dhuhr,
            asr: asr,
            maghrib: maghrib,
            isha: isha,
            hijriDay: hijri.day,
            hijriMonthName: hijri.month.en,
            hijriYear: hijri.year
        )
    }

    // MARK: - Offline hesaplama (Adhan Swift)

    /// İnternet yokken Adhan Swift ile lokal hesaplama.
    /// diyanet → `CalculationMethod.turkey` + Hanafi madhab (school == 1).
    func calculateLocally(
        lat: Double,
        lng: Double,
        date: Date,
        method: CalculationMethod,
        school: Int = 1
    ) -> PrayerTimes {
        let coordinates = Coordinates(latitude: lat, longitude: lng)
        var params = Self.adhanParameters(for: method)
        params.madhab = school == 1 ? .hanafi : .shafi

        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let hijri = storage.offlineHijri(for: date)
        let day = Calendar.current.startOfDay(for: date)

        if let adhanTimes = Adhan.PrayerTimes(
            coordinates: coordinates,
            date: components,
            calculationParameters: params
        ) {
            return PrayerTimes(
                date: day,
                fajr: adhanTimes.fajr,
                sunrise: adhanTimes.sunrise,
                dhuhr: adhanTimes.dhuhr,
                asr: adhanTimes.asr,
                maghrib: adhanTimes.maghrib,
                isha: adhanTimes.isha,
                hijriDay: hijri.day,
                hijriMonthName: hijri.monthName,
                hijriYear: hijri.year
            )
        }

        // Çok nadir durum (uç enlemler): kaba yaklaşık değerlerle asla boş dönme.
        func approximate(_ hour: Int, _ minute: Int) -> Date {
            Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }
        return PrayerTimes(
            date: day,
            fajr: approximate(5, 0),
            sunrise: approximate(6, 30),
            dhuhr: approximate(12, 30),
            asr: approximate(16, 0),
            maghrib: approximate(19, 0),
            isha: approximate(20, 30),
            hijriDay: hijri.day,
            hijriMonthName: hijri.monthName,
            hijriYear: hijri.year
        )
    }

    // MARK: - Birleşik akış

    /// Cache → Aladhan → lokal hesaplama. Çağırana asla hata fırlatmaz.
    func getPrayerTimes(city: City, date: Date) async -> PrayerTimes {
        let method = city.method
        let school = city.school

        if let cached = storage.cachedPrayerTimes(for: date),
           cached.matches(
               latitude: city.latitude,
               longitude: city.longitude,
               method: method.rawValue,
               school: school
           ) {
            return cached.times
        }

        let times: PrayerTimes
        do {
            times = try await fetchFromAladhan(
                lat: city.latitude,
                lng: city.longitude,
                date: date,
                method: method,
                school: school
            )
        } catch {
            times = calculateLocally(
                lat: city.latitude,
                lng: city.longitude,
                date: date,
                method: method,
                school: school
            )
        }

        storage.cachePrayerTimes(
            CachedPrayerTimes(
                times: times,
                latitude: city.latitude,
                longitude: city.longitude,
                method: method.rawValue,
                school: school,
                cachedAt: Date()
            ),
            for: date
        )
        return times
    }

    /// Uygulama açılışında bugün + sonraki 7 günü cache'e doldurur.
    func prefetch(city: City) async {
        let today = Calendar.current.startOfDay(for: Date())
        for offset in 0...7 {
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: today) else { continue }
            _ = await getPrayerTimes(city: city, date: date)
        }
    }

    /// Sıradaki vakti bulur. Bugünün tüm vakitleri geçtiyse yarının sabah (fajr) vaktini döner.
    /// `tomorrow` verilmezse yarının fajr'ı bugünkü fajr + 24 saat olarak yaklaşıklanır.
    func nextPrayer(
        from today: PrayerTimes,
        tomorrow: PrayerTimes? = nil,
        at now: Date = Date()
    ) -> (prayer: Prayer, time: Date) {
        if let upcoming = today.orderedTimes.first(where: { $0.time > now }) {
            return upcoming
        }
        if let tomorrow {
            return (.fajr, tomorrow.fajr)
        }
        return (.fajr, today.fajr.addingTimeInterval(24 * 60 * 60))
    }

    // MARK: - Yardımcılar

    /// Aladhan URL formatı: DD-MM-YYYY
    static func apiDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }

    /// "05:43 (+03)" gibi bir timing string'inden HH:mm çekip verilen güne yerleştirir.
    static func combine(date: Date, withTiming timing: String) -> Date? {
        let scanner = Scanner(string: timing)
        guard
            let hour = scanner.scanInt(),
            scanner.scanString(":") != nil,
            let minute = scanner.scanInt(),
            (0..<24).contains(hour),
            (0..<60).contains(minute)
        else { return nil }

        return Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: date
        )
    }

    /// CalculationMethod → Adhan Swift parametreleri.
    private static func adhanParameters(for method: CalculationMethod) -> CalculationParameters {
        switch method {
        case .diyanet: return Adhan.CalculationMethod.turkey.params
        case .mwl: return Adhan.CalculationMethod.muslimWorldLeague.params
        case .isna: return Adhan.CalculationMethod.northAmerica.params
        case .ummAlQura: return Adhan.CalculationMethod.ummAlQura.params
        case .egyptian: return Adhan.CalculationMethod.egyptian.params
        }
    }
}

// MARK: - Aladhan API yanıt modelleri

struct AladhanResponse: Codable {
    let code: Int
    let status: String
    let data: AladhanData
}

struct AladhanData: Codable {
    let timings: AladhanTimings
    let date: AladhanDate
}

struct AladhanTimings: Codable {
    let fajr: String
    let sunrise: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String

    enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case sunrise = "Sunrise"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case maghrib = "Maghrib"
        case isha = "Isha"
    }
}

struct AladhanDate: Codable {
    let readable: String
    let hijri: AladhanHijri
}

struct AladhanHijri: Codable {
    let day: String
    let month: AladhanHijriMonth
    let year: String
}

struct AladhanHijriMonth: Codable {
    let number: Int
    let en: String
    let ar: String?
}
