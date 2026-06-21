import SwiftUI

struct PrayerCalendarView: View {
    let city: City

    @State private var selectedDate = Date()
    @State private var times: PrayerTimes?
    @State private var isLoading = false

    @Environment(LanguageService.self) private var lang

    private let prayerService = PrayerTimeService.shared

    var body: some View {
        ZStack {
            AuroraBackground(accentColor: .vakitAccent)

            ScrollView {
                VStack(spacing: 18) {
                    dateControls

                    if isLoading && times == nil {
                        ProgressView().tint(Color.vakitAccent).padding(.top, 40)
                    } else if let times {
                        hijriCard(times)
                        prayerList(times)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle(lang.t("calendar.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selectedDayKey) { await load() }
    }

    private var dateControls: some View {
        HStack(spacing: 12) {
            dayButton(offset: -1, icon: "chevron.left")

            DatePicker(
                lang.t("calendar.selectDate"),
                selection: $selectedDate,
                in: allowedDates,
                displayedComponents: .date
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(Color.vakitAccent)
            .frame(maxWidth: .infinity)

            dayButton(offset: 1, icon: "chevron.right")
        }
        .padding(14)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.vakitBorder))
    }

    private func dayButton(offset: Int, icon: String) -> some View {
        Button {
            selectedDate = cityCalendar.date(byAdding: .day, value: offset, to: selectedDate) ?? selectedDate
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.vakitAccent)
                .frame(width: 38, height: 38)
                .background(Circle().fill(Color.vakitAccent.opacity(0.12)))
        }
        .disabled(!allowedDates.contains(cityCalendar.date(byAdding: .day, value: offset, to: selectedDate) ?? selectedDate))
    }

    private func hijriCard(_ times: PrayerTimes) -> some View {
        VStack(spacing: 5) {
            Text(formattedDate)
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.vakitText)
            Text("\(times.hijriDay) \(times.hijriMonthName) \(times.hijriYear)")
                .font(.subheadline)
                .foregroundStyle(Color.vakitAccent)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func prayerList(_ times: PrayerTimes) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(Prayer.allCases.enumerated()), id: \.element.id) { index, prayer in
                HStack(spacing: 12) {
                    Image(systemName: prayer.systemImage)
                        .foregroundStyle(prayer.accentColor)
                        .frame(width: 28)
                    Text(lang.t(prayer.localizationKey))
                        .foregroundStyle(Color.vakitText)
                    Spacer()
                    Text(times.time(for: prayer).hhmm)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.vakitText)
                        .monospacedDigit()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                if index < Prayer.allCases.count - 1 {
                    Divider().overlay(Color.vakitBorder).padding(.leading, 56)
                }
            }
        }
        .background(Color.vakitSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.vakitBorder))
    }

    private var cityCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: city.timezone) ?? .current
        return calendar
    }

    private var allowedDates: ClosedRange<Date> {
        let today = cityCalendar.startOfDay(for: Date())
        let past = cityCalendar.date(byAdding: .day, value: -30, to: today) ?? today
        let future = cityCalendar.date(byAdding: .day, value: 365, to: today) ?? today
        return past...future
    }

    private var selectedDayKey: String {
        StorageService.dateKey(for: selectedDate, timeZone: cityCalendar.timeZone)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang.currentLanguage == "tr" ? "tr_TR" : "en_US")
        formatter.timeZone = cityCalendar.timeZone
        formatter.dateStyle = .full
        return formatter.string(from: selectedDate)
    }

    private func load() async {
        let requestedDate = selectedDate
        let requestedKey = StorageService.dateKey(
            for: requestedDate,
            timeZone: cityCalendar.timeZone
        )
        isLoading = true
        let result = await prayerService.getPrayerTimes(city: city, date: requestedDate)
        guard !Task.isCancelled, requestedKey == selectedDayKey else { return }
        times = result
        isLoading = false
    }
}
