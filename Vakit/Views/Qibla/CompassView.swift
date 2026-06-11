import SwiftUI

/// Kıble pusulası: sabit pusula yüzü + Kabe'yi gösteren animasyonlu iğne.
struct CompassView: View {
    let viewModel: QiblaViewModel

    @Environment(LanguageService.self) private var lang

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                compassFace
                needle
                    .rotationEffect(.degrees(viewModel.needleRotation))
                    .animation(.interpolatingSpring(stiffness: 50, damping: 10), value: viewModel.needleRotation)
            }
            .frame(width: 260, height: 260)

            VStack(spacing: 4) {
                Text(lang.t("qibla.degrees", Int(normalizedQibla.rounded())))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.vakitText)
                    .contentTransition(.numericText())

                Text(lang.t(directionKey))
                    .font(.subheadline)
                    .foregroundStyle(Color.vakitTextDim)
            }
        }
    }

    private var normalizedQibla: Double {
        let value = viewModel.qiblaAngle.truncatingRemainder(dividingBy: 360)
        return value < 0 ? value + 360 : value
    }

    private var directionKey: String {
        let directions = [
            "qibla.direction.north",
            "qibla.direction.northEast",
            "qibla.direction.east",
            "qibla.direction.southEast",
            "qibla.direction.south",
            "qibla.direction.southWest",
            "qibla.direction.west",
            "qibla.direction.northWest",
        ]
        let index = Int((normalizedQibla / 45).rounded()) % directions.count
        return directions[index]
    }

    private var compassFace: some View {
        ZStack {
            Circle()
                .fill(Color.vakitSurface)

            Circle()
                .strokeBorder(Color.vakitBorder, lineWidth: 1)

            ForEach(0..<24, id: \.self) { tick in
                Rectangle()
                    .fill(Color.vakitTextDim.opacity(tick % 6 == 0 ? 0.6 : 0.25))
                    .frame(width: tick % 6 == 0 ? 2 : 1, height: tick % 6 == 0 ? 14 : 8)
                    .offset(y: -118)
                    .rotationEffect(.degrees(Double(tick) * 15))
            }

            cardinalLabels
        }
    }

    private var cardinalLabels: some View {
        ZStack {
            Text(lang.t("qibla.compass.north")).offset(y: -100)
            Text(lang.t("qibla.compass.east")).offset(x: 100)
            Text(lang.t("qibla.compass.south")).offset(y: 100)
            Text(lang.t("qibla.compass.west")).offset(x: -100)
        }
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .foregroundStyle(Color.vakitTextDim)
    }

    private var needle: some View {
        VStack(spacing: 0) {
            VStack(spacing: 2) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 22))
                Text(lang.t("qibla.kaaba"))
                    .font(.system(.caption2, design: .rounded, weight: .bold))
            }
            .foregroundStyle(Color.vakitAccent)

            Spacer()

            Circle()
                .fill(Color.vakitTextDim.opacity(0.5))
                .frame(width: 10, height: 10)
        }
        .frame(height: 220)
    }
}

#Preview {
    ZStack {
        Color.vakitBg.ignoresSafeArea()
        CompassView(viewModel: QiblaViewModel())
    }
    .environment(LanguageService.shared)
}
