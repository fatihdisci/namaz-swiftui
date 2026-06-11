import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    @Environment(LanguageService.self) private var lang

    init(viewModel: HomeViewModel = HomeViewModel()) {
        _viewModel = State(initialValue: viewModel)
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

                    DailyContentCard(
                        entry: viewModel.dailyContent,
                        language: lang.currentLanguage
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
        }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.currentCity?.name ?? "—")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.vakitText)
                Text(viewModel.hijriDate)
                    .font(.footnote)
                    .foregroundStyle(Color.vakitTextDim)
            }

            Spacer()

            NavigationLink {
                // Phase 4+'ta gerçek SettingsView gelecek.
                ZStack {
                    Color.vakitBg.ignoresSafeArea()
                    Text(lang.t("settings.title"))
                        .foregroundStyle(Color.vakitText)
                }
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.vakitTextDim)
                    .padding(10)
                    .background(Circle().fill(Color.vakitSurface))
                    .overlay(Circle().strokeBorder(Color.vakitBorder, lineWidth: 1))
            }
        }
    }
}

#Preview {
    HomeView()
        .environment(LanguageService.shared)
}
