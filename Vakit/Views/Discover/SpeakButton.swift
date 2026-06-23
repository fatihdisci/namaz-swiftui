import SwiftUI

/// Dua/hadis mealini seçili dilde (TR/EN) yerleşik TTS ile sesli okuyan küçük buton.
/// `id` öğeyi benzersiz tanımlar; aynı id tekrar basılınca durur. Tek kaynak (singleton)
/// olduğu için aynı anda yalnızca bir öğe konuşur.
struct SpeakButton: View {
    let id: String
    let text: String
    var tint: Color = .vakitAccent

    @Environment(LanguageService.self) private var lang
    @State private var speech = TranslationSpeechService.shared

    var body: some View {
        Button {
            speech.toggle(id: id, text: text, language: lang.currentLanguage)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: speech.isSpeaking(id) ? "stop.circle.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(lang.t(speech.isSpeaking(id) ? "discover.speak.stop" : "discover.speak.listen"))
                    .font(.system(.caption, weight: .semibold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 11)
            .frame(height: 30)
            .background(Capsule().fill(tint.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lang.t(speech.isSpeaking(id) ? "discover.speak.stop" : "discover.speak.listen"))
    }
}
