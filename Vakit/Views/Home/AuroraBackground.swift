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

                Circle()
                    .fill(accentColor)
                    .frame(width: size.width * 0.9, height: size.width * 0.9)
                    .offset(x: -size.width * 0.3, y: -size.height * 0.25)
                    .blur(radius: 80)
                    .opacity(0.15)

                Circle()
                    .fill(accentColor)
                    .frame(width: size.width * 0.7, height: size.width * 0.7)
                    .offset(x: size.width * 0.45, y: size.height * 0.05)
                    .blur(radius: 80)
                    .opacity(0.15)

                Circle()
                    .fill(accentColor)
                    .frame(width: size.width * 0.8, height: size.width * 0.8)
                    .offset(x: size.width * 0.1, y: size.height * 0.55)
                    .blur(radius: 80)
                    .opacity(0.12)
            }
            .animation(.easeInOut(duration: 1.5), value: accentColor)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AuroraBackground(accentColor: .fajr)
}
