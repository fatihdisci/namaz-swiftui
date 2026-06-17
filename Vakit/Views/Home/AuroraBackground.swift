import SwiftUI

/// Aurora hissi: koyu zemin üzerinde, aktif vaktin renginde
/// yumuşak radial ışık lekeleri. Renk değişimi yumuşak animasyonludur.
struct AuroraBackground: View {
    let accentColor: Color

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                Color.vakitBg

                LinearGradient(
                    colors: [
                        accentColor.opacity(0.12),
                        Color.vakitBg.opacity(0.0),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Circle()
                    .fill(accentColor)
                    .frame(width: size.width * 0.65, height: size.width * 0.65)
                    .offset(x: -size.width * 0.35, y: -size.height * 0.22)
                    .blur(radius: 90)
                    .opacity(0.09)

                Circle()
                    .fill(Color.sunrise)
                    .frame(width: size.width * 0.55, height: size.width * 0.55)
                    .offset(x: size.width * 0.42, y: size.height * 0.55)
                    .blur(radius: 100)
                    .opacity(0.05)
            }
            .animation(.easeInOut(duration: 1.5), value: accentColor)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AuroraBackground(accentColor: .fajr)
}
