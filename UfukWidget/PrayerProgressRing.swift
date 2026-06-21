import SwiftUI

// MARK: - Progress Halkası

/// Bir önceki vakit ile sonraki vakit arasında geçen sürenin oranını
/// gösteren halka. Merkezinde sonraki vaktin ikonu bulunur.
///
/// progress = (now - öncekiVakit) / (sonrakiVakit - öncekiVakit)
struct PrayerProgressRing: View {
    /// 0...1 arası dolum oranı.
    let progress: Double
    /// Merkezde gösterilecek sonraki vakit anahtarı.
    let nextPrayerKey: String

    var lineWidth: CGFloat = 8
    var iconSize: CGFloat = 22
    /// Kilit ekranı tinted modunda tek renk çalışsın diye.
    var tinted: Bool = false

    private var clampedProgress: Double {
        min(1, max(0.001, progress))
    }

    /// Sona yaklaşıldığında (progress > 0.8) hafif parlama.
    private var isGlowing: Bool {
        progress > 0.8
    }

    var body: some View {
        ZStack {
            // Arka halka — beyaz %15 opacity
            Circle()
                .stroke(
                    tinted ? Color.white.opacity(0.25) : Color.white.opacity(0.15),
                    lineWidth: lineWidth
                )

            // Dolu halka — altın gradient, yuvarlak uç
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    ringFill,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(
                    color: isGlowing && !tinted ? WidgetPalette.accentGold.opacity(0.7) : .clear,
                    radius: isGlowing ? 5 : 0
                )

            // Merkez — sonraki vakit ikonu
            PrayerIconView(
                prayerKey: nextPrayerKey,
                size: iconSize,
                color: tinted ? .white : WidgetPalette.accentGold
            )
        }
    }

    private var ringFill: AnyShapeStyle {
        if tinted {
            return AnyShapeStyle(Color.white)
        }
        return AnyShapeStyle(WidgetPalette.ringGradient)
    }
}

// MARK: - Canlı dolan halka (kilit ekranı / accessoryCircular)

/// Sistem tarafından otomatik dolan halka. Timeline reload gerektirmez —
/// `ProgressView(timerInterval:)` kullanır. Kilit ekranı tint moduna uyumludur.
struct LivePrayerProgressRing: View {
    let interval: ClosedRange<Date>
    let nextPrayerKey: String

    var body: some View {
        ProgressView(timerInterval: interval, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            Image(systemName: PrayerIcon.symbol(for: nextPrayerKey))
                .font(.system(size: 13, weight: .medium))
                .symbolRenderingMode(.hierarchical)
        }
        .progressViewStyle(.circular)
        .tint(WidgetPalette.accentGold)
    }
}
