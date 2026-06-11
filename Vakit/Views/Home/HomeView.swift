import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel
    private let onOpenDiscover: () -> Void

    @Environment(LanguageService.self) private var lang

    init(viewModel: HomeViewModel = HomeViewModel(), onOpenDiscover: @escaping () -> Void = {}) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenDiscover = onOpenDiscover
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

                    qiblaCard

                    if let verse = viewModel.dailyVerse {
                        DailyContentCard(
                            verse: verse,
                            language: lang.currentLanguage,
                            onOpenDiscover: onOpenDiscover
                        )
                    }
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
        }
    }

    /// Kıble artık sekme değil: ana ekrandan push ile açılır.
    private var qiblaCard: some View {
        NavigationLink {
            QiblaView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.vakitAccent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.vakitAccent.opacity(0.12)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.t("qibla.title"))
                        .font(.system(.body, design: .default, weight: .semibold))
                        .foregroundStyle(Color.vakitText)
                    Text(lang.t("qibla.subtitle"))
                        .font(.footnote)
                        .foregroundStyle(Color.vakitTextDim)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.vakitTextDim)
            }
            .padding(16)
            .background(Color.vakitSurface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.vakitBorder, lineWidth: 1)
            )
        }
    }
}

#Preview {
    HomeView()
        .environment(LanguageService.shared)
}
