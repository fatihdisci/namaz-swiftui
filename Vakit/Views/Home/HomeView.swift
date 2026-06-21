import SwiftUI
import SwiftData

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @State private var showLocationPicker = false
    @State private var showProGate = false
    @State private var proGateContext: ProGateContext = .general
    private let onOpenDiscover: () -> Void

    @Environment(LanguageService.self) private var lang
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(NotificationService.self) private var notificationService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @MainActor
    init(viewModel: HomeViewModel, onOpenDiscover: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenDiscover = onOpenDiscover
    }

    @MainActor
    init(onOpenDiscover: @escaping () -> Void = {}) {
        self.init(viewModel: HomeViewModel(), onOpenDiscover: onOpenDiscover)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(accentColor: viewModel.nextPrayer.accentColor)

                TimelineView(.periodic(from: .now, by: 1.0)) { context in
                    content
                        .onChange(of: context.date) { _, newDate in
                            viewModel.tick(date: newDate)
                        }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            await viewModel.load()
        }
        .onReceive(NotificationCenter.default.publisher(for: .vakitPrayerLocationChanged)) { _ in
            Task { await reloadAndReschedule() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .vakitSavedPrayerLocationsChanged)) { _ in
            viewModel.refreshSavedLocations()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await viewModel.load() }
        }
        .sheet(isPresented: $showLocationPicker) {
            // Her açılışta TAZE model sahiplenen alt view; konum aynı instance'tan
            // üretilip geri verilir (ilk açılışta kaydetme sorunu çözülür).
            NewLocationSheet(lang: lang) { location in
                saveNewLocation(location)
                showLocationPicker = false
            }
        }
        .sheet(isPresented: $showProGate) {
            ProGateView(context: proGateContext)
                .environment(lang)
                .environment(purchaseService)
        }
    }

    private var content: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.horizontal, 20)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 20) {
                    NextPrayerCard(
                        prayer: viewModel.nextPrayer,
                        time: viewModel.nextPrayerTime,
                        countdown: viewModel.countdownString
                    )

                    citySelector

                    if viewModel.isFriday, let times = viewModel.todaysTimes {
                        FridayCard(dhuhrTime: times.dhuhr)
                    }

                    if let times = viewModel.todaysTimes, times.isRamadan {
                        RamadanCard(times: times)
                    }

                    VStack(spacing: 4) {
                        ForEach(Prayer.allCases) { prayer in
                            let state = viewModel.rowState(for: prayer)
                            PrayerListRow(
                                prayer: prayer,
                                time: state.time,
                                isPast: state.isPast,
                                isNext: state.isNext
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "location.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.vakitAccent)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color.vakitAccent.opacity(0.14)))

                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.currentCity?.name ?? "-")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.vakitText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)

                    Text(viewModel.currentCity?.country ?? "")
                        .font(.caption)
                        .foregroundStyle(Color.vakitTextDim)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let city = viewModel.currentCity {
                NavigationLink {
                    PrayerCalendarView(city: city)
                } label: {
                    hijriSummary
                }
            } else {
                hijriSummary
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.vakitBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.12), radius: 18, y: 10)
    }

    private var hijriSummary: some View {
        HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.vakitAccent)

                VStack(alignment: .trailing, spacing: 1) {
                    Text("Hicri")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.vakitTextDim)

                    Text(viewModel.hijriDate)
                        .font(.system(.caption, design: .default, weight: .semibold))
                        .foregroundStyle(Color.vakitText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }


    private var citySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.savedLocations) { location in
                    Button {
                        guard purchaseService.hasProAccess || location.id == viewModel.currentCity?.id else {
                            proGateContext = .cities
                            showProGate = true
                            return
                        }
                        StorageService.shared.selectedPrayerLocation = location
                    } label: {
                        Text(location.shortName)
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(location.id == viewModel.currentCity?.id ? Color.vakitBg : Color.vakitText)
                            .lineLimit(1)
                            .padding(.horizontal, 14)
                            .frame(height: 36)
                            .background(
                                Capsule().fill(
                                    location.id == viewModel.currentCity?.id ? Color.vakitAccent : Color.vakitSurface
                                )
                            )
                            .overlay(Capsule().strokeBorder(Color.vakitBorder, lineWidth: 1))
                    }
                }

                Button {
                    guard purchaseService.hasProAccess else {
                        proGateContext = .cities
                        showProGate = true
                        return
                    }
                    showLocationPicker = true
                } label: {
                    Image(systemName: purchaseService.hasProAccess ? "plus" : "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.vakitAccent)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.vakitSurface))
                        .overlay(Circle().strokeBorder(Color.vakitBorder, lineWidth: 1))
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func saveNewLocation(_ location: PrayerLocation) {
        let existing = (try? modelContext.fetch(FetchDescriptor<City>())) ?? []
        existing.forEach { $0.isPrimary = false }
        let city = location.makeCity()
        city.isPrimary = true
        modelContext.insert(city)
        try? modelContext.save()

        StorageService.shared.selectedPrayerLocation = location
        // Vakitleri yeniden yükle + bildirim/widget snapshot'ını tazele.
        Task { await reloadAndReschedule() }
    }

    private func reloadAndReschedule() async {
        await viewModel.reloadForLocationChange()
        guard let city = StorageService.shared.resolvedCity else { return }
        await notificationService.reschedule(city: city)
    }
}

// MARK: - New location sheet

/// Yeni konum ekleme sheet'i. KENDİ `LocationSelectionViewModel`'ini sahiplenir;
/// sheet her açıldığında taze model kurulur, seçilen konum aynı instance'tan
/// üretilip `onSave` ile geri verilir.
private struct NewLocationSheet: View {
    let lang: LanguageService
    let onSave: (PrayerLocation) -> Void

    @State private var model = LocationSelectionViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.vakitBg.ignoresSafeArea()
                LocationSelectionView(viewModel: model) { location in
                    onSave(location)
                }
            }
        }
        .environment(lang)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    HomeView()
        .environment(LanguageService.shared)
        .environment(NotificationService.shared)
        .environment(PurchaseService.shared)
}
